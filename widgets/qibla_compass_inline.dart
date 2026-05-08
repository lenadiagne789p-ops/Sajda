import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sajda/services/aladhan_api_service.dart';
import 'package:sajda/services/prayer_notification_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/heading_source.dart';
import 'package:sajda/utils/device_heading.dart';

class QiblaCompassInline extends StatefulWidget {
  const QiblaCompassInline({super.key});

  @override
  State<QiblaCompassInline> createState() => _QiblaCompassInlineState();
}

class _QiblaCompassInlineState extends State<QiblaCompassInline> {
  Future<_QiblaInlineData>? _bearingFuture; // Qibla bearing + label
  final PrayerNotificationService _prayerService = PrayerNotificationService();
  Stream<DeviceHeading>? _throttledQiblaStream;

  @override
  void initState() {
    super.initState();
    _bearingFuture = _loadBearing();
    _setupThrottledStream();
    // Try to enable sensor permission early (web/iOS Safari) without breaking mobile
    WidgetsBinding.instance.addPostFrameCallback((_) => _enableOrientation());
  }

  void _setupThrottledStream() {
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
      final ok = await requestHeadingPermission();
      if (!mounted) return;
      if (ok) {
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

  Future<_QiblaInlineData> _loadBearing() async {
    // Try current location, then saved location, then saved city name
    final pos = await _prayerService.getCurrentLocation() 
        ?? await _prayerService.getSavedLocation();
    if (pos == null) {
      // Last resort: try resolve from stored city
      final city = await _prayerService.getSelectedCity();
      if (city != null && city.trim().isNotEmpty) {
        final saved = await _prayerService.saveCityByName(city.trim());
        if (saved != null) {
          final bearing = await AladhanApiService().getQiblaDirection(latitude: saved.latitude, longitude: saved.longitude);
          final label = await _prayerService.getCityFromCoordinates(saved.latitude, saved.longitude);
          return _QiblaInlineData(bearing: bearing, label: label);
        }
      }
      throw Exception('Localisation indisponible');
    }
    final api = AladhanApiService();
    final bearing = await api.getQiblaDirection(latitude: pos.latitude, longitude: pos.longitude);
    final label = await _prayerService.getCityFromCoordinates(pos.latitude, pos.longitude);
    return _QiblaInlineData(bearing: bearing, label: label);
  }

  Future<void> _promptManualCity() async {
    final initialCity = await _prayerService.getSelectedCity();
    final controller = TextEditingController(text: initialCity ?? '');
    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrer une ville'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Ville ou adresse', hintText: 'Ex: Paris, Casablanca...'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || city == null || city.isEmpty) return;
    final saved = await _prayerService.saveCityByName(city);
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ville sauvegardée: $city'), backgroundColor: IslamicColors.emeraldGreen));
      setState(() => _bearingFuture = _loadBearing());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ville introuvable'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.roseGold.withValues(alpha: 0.12), IslamicColors.dustyRose.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.roseGold.withValues(alpha: 0.28), width: 1),
      ),
      child: Column(children: [
        Text('اتجاه القبلة', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          width: 180,
          child: FutureBuilder<_QiblaInlineData>(
            future: _bearingFuture,
            builder: (context, snapBearing) {
              if (snapBearing.connectionState == ConnectionState.waiting) {
                // Show a static dial while loading bearing
                return const Center(child: _CompassDial());
              }
              if (snapBearing.hasError || !snapBearing.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Qibla indisponible', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      OutlinedButton.icon(onPressed: () => setState(() => _bearingFuture = _loadBearing()), icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
                      TextButton.icon(onPressed: _promptManualCity, icon: const Icon(Icons.location_city), label: const Text('Entrer ma ville')),
                    ])
                  ],
                );
              }
              final qiblaBearing = snapBearing.data!.bearing; // degrees from North
              return StreamBuilder(
                stream: _throttledQiblaStream,
                builder: (context, snapshot) {
                  if (_throttledQiblaStream == null) {
                    return _StaticQiblaDial(bearing: qiblaBearing);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Stack(alignment: Alignment.center, children: [
                      const _CompassDial(),
                      Positioned(
                        bottom: 12,
                        child: OutlinedButton.icon(
                          onPressed: _enableOrientation,
                          icon: const Icon(Icons.sensors),
                          label: const Text('Activer le capteur'),
                        ),
                      )
                    ]);
                  }
                  // On Web or when sensor is not available, the plugin may error.
                  // In that case, fall back to a static pointer from North.
                  if (snapshot.hasError) {
                    return _StaticQiblaDial(bearing: qiblaBearing);
                  }
                  final data = snapshot.data;
                  double relativeAngle = 0.0;
                  try {
                    if (data != null) {
                      final deviceDirection = data.direction; // degrees from North
                      relativeAngle = qiblaBearing - deviceDirection;
                      if (relativeAngle > 180) relativeAngle -= 360;
                      if (relativeAngle < -180) relativeAngle += 360;
                    }
                  } catch (_) {
                    relativeAngle = 0.0;
                  }
                  final aligned = relativeAngle.abs() < 6; // ~compass tolerance

                  return Stack(alignment: Alignment.center, children: [
                    // Static dial under a repaint boundary so only the needle repaints
                    const RepaintBoundary(child: _CompassDial()),
                    // Rotating needle pointing to Qibla
                    Transform.rotate(
                      angle: relativeAngle * (math.pi / 180),
                      child: Icon(Icons.navigation, size: 54, color: aligned ? Colors.green : IslamicColors.roseGold),
                    ),
                    // Center cap
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<_QiblaInlineData>(
          future: _bearingFuture,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final label = snap.data!.label;
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on, size: 16, color: IslamicColors.roseGold),
              const SizedBox(width: 6),
              Text(label ?? 'Position actuelle', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
            ]);
          },
        )
      ]),
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial();
  @override
  Widget build(BuildContext context) => Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [IslamicColors.pearlWhite, Colors.white, IslamicColors.roseGold.withValues(alpha: 0.08)]),
          border: Border.all(color: IslamicColors.roseGold, width: 1.6),
        ),
        child: Stack(children: [
          ...List.generate(60, (i) {
            final isCardinal = i % 15 == 0;
            final len = isCardinal ? 12.0 : (i % 5 == 0 ? 8.0 : 5.0);
            final color = isCardinal ? IslamicColors.roseGold : Colors.grey[400]!;
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
        alignment: const Alignment(0, -0.78),
        child: Transform.rotate(
          angle: -angleDeg * math.pi / 180,
          child: Text(label, style: TextStyle(color: isNorth ? IslamicColors.emeraldGreen : Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _StaticQiblaDial extends StatelessWidget {
  final double bearing; // degrees from North
  const _StaticQiblaDial({required this.bearing});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      const _CompassDial(),
      Transform.rotate(
        angle: bearing * (math.pi / 180),
        child: const Icon(Icons.navigation, size: 54, color: IslamicColors.roseGold),
      ),
      // No explicit sensor warning: keep UI clean in preview
      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
    ]);
  }
}

class _QiblaInlineData {
  final double bearing;
  final String? label;
  const _QiblaInlineData({required this.bearing, this.label});
}
