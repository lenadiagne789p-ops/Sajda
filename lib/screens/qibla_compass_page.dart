import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sajda/services/aladhan_api_service.dart';
import 'package:sajda/services/prayer_notification_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/heading_source.dart';
import 'package:sajda/utils/device_heading.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  final PrayerNotificationService _prayerService = PrayerNotificationService();
  Future<_QiblaViewData>? _bearingFuture;
  // Throttle sensor updates to reduce rebuilds
  Stream<DeviceHeading>? _throttledQiblaStream;
  bool _wasAligned = false; // for subtle haptic feedback when entering alignment

  @override
  void initState() {
    super.initState();
    _bearingFuture = _loadBearing();
    _setupThrottledStream();
    // Attempt to request sensor permission early (web/iOS Safari)
    WidgetsBinding.instance.addPostFrameCallback((_) => _enableOrientation());
  }

  void _setupThrottledStream() {
    // Emit at most ~12fps and only when direction changed by >= 1°
    const minInterval = Duration(milliseconds: 80);
    double? lastDir;
    DateTime lastTime = DateTime.fromMillisecondsSinceEpoch(0);
    final raw = headingStream();
    if (raw == null) {
      _throttledQiblaStream = null;
      return;
    }
    _throttledQiblaStream = raw.where((e) {
      try {
        final now = DateTime.now();
        final dir = e.direction;
        final enoughTime = now.difference(lastTime) >= minInterval;
        final enoughDelta = lastDir == null || (dir - (lastDir!)).abs() >= 1.0;
        if (enoughTime && enoughDelta) {
          lastTime = now;
          lastDir = dir;
          return true;
        }
      } catch (_) {
        return true;
      }
      return false;
    });
  }

  Future<void> _enableOrientation() async {
    try {
      final granted = await requestHeadingPermission();
      if (!mounted) return;
      if (granted) {
        setState(() {
          _setupThrottledStream();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission capteur refusée'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {}
  }

  Future<_QiblaViewData> _loadBearing() async {
    Position? position = await _prayerService.getCurrentLocation();
    var usedFallback = false;

    if (position == null) {
      usedFallback = true;
      position = await _prayerService.getSavedLocation();
      if (position == null) {
        final storedCity = await _prayerService.getSelectedCity();
        if (storedCity != null && storedCity.trim().isNotEmpty) {
          position = await _prayerService.saveCityByName(storedCity.trim());
        }
      }
    }

    if (position == null) {
      throw Exception('Position indisponible');
    }

    final bearing = await AladhanApiService().getQiblaDirection(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    String? resolvedLabel;
    try {
      resolvedLabel = await _prayerService.getCityFromCoordinates(position.latitude, position.longitude);
    } catch (_) {
      resolvedLabel = null;
    }
    resolvedLabel ??= await _prayerService.getSelectedCity();

    return _QiblaViewData(
      bearing: bearing,
      latitude: position.latitude,
      longitude: position.longitude,
      locationLabel: resolvedLabel,
      usedFallbackLocation: usedFallback,
    );
  }

  void _retryBearing() {
    setState(() {
      _bearingFuture = _loadBearing();
    });
  }

  Future<void> _promptManualCity() async {
    final initialCity = await _prayerService.getSelectedCity();
    final controller = TextEditingController(text: initialCity ?? '');

    final city = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Entrer une ville'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Ville ou adresse',
              hintText: 'Ex: Paris, Casablanca...'
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted) return;

    if (city == null || city.isEmpty) {
      return;
    }

    final position = await _prayerService.saveCityByName(city);
    if (!mounted) return;

    if (position != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ville sauvegardée: $city'),
          backgroundColor: IslamicColors.emeraldGreen,
        ),
      );
      _retryBearing();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ville introuvable. Merci de vérifier l\'orthographe.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Boussole Qibla', showBack: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [IslamicColors.emeraldGreen.withValues(alpha: 0.1), IslamicColors.mysticBlue.withValues(alpha: 0.05), IslamicColors.pearlWhite], radius: 1.2),
        ),
        child: Center(
          child: FutureBuilder<_QiblaViewData>(
            future: _bearingFuture,
            builder: (context, snapBearing) {
              if (snapBearing.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(color: IslamicColors.emeraldGreen);
              }
              if (snapBearing.hasError || !snapBearing.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Qibla indisponible',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Activez la localisation ou indiquez votre ville pour calculer la direction.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retryBearing,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _promptManualCity,
                        icon: const Icon(Icons.location_city),
                        label: const Text('Entrer ma ville'),
                      ),
                    ],
                  ),
                );
              }
              final qiblaData = snapBearing.data!;
              final qiblaBearing = qiblaData.bearing;
              return StreamBuilder(
                stream: _throttledQiblaStream,
                builder: (context, snapshot) {
                  // If sensor stream is unavailable (e.g., Web) or errors, fall back to a static dial
                  if (_throttledQiblaStream == null) {
                    return _StaticQiblaDialLarge(bearing: qiblaBearing, viewData: qiblaData);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StaticQiblaDialLarge(bearing: qiblaBearing, viewData: qiblaData),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _enableOrientation,
                          icon: const Icon(Icons.sensors),
                          label: const Text('Activer le capteur'),
                        ),
                      ],
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    // Web/unsupported sensors: show a clean static dial (no manual simulation)
                    return _StaticQiblaDialLarge(bearing: qiblaBearing, viewData: qiblaData);
                  }

                  final data = snapshot.data;
                  double angleDeg = 0.0;
                  try {
                    final currentDirection = data!.direction; // deg from North
                    angleDeg = qiblaBearing - currentDirection;
                    if (angleDeg > 180) angleDeg -= 360;
                    if (angleDeg < -180) angleDeg += 360;
                  } catch (_) {
                    angleDeg = 0.0;
                  }
                  const toleranceDeg = 6.0;
                  final aligned = angleDeg.abs() < toleranceDeg;

                  // Subtle haptic feedback when user reaches alignment (mobile only)
                  if (aligned && !_wasAligned) {
                    try {
                      HapticFeedback.lightImpact();
                    } catch (_) {}
                  }
                  _wasAligned = aligned;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                            if (aligned)
                              BoxShadow(
                                color: IslamicColors.emeraldGreen.withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                          ],
                          border: Border.all(
                            color: aligned ? IslamicColors.emeraldGreen : IslamicColors.emeraldGreen.withValues(alpha: 0.25),
                            width: aligned ? 3 : 1,
                          ),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          // Static dial does not repaint when needle moves
                          const RepaintBoundary(child: _DialLarge()),
                          // Needle
                          Transform.rotate(
                            angle: angleDeg * (math.pi / 180),
                            child: Icon(
                              Icons.navigation,
                              size: 72,
                              color: aligned ? IslamicColors.emeraldGreen : IslamicColors.roseGold,
                            ),
                          ),
                          // Center cap
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(aligned ? Icons.check_circle : Icons.explore, color: aligned ? IslamicColors.emeraldGreen : IslamicColors.roseGold),
                        const SizedBox(width: 8),
                        Text(
                          aligned ? 'Direction alignée' : 'Tournez le téléphone...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: aligned ? IslamicColors.emeraldGreen : IslamicColors.roseGold, fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text('Δ ${angleDeg.abs().toStringAsFixed(0)}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                      const SizedBox(height: 16),
                      if (qiblaData.locationLabel != null)
                        Text(
                          'Basé sur: ${qiblaData.locationLabel}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      Text(
                        'Coordonnées: ${qiblaData.latitude.toStringAsFixed(4)}, ${qiblaData.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      if (qiblaData.usedFallbackLocation)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: _promptManualCity,
                            icon: const Icon(Icons.edit_location_alt),
                            label: const Text('Ajuster la ville'),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QiblaViewData {
  final double bearing;
  final double latitude;
  final double longitude;
  final String? locationLabel;
  final bool usedFallbackLocation;

  const _QiblaViewData({
    required this.bearing,
    required this.latitude,
    required this.longitude,
    this.locationLabel,
    this.usedFallbackLocation = false,
  });
}

class _DialLarge extends StatelessWidget {
  const _DialLarge();
  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [IslamicColors.pearlWhite, Colors.white, IslamicColors.emeraldGreen.withValues(alpha: 0.06)]), border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.35))),
        child: Stack(children: [
          ...List.generate(60, (i) {
            final isCardinal = i % 15 == 0;
            final len = isCardinal ? 16.0 : (i % 5 == 0 ? 10.0 : 6.0);
            final color = isCardinal ? IslamicColors.emeraldGreen : Colors.grey[400]!;
            return _Tick(angleDeg: i * 6.0, length: len, color: color);
          }),
          const _CardinalLabel('N', 0),
          const _CardinalLabel('E', 90),
          const _CardinalLabel('S', 180),
          const _CardinalLabel('W', 270),
        ]),
      );
}

class _Tick extends StatelessWidget {
  final double angleDeg;
  final double length;
  final Color color;
  const _Tick({required this.angleDeg, required this.length, required this.color});

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angleDeg * math.pi / 180,
        child: Align(alignment: Alignment.topCenter, child: Container(width: 2, height: length, color: color)),
      );
}

class _CardinalLabel extends StatelessWidget {
  final String label;
  final double angleDeg;
  const _CardinalLabel(this.label, this.angleDeg);

  @override
  Widget build(BuildContext context) {
    final isNorth = label == 'N';
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: Align(
        alignment: const Alignment(0, -0.8),
        child: Transform.rotate(
          angle: -angleDeg * math.pi / 180,
          child: Text(label, style: TextStyle(color: isNorth ? IslamicColors.emeraldGreen : Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _StaticQiblaDialLarge extends StatelessWidget {
  final double bearing; // degrees from North
  final _QiblaViewData viewData;
  const _StaticQiblaDialLarge({required this.bearing, required this.viewData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
            border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.25)),
          ),
          child: Stack(alignment: Alignment.center, children: [
            const _DialLarge(),
            Transform.rotate(
              angle: bearing * (math.pi / 180),
              child: const Icon(Icons.navigation, size: 72, color: IslamicColors.roseGold),
            ),
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ]),
        ),
        const SizedBox(height: 16),
        // Keep preview minimal; no sensor warning message
        const SizedBox(height: 8),
        if (viewData.locationLabel != null)
          Text(
            'Basé sur: ${viewData.locationLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        Text(
          'Coordonnées: ${viewData.latitude.toStringAsFixed(4)}, ${viewData.longitude.toStringAsFixed(4)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        if (viewData.usedFallbackLocation)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Astuce: ajustez la ville via le bouton "Entrer ma ville"',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
      ],
    );
  }
}

// Note: Web simulation removed to adhere to "automatic only" behavior.
