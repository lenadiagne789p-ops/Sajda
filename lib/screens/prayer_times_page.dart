import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sajda/models/prayer_times.dart';
import 'package:sajda/models/islamic_calendar.dart';
import 'package:sajda/services/prayer_notification_service.dart';
import 'package:sajda/services/aladhan_api_service.dart';
import 'package:sajda/screens/prayer_settings_page.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/data/prayer_moments_media.dart';
import 'package:sajda/widgets/qibla_compass_inline.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'dart:async';
import 'package:sajda/services/storage_service.dart';


class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> with TickerProviderStateMixin {
  PrayerTimes? _prayerTimes;
  Timer? _timer;
  late AnimationController _pulseController;
  final ScrollController _momentsController = ScrollController();
  int? _lastAutoIndex;
  // Reduce rebuilds: only tick time-sensitive widgets
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());


  bool _isLoading = true;
  Position? _currentPosition;
  String? _currentCity;
  final PrayerNotificationService _notificationService = PrayerNotificationService();
  final AladhanApiService _aladhanService = AladhanApiService();
  String? _locationError;

  // Local UI state: mark prayers as done for the current day
  final Map<PrayerType, bool> _prayedToday = {
    PrayerType.fajr: false,
    PrayerType.dhuhr: false,
    PrayerType.asr: false,
    PrayerType.maghrib: false,
    PrayerType.isha: false,
  };
  DateTime _stateForDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();

    Future.microtask(() async {
      await _initializeServices();
      await _loadPrayerTimes();
      await _loadPrayedStateForToday();
    });
    _startTimer();
    // Auto-scroll when the moment changes based on time notifier
    _now.addListener(() {
      if (!mounted || _prayerTimes == null) return;
      final idx = _momentIndexFor(_prayerTimes!);
      if (_lastAutoIndex != idx) {
        _autoScrollToCurrentMoment();
      }
    });
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
    await _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    final position = await _notificationService.getSavedLocation();
    final city = await _notificationService.getSelectedCity();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _currentCity = city;
      });
    }
  }



  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_stateForDate.day != now.day || _stateForDate.month != now.month || _stateForDate.year != now.year) {
        _resetPrayedStateForNewDay();
      }
      _now.value = now;
    });
  }

  void _resetPrayedStateForNewDay() {
    _stateForDate = DateTime.now();
    _loadPrayedStateForToday();
  }

  Future<void> _loadPrayedStateForToday() async {
    final today = DateTime.now();
    try {
      final map = await StorageService.getPrayerDoneForDate(today);
      if (!mounted) return;
      setState(() {
        _prayedToday[PrayerType.fajr] = map['fajr'] ?? false;
        _prayedToday[PrayerType.dhuhr] = map['dhuhr'] ?? false;
        _prayedToday[PrayerType.asr] = map['asr'] ?? false;
        _prayedToday[PrayerType.maghrib] = map['maghrib'] ?? false;
        _prayedToday[PrayerType.isha] = map['isha'] ?? false;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistPrayedState() async {
    final today = DateTime.now();
    final map = <String, bool>{
      'fajr': _prayedToday[PrayerType.fajr] ?? false,
      'dhuhr': _prayedToday[PrayerType.dhuhr] ?? false,
      'asr': _prayedToday[PrayerType.asr] ?? false,
      'maghrib': _prayedToday[PrayerType.maghrib] ?? false,
      'isha': _prayedToday[PrayerType.isha] ?? false,
    };
    await StorageService.setPrayerDoneForDate(today, map);
  }

  Future<void> _loadPrayerTimes() async {
    double latitude = 48.8566; // Paris par défaut
    double longitude = 2.3522;

    // Utiliser la position sauvegardée si disponible
    if (_currentPosition != null) {
      latitude = _currentPosition!.latitude;
      longitude = _currentPosition!.longitude;
    } else {
      // Essayer d'obtenir la position actuelle
      final position = await _notificationService.getCurrentLocation();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
        final city = await _notificationService.getCityFromCoordinates(latitude, longitude);
        if (city != null && mounted) {
          setState(() {
            _currentPosition = position;
            _currentCity = city;
            _locationError = null;
          });
        }
      } else {
        final storedPosition = await _notificationService.getSavedLocation();
        if (storedPosition != null) {
          latitude = storedPosition.latitude;
          longitude = storedPosition.longitude;
          if (mounted) {
            setState(() {
              _currentPosition = storedPosition;
              _locationError = null;
            });
          }
        } else if (_currentCity != null) {
          final manualPosition = await _notificationService.saveCityByName(_currentCity!);
          if (manualPosition != null) {
            latitude = manualPosition.latitude;
            longitude = manualPosition.longitude;
            if (mounted) {
              setState(() {
                _currentPosition = manualPosition;
                _locationError = null;
              });
            }
          }
        }

        if (_currentPosition == null && mounted) {
          final shouldShowSnackBar = _locationError == null;
          setState(() {
            _locationError = 'Localisation indisponible, horaires affichés pour Paris (par défaut)';
            _currentCity ??= 'Paris';
          });
          if (shouldShowSnackBar) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 Activez la localisation ou saisissez votre ville dans les paramètres de prière.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    }



    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Fetch timings from AlAdhan API using selected calculation method
      final method = await _notificationService.getCalculationMethod();
      final prayerTimes = await _aladhanService.getTimingsByCoordinates(latitude: latitude, longitude: longitude, method: method, date: DateTime.now());
      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
      // After data loads, auto-scroll the moments gallery to current/next prayer
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToCurrentMoment());
      // Programmer les notifications
      await _notificationService.schedulePrayerNotifications(prayerTimes);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationError = 'Erreur lors de la récupération des horaires de prière';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Impossible de récupérer les horaires : ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(child: CircularProgressIndicator(color: IslamicColors.emeraldGreen)),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCurrentTimeCard(),
                    if (_locationError != null) ...[
                      const SizedBox(height: 12),
                      _buildLocationWarning(),
                    ],
                    const SizedBox(height: 20),
                    _buildHijriDateCard(),
                    const SizedBox(height: 20),
                    _buildNextPrayerCard(),
                    const SizedBox(height: 20),
                    _buildDayMomentsGallery(),
                    const SizedBox(height: 20),
                    _buildQiblaCompass(),
                    const SizedBox(height: 20),
                    _buildPrayerTimesGrid(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() => const BoxDecoration(color: Colors.white);

  Widget _buildAppBar() {
    return GradientSliverAppBar(
      title: 'مواقيت الصلاة',
      subtitle: _currentCity,
      expandedHeight: 110,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () async {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _locationError = null;
              });
            }
            await _loadPrayerTimes();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PrayerSettingsPage()));
            if (result == true) {
              if (mounted) setState(() => _isLoading = true);
              await _loadLocationData();
              await _loadPrayerTimes();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCurrentTimeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.emeraldGreen.withValues(alpha: 0.1), IslamicColors.roseGold.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: ValueListenableBuilder<DateTime>(
        valueListenable: _now,
        builder: (context, now, _) {
          return Column(
            children: [
              Text('الوقت الحالي', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
              Text('${now.day}/${now.month}/${now.year}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationError ?? 'Localisation indisponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriDateCard() {
    final hijriDate = HijriDate.fromDateTime(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.mysticBlue.withValues(alpha: 0.1), IslamicColors.softViolet.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.mysticBlue.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('التاريخ الهجري', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.mysticBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(hijriDate.toArabicString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: IslamicColors.mysticBlue, fontWeight: FontWeight.bold)),
          Text(hijriDate.toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }




  Widget _buildNextPrayerCard() {
    if (_prayerTimes == null) return const SizedBox();
    final nextPrayer = _prayerTimes!.getNextPrayer();
    if (nextPrayer == null) {
      return _buildPrayerCard('Isha terminé', 'عشاء انتهى', 'Prochaine prière: Fajr demain', Icons.nights_stay, IslamicColors.mysticBlue);
    }
    final nextTime = _prayerTimes!.getPrayerTime(nextPrayer);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: _now,
            builder: (context, now, _) {
              final timeUntil = nextTime.difference(now);
              return _buildPrayerCard('Prochaine Prière', 'الصلاة القادمة', '${_prayerTimes!.getPrayerNameInFrench(nextPrayer)} dans ${_formatCountdown(timeUntil)}', _getPrayerIcon(nextPrayer), IslamicColors.roseGold);
            },
          ),
        );
      },
    );
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}min';
    if (m > 0) return '${m}min ${s}s';
    return '${s}s';
  }

  Widget _buildPrayerCard(String title, String titleArabic, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleArabic, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaCompass() => const QiblaCompassInline();

  Widget _buildPrayerTimesGrid() {
    if (_prayerTimes == null) return const SizedBox();
    final prayers = [
      (PrayerType.fajr, _prayerTimes!.fajr),
      (PrayerType.dhuhr, _prayerTimes!.dhuhr),
      (PrayerType.asr, _prayerTimes!.asr),
      (PrayerType.maghrib, _prayerTimes!.maghrib),
      (PrayerType.isha, _prayerTimes!.isha),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Make tiles taller to prevent text/icon overflow on small screens or large text scale
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: prayers.length,
      itemBuilder: (context, index) => _buildPrayerTimeCard(prayers[index].$1, prayers[index].$2),
    );
  }

  Color _colorForPrayer(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return IslamicColors.mysticBlue;
      case PrayerType.dhuhr:
        return IslamicColors.emeraldGreen;
      case PrayerType.asr:
        return IslamicColors.softViolet;
      case PrayerType.maghrib:
        return IslamicColors.roseGold;
      case PrayerType.isha:
        return Colors.indigo;
    }
  }

  Widget _buildPrayerTimeCard(PrayerType prayer, DateTime time) {
    final isNext = _prayerTimes?.getNextPrayer() == prayer;
    final accent = _colorForPrayer(prayer);
    final isDone = _prayedToday[prayer] == true;
    // Countdown rebuilt via _now notifier for minimal updates

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _prayedToday[prayer] = !(isDone));
        _persistPrayedState();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent.withValues(alpha: isNext ? 0.22 : 0.12), accent.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDone ? accent : accent.withValues(alpha: 0.3), width: isNext ? 2 : 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(_getPrayerIcon(prayer), color: accent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_prayerTimes!.getPrayerNameInArabic(prayer), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accent, fontWeight: FontWeight.bold), softWrap: true, overflow: TextOverflow.ellipsis),
                        Text(_prayerTimes!.getPrayerNameInFrench(prayer), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), softWrap: true, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isDone
                          ? Icon(Icons.check_circle, key: const ValueKey('done'), color: accent, size: 22)
                          : Icon(Icons.radio_button_unchecked, key: const ValueKey('todo'), color: Colors.grey[500], size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRakahAndSunnahChips(context, prayer, accent),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withValues(alpha: 0.25), width: 1)),
                      child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent, fontWeight: FontWeight.bold)),
                    ),
                    if (isNext)
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _now,
                        builder: (context, now, _) {
                          final countdown = _formatCountdown(time.difference(now));
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.timer, size: 16, color: Colors.black87),
                              const SizedBox(width: 6),
                              Text('dans $countdown', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
                            ]),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRakahAndSunnahChips(BuildContext context, PrayerType prayer, Color accent) {
    final chips = <Widget>[
      _miniChip(
        context,
        icon: Icons.checklist_rtl,
        color: accent,
        label: 'Fard • ${_fardRakahs(prayer)} rakaʿāt',
      ),
    ];

    final sunnah = _sunnahSummary(prayer);
    if (sunnah.isNotEmpty) {
      chips.add(_miniChip(
        context,
        icon: Icons.auto_awesome,
        color: accent,
        label: 'Surérog. • $sunnah',
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _miniChip(BuildContext context, {required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  int _fardRakahs(PrayerType p) {
    switch (p) {
      case PrayerType.fajr:
        return 2;
      case PrayerType.dhuhr:
        return 4;
      case PrayerType.asr:
        return 4;
      case PrayerType.maghrib:
        return 3;
      case PrayerType.isha:
        return 4;
    }
  }

  String _sunnahSummary(PrayerType p) {
    switch (p) {
      case PrayerType.fajr:
        return '2 avant';
      case PrayerType.dhuhr:
        return '4 avant + 2 après';
      case PrayerType.asr:
        return '4 avant (optionnel)';
      case PrayerType.maghrib:
        return '2 après';
      case PrayerType.isha:
        return '2 après + Witr';
    }
  }

  IconData _getPrayerIcon(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny;
      case PrayerType.asr:
        return Icons.wb_cloudy;
      case PrayerType.maghrib:
        return Icons.wb_twilight;
      case PrayerType.isha:
        return Icons.nightlight_round;
    }
  }

  Widget _buildDayMomentsGallery() {
    if (_prayerTimes == null) return const SizedBox();

    final items = [
      ('fajr', PrayerMomentsMedia.pickFor('fajr'), 'الفجر', 'Fajr', _prayerTimes!.fajr, Icons.wb_sunny_outlined),
      ('sunrise', PrayerMomentsMedia.pickFor('sunrise'), 'شروق الشمس', 'Lever du soleil', _prayerTimes!.sunrise, Icons.wb_sunny_outlined),
      ('dhuhr', PrayerMomentsMedia.pickFor('dhuhr'), 'الظهر', 'Dhuhr', _prayerTimes!.dhuhr, Icons.wb_sunny),
      ('asr', PrayerMomentsMedia.pickFor('asr'), 'العصر', 'Asr', _prayerTimes!.asr, Icons.wb_cloudy),
      // Use the dedicated Maghrib photo here (above the Qibla section), as requested
      ('maghrib', 'assets/images/Maghrib_prayer_sunset_mosque_silhouette_orange_1762284199690.jpg', 'المغرب', 'Maghrib', _prayerTimes!.maghrib, Icons.wb_twilight),
      ('isha', PrayerMomentsMedia.pickFor('isha'), 'العشاء', 'Isha', _prayerTimes!.isha, Icons.nightlight_round),
    ];

    return SizedBox(
      height: 210,
      child: ListView.separated(
        controller: _momentsController,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (context, index) {
          final it = items[index];
          final key = it.$1;
          // Reframe Maghrib and Isha to show more sky/horizon for better composition
          final alignment = (key == 'maghrib' || key == 'isha') ? Alignment.topCenter : Alignment.center;
          return _DayMomentCard(
            width: MediaQuery.of(context).size.width * 0.72,
            imageUrl: it.$2,
            titleAr: it.$3,
            titleFr: it.$4,
            timeLabel: '${it.$5.hour.toString().padLeft(2, '0')}:${it.$5.minute.toString().padLeft(2, '0')}',
            accent: IslamicColors.emeraldGreen,
            icon: it.$6,
            imageAlignment: alignment,
          );
        },
      ),
    );
  }






  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _momentsController.dispose();
    _now.dispose();


    super.dispose();
  }
}

extension on _PrayerTimesPageState {
  int _momentIndexFor(PrayerTimes t) {
    // Prefer the current prayer if we are within its window; otherwise use the next prayer
    final current = t.getCurrentPrayer();
    final target = current ?? t.getNextPrayer();
    switch (target) {
      case PrayerType.fajr:
        return 0;
      case null:
        // After Isha: scroll to Isha
        return 5;
      case PrayerType.dhuhr:
        return 2;
      case PrayerType.asr:
        return 3;
      case PrayerType.maghrib:
        return 4;
      case PrayerType.isha:
        return 5;
    }
  }

  void _autoScrollToCurrentMoment() {
    if (_prayerTimes == null || !_momentsController.hasClients) return;
    final index = _momentIndexFor(_prayerTimes!);
    if (_lastAutoIndex == index) return;
    _lastAutoIndex = index;

    final width = MediaQuery.of(context).size.width * 0.72;
    const spacing = 12.0;
    final offset = (width + spacing) * index;

    // Clamp offset to max scroll extent after first layout
    final max = _momentsController.position.maxScrollExtent;
    final clamped = offset.clamp(0.0, max);
    _momentsController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

class _DayMomentCard extends StatelessWidget {
  final double width;
  final String imageUrl;
  final String titleAr;
  final String titleFr;
  final String timeLabel;
  final Color accent;
  final IconData icon;
  final Alignment imageAlignment;

  const _DayMomentCard({required this.width, required this.imageUrl, required this.titleAr, required this.titleFr, required this.timeLabel, required this.accent, required this.icon, this.imageAlignment = Alignment.center});

  Widget _buildImage(BuildContext context, String path, Alignment alignment) {
    final isNetwork = path.startsWith('http');
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final targetWidth = (width * dpr).clamp(320, 1920).round();
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        cacheWidth: targetWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stack) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
          );
        },
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: targetWidth,
      errorBuilder: (context, error, stack) {
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withValues(alpha: 0.18), width: 1)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildImage(context, imageUrl, imageAlignment)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.35)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: 0.3), width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.max, children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$titleAr • $titleFr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                  child: Text(timeLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: accent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _MonthlyTile extends StatelessWidget {
  final PrayerTimes t;
  const _MonthlyTile({required this.t});

  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isToday = now.year == t.date.year && now.month == t.date.month && now.day == t.date.day;
    final accent = isToday ? IslamicColors.emeraldGreen : Colors.grey.shade700;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isToday ? IslamicColors.emeraldGreen : Colors.grey).withValues(alpha: 0.25), width: isToday ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: accent, size: 20),
              const SizedBox(width: 8),
              Text('${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accent, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: IslamicColors.emeraldGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('Aujourd\'hui', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallTime(context, Icons.wb_sunny_outlined, 'Fajr', _hm(t.fajr), IslamicColors.mysticBlue),
              _divider(),
              _smallTime(context, Icons.wb_sunny, 'Dhuhr', _hm(t.dhuhr), IslamicColors.emeraldGreen),
              _divider(),
              _smallTime(context, Icons.wb_cloudy, 'Asr', _hm(t.asr), IslamicColors.softViolet),
              _divider(),
              _smallTime(context, Icons.wb_twilight, 'Maghrib', _hm(t.maghrib), IslamicColors.roseGold),
              _divider(),
              _smallTime(context, Icons.nightlight_round, 'Isha', _hm(t.isha), Colors.indigo),
            ],
          )
        ],
      ),
    );
  }

  Widget _divider() => Expanded(child: Center(child: Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.06))));

  Widget _smallTime(BuildContext context, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
