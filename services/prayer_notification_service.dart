import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sajda/models/prayer_times.dart';
import 'package:sajda/services/aladhan_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';
import 'package:sajda/theme.dart';

enum AdhanSourceType { asset, network }

class AdhanSoundOption {
  final String id;
  final String name;
  final String description;
  final String source;
  final AdhanSourceType type;

  const AdhanSoundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    this.type = AdhanSourceType.network,
  });
}

class PrayerNotificationService {
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Expose player and streams for UI to control and listen consistently
  AudioPlayer get adhanPlayer => _audioPlayer;
  Stream<PlayerState> get playerStateStream => _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  // Settings keys
  static const String _adhanEnabledKey = 'adhan_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _popupEnabledKey = 'popup_enabled';
  static const String _selectedCityKey = 'selected_city';
  static const String _latitudeKey = 'user_latitude';
  static const String _longitudeKey = 'user_longitude';
  static const String _calcMethodKey = 'prayer_calc_method';
  static const String _selectedAdhanKey = 'selected_adhan_sound';
  static const String _customAdhanUrlKey = 'custom_adhan_url';
  static const String _preNotificationOffsetKey = 'prayer_lead_minutes';

  static const int _defaultLeadMinutes = 10;
  static const int _maxLeadMinutes = 90;

  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  final AladhanApiService _aladhanApi = AladhanApiService();
  Timer? _dailyRefreshTimer;
  final Map<String, Timer> _adhanTimers = {};

  static const List<AdhanSoundOption> _adhanOptions = [
    AdhanSoundOption(
      id: 'classic_offline',
      name: 'Adhan classique (offline)',
      description: 'Version intégrée disponible sans connexion',
      source: 'assets/audio/adhan.mp3',
      type: AdhanSourceType.asset,
    ),
    AdhanSoundOption(
      id: 'makkah_alafasy',
      name: 'La Mecque — Mishary Alafasy',
      description: 'Adhan de la Mosquée sacrée (Al‑Masjid Al‑Haram)',
      source: 'https://cdn.islamic.network/adhan/audio/64/ar.alafasy.mp3',
    ),
    AdhanSoundOption(
      id: 'madinah_otaybi',
      name: 'Madinah — Haramain',
      description: 'Adhan de la Mosquée du Prophète (Al‑Masjid An‑Nabawi)',
      source: 'https://cdn.islamic.network/adhan/audio/64/ar.otaybi.mp3',
    ),
    AdhanSoundOption(
      id: 'aqsa_jerusalem',
      name: 'Al‑Aqsa — Jérusalem',
      description: 'Adhan de la Mosquée Al‑Aqsa',
      source: 'https://cdn.islamic.network/adhan/audio/64/ar.hossari.mp3',
    ),
    AdhanSoundOption(
      id: 'egypt_minsy',
      name: 'Le Caire — style égyptien',
      description: 'Adhan traditionnel égyptien',
      source: 'https://cdn.islamic.network/adhan/audio/64/ar.muhammad_refaat.mp3',
    ),
  ];

  AdhanSoundOption get _defaultAdhan {
    // On Web, prefer a network adhan (assets may fail to load due to browser codecs or paths)
    if (kIsWeb) {
      // The first network option in the list is index 1 (Makkah — Alafasy)
      // Fallback safely if the list changes order in the future
      return _adhanOptions.firstWhere(
        (o) => o.type == AdhanSourceType.network,
        orElse: () => _adhanOptions.first,
      );
    }
    return _adhanOptions.first;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezones
    try {
      tzdata.initializeTimeZones();
      _configureLocalTimezone();
    } catch (e) {
      debugPrint('Timezone init error: $e');
    }

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);

    // Stop vibration when playback completes
    _audioPlayer.onPlayerStateChanged.listen((state) async {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        // Guard vibration cancel on Web where the plugin has no implementation
        if (!kIsWeb) {
          try {
            await Vibration.cancel();
          } catch (_) {}
        }
      }
    });

    // Request notifications permission on Android 13+
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  void _configureLocalTimezone() {
    // Map device offset to a fixed Etc/GMT zone to avoid extra plugins
    final offset = DateTime.now().timeZoneOffset; // e.g., +02:00
    final hours = offset.inHours.abs();
    final signForEtc = offset.isNegative ? '+' : '-'; // Etc/GMT-2 => UTC+2
    final etcName = 'Etc/GMT$signForEtc$hours';
    try {
      final location = tz.getLocation(etcName);
      tz.setLocalLocation(location);
    } catch (e) {
      // Fallback to UTC
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  Future<bool> requestPermissions() async {
    // Ensure location services are enabled (mobile only)
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open settings on mobile; on web we can't
        await Geolocator.openLocationSettings();
        return false;
      }
    }

    // Location permissions
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }
    if (locationPermission == LocationPermission.deniedForever) {
      // Guide user to app settings on mobile
      if (!kIsWeb) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    // Notifications permissions (Android only)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }

    return locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // Save position
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latitudeKey, position.latitude);
      await prefs.setDouble(_longitudeKey, position.longitude);

      final resolvedCity = await getCityFromCoordinates(position.latitude, position.longitude);
      if (resolvedCity != null) {
        await saveSelectedCity(resolvedCity);
      }

      return position;
    } catch (e) {
      debugPrint('Erreur de géolocalisation: $e');
      return null;
    }
  }

  Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      }
    } catch (e) {
      debugPrint('Erreur de géocodage: $e');
    }
    return null;
  }

  Future<void> saveSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCityKey, city);
  }

  Future<String?> getSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedCityKey);
  }

  Future<Position?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (latitude != null && longitude != null) {
      return _createPosition(latitude, longitude);
    }
    return null;
  }

  // Settings getters and setters
  Future<int> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to UOIF (France) = 12 for francophone users
    return prefs.getInt(_calcMethodKey) ?? 12;
  }

  Future<void> setCalculationMethod(int method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calcMethodKey, method);
  }

  Future<List<AdhanSoundOption>> availableAdhanOptionsAsync() async {
    final custom = await getCustomAdhanUrl();
    if (custom == null || custom.isEmpty) {
      return List.unmodifiable(_adhanOptions);
    }
    final customOption = AdhanSoundOption(
      id: 'custom_url',
      name: 'Personnalisé (AlAdhan Play)',
      description: 'URL personnalisée depuis aladhan.com/play',
      source: custom,
    );
    return List.unmodifiable([customOption, ..._adhanOptions]);
  }

  AdhanSoundOption _optionById(String id) {
    return _adhanOptions.firstWhere((opt) => opt.id == id, orElse: () => _defaultAdhan);
  }

  Future<AdhanSoundOption> getSelectedAdhanOption() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_selectedAdhanKey);
    if (storedId == null) return _defaultAdhan;
    if (storedId == 'custom_url') {
      final custom = await getCustomAdhanUrl();
      if (custom != null && custom.isNotEmpty) {
        return AdhanSoundOption(
          id: 'custom_url',
          name: 'Personnalisé (AlAdhan Play)',
          description: 'URL personnalisée depuis aladhan.com/play',
          source: custom,
        );
      }
      // si l’URL a été supprimée, revenir au défaut
      return _defaultAdhan;
    }
    return _optionById(storedId);
  }

  Future<void> setSelectedAdhan(String optionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAdhanKey, _optionById(optionId).id);
  }

  Future<void> setCustomAdhanUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customAdhanUrlKey, url);
    await prefs.setString(_selectedAdhanKey, 'custom_url');
  }

  Future<String?> getCustomAdhanUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customAdhanUrlKey);
  }

  Future<bool> isAdhanEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adhanEnabledKey) ?? true;
  }

  Future<void> setAdhanEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adhanEnabledKey, enabled);
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  Future<bool> isPopupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_popupEnabledKey) ?? true;
  }

  Future<void> setPopupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_popupEnabledKey, enabled);
  }

  Future<int> getNotificationLeadMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_preNotificationOffsetKey);
    if (stored == null) return _defaultLeadMinutes;
    return stored.clamp(0, _maxLeadMinutes).toInt();
  }

  Future<void> setNotificationLeadMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final bounded = minutes.clamp(0, _maxLeadMinutes).toInt();
    await prefs.setInt(_preNotificationOffsetKey, bounded);
  }

  Future<void> schedulePrayerNotifications(PrayerTimes prayerTimes) async {
    final leadMinutesRaw = await getNotificationLeadMinutes();
    final int leadMinutes = leadMinutesRaw.clamp(0, _maxLeadMinutes).toInt();
    final showPopupNotifications = await isPopupEnabled();

    try {
      if (!kIsWeb) {
        try {
          await _notifications.cancelAll();
        } catch (e) {
          debugPrint('[PrayerNotificationService] cancelAll error: $e');
        }
      }

      final now = DateTime.now();
      final entries = <(int id, String title, DateTime time)>[
        (1, 'Fajr', prayerTimes.fajr),
        (2, 'Dhuhr', prayerTimes.dhuhr),
        (3, 'Asr', prayerTimes.asr),
        (4, 'Maghrib', prayerTimes.maghrib),
        (5, 'Isha', prayerTimes.isha),
      ];

      for (final (id, title, prayerTime) in entries) {
        if (!prayerTime.isAfter(now)) {
          continue;
        }

        _scheduleAdhanAtTime(prayerTime, title);

        if (!showPopupNotifications) {
          continue;
        }

        DateTime notificationTime;
        String body;

        if (leadMinutes <= 0) {
          notificationTime = prayerTime;
          body = _buildImmediateReminderBody(title, prayerTime);
        } else {
          final preTime = prayerTime.subtract(Duration(minutes: leadMinutes));
          if (preTime.isAfter(now)) {
            notificationTime = preTime;
            body = _buildLeadReminderBody(title, prayerTime, leadMinutes);
          } else {
            final remaining = prayerTime.difference(now);
            if (remaining.inSeconds <= 0) {
              continue;
            }
            notificationTime = now.add(const Duration(seconds: 10));
            if (!notificationTime.isBefore(prayerTime)) {
              notificationTime = prayerTime.subtract(const Duration(seconds: 1));
            }
            if (!notificationTime.isAfter(now)) {
              continue;
            }
            body = _buildFallbackReminderBody(title, prayerTime, remaining);
          }
        }

        await _scheduleNotification(id, title, body, notificationTime);
      }
    } catch (e) {
      debugPrint('Erreur lors de la programmation des notifications: $e');
    } finally {
      _scheduleNextDayRefresh(prayerTimes.date);
    }
  }

  Future<void> _scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    try {
      if (kIsWeb) {
        // On Web: do not call native scheduling, but keep the in-app timer
        debugPrint('[PrayerNotificationService] Web: would schedule "$title" at $scheduledTime');
      } else {
        // Use a visible, colorized style to avoid transparent/low-contrast look (esp. Isha at night)
        final androidDetails = AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Notifications',
          channelDescription: 'Notifications for prayer times with Adhan',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false, // Nous gérons l'audio manuellement
          enableVibration: true,
          ticker: 'Prayer Time',
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          colorized: true,
          // Night-friendly accent; improves contrast on certain Android OEM skins
          color: IslamicColors.mysticBlue,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'Temps de prière',
          ),
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true, 
          presentBadge: true, 
          presentSound: false, // Audio géré manuellement
        );

        final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
          payload: 'prayer:${title.toLowerCase()}',
        );
      }

      debugPrint('Notification programmée: $title à $scheduledTime');
    } catch (e) {
      debugPrint('Erreur lors de la programmation de la notification $id: $e');
    }
  }

  String _buildLeadReminderBody(String prayerName, DateTime prayerTime, int leadMinutes) {
    final emoji = _emojiForPrayer(prayerName);
    final minutesLabel = leadMinutes == 1 ? '1 minute' : '$leadMinutes minutes';
    return '$emoji $prayerName commence dans $minutesLabel (à ${_formatTime(prayerTime)})';
  }

  String _buildImmediateReminderBody(String prayerName, DateTime prayerTime) {
    final emoji = _emojiForPrayer(prayerName);
    return '$emoji Il est l\'heure de la prière de $prayerName (à ${_formatTime(prayerTime)})';
  }

  String _buildFallbackReminderBody(String prayerName, DateTime prayerTime, Duration remaining) {
    final emoji = _emojiForPrayer(prayerName);
    return '$emoji $prayerName commence à ${_formatTime(prayerTime)} · ${_formatRemaining(remaining)} restantes';
  }

  String _emojiForPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return '🌅';
      case 'dhuhr':
        return '☀️';
      case 'asr':
        return '🌇';
      case 'maghrib':
        return '🌆';
      case 'isha':
        return '🌙';
      default:
        return '🕌';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatRemaining(Duration remaining) {
    final minutes = remaining.inMinutes;
    if (minutes >= 1) {
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
    final seconds = remaining.inSeconds;
    if (seconds <= 5) {
      return 'quelques secondes';
    }
    return '$seconds secondes';
  }

  void _scheduleNextDayRefresh(DateTime currentDate) {
    _dailyRefreshTimer?.cancel();

    final now = DateTime.now();
    final normalized = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final nextDay = normalized.add(const Duration(days: 1));
    final refreshTime = DateTime(nextDay.year, nextDay.month, nextDay.day, 0, 5);

    var delay = refreshTime.difference(now);
    if (delay.inSeconds <= 0) {
      delay = const Duration(minutes: 5);
    }

    _dailyRefreshTimer = Timer(delay, () async {
      await refreshPrayerNotifications(forDate: nextDay);
    });
  }

  Future<void> refreshPrayerNotifications({DateTime? forDate}) async {
    try {
      final position = await _resolvePositionForScheduling();
      if (position == null) {
        debugPrint('[PrayerNotificationService] refreshPrayerNotifications: position indisponible');
        return;
      }

      final method = await getCalculationMethod();
      final targetDate = forDate ?? DateTime.now();
      final prayerTimes = await _aladhanApi.getTimingsByCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        method: method,
        date: targetDate,
      );

      await schedulePrayerNotifications(prayerTimes);
    } catch (e) {
      debugPrint('[PrayerNotificationService] refreshPrayerNotifications error: $e');
    }
  }

  Future<Position?> _resolvePositionForScheduling() async {
    var position = await getSavedLocation();
    if (position != null) {
      return position;
    }

    final city = await getSelectedCity();
    if (city != null && city.isNotEmpty) {
      position = await saveCityByName(city);
      if (position != null) {
        return position;
      }
    }

    // Fallback to Paris coordinates to avoid missing schedules entirely.
    debugPrint('[PrayerNotificationService] Aucune position sauvegardée, utilisation du fallback Paris');
    return _createPosition(48.8566, 2.3522);
  }

  Future<void> cancelPrayerNotifications() async {
    try {
      _dailyRefreshTimer?.cancel();
      _dailyRefreshTimer = null;

      for (final timer in _adhanTimers.values) {
        timer.cancel();
      }
      _adhanTimers.clear();
      if (kIsWeb) {
        debugPrint('[PrayerNotificationService] Web: cancelPrayerNotifications (timers uniquement)');
      } else {
        // IDs 1..5 are used for Fajr..Isha scheduling in this service
        for (final id in [1, 2, 3, 4, 5]) {
          await _notifications.cancel(id);
        }
      }

      await stopAdhan();
    } catch (e) {
      debugPrint('[PrayerNotificationService] cancelPrayerNotifications error: $e');
    }
  }

  void _scheduleAdhanAtTime(DateTime time, String prayerName) {
    final key = prayerName.toLowerCase();
    _adhanTimers[key]?.cancel();

    final now = DateTime.now();
    final delay = time.difference(now);

    if (delay.inMilliseconds <= 0) {
      _adhanTimers.remove(key);
      return;
    }

    _adhanTimers[key] = Timer(delay, () {
      playAdhan();
      debugPrint('Adhan joué automatiquement pour: $prayerName');
      _adhanTimers.remove(key);
    });
  }

  Future<void> playAdhan() async {
    final option = await getSelectedAdhanOption();
    await playAdhanOption(option, respectToggle: true, withVibration: true);
  }

  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
    if (!kIsWeb) {
      try {
        await Vibration.cancel();
      } catch (_) {}
    }
  }

  Future<void> previewAdhan(String optionId) async {
    final option = _optionById(optionId);
    await playAdhanOption(option, respectToggle: false, withVibration: false);
  }

  Future<void> playAdhanOption(
    AdhanSoundOption option, {
    bool respectToggle = true,
    bool withVibration = true,
  }) async {
    if (respectToggle && !await isAdhanEnabled()) return;

    Future<bool> startPlayback(AdhanSoundOption target) async {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        if (target.type == AdhanSourceType.asset) {
          // On Web, avoid assets for reliability; use the default network adhan instead
          if (kIsWeb) {
            final networkDefault = _defaultAdhan;
            await _audioPlayer.play(UrlSource(networkDefault.source));
          } else {
            await _audioPlayer.play(AssetSource(_resolveAssetPath(target.source)));
          }
        } else {
          await _audioPlayer.play(UrlSource(target.source));
        }
        return true;
      } catch (e) {
        debugPrint("Erreur lors de la lecture de l'adhan ${target.id}: $e");
        return false;
      }
    }

    var success = await startPlayback(option);
    if (!success && option.id != _defaultAdhan.id) {
      success = await startPlayback(_defaultAdhan);
    }

    if (success && withVibration && await isVibrationEnabled()) {
      if (!kIsWeb) {
        try {
          final hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            await Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000], intensities: [0, 255, 0, 255, 0, 255]);
          }
        } catch (_) {}
      }
    }
  }

  // Méthode pour tester une notification avec adhan instantanément
  Future<void> testPrayerNotification(String prayerName) async {
    if (kIsWeb) {
      debugPrint('[PrayerNotificationService] Web: test notification "$prayerName"');
    } else {
      final androidDetails = AndroidNotificationDetails(
        'prayer_test_channel',
        'Prayer Test Notifications',
        channelDescription: 'Test notifications for prayer times with Adhan',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        ticker: 'Prayer Test',
        icon: '@mipmap/ic_launcher',
        colorized: true,
        color: IslamicColors.mysticBlue,
        category: AndroidNotificationCategory.reminder,
        styleInformation: const BigTextStyleInformation(
          '🕌 Test de l\'appel à la prière',
          contentTitle: 'Test',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true, 
        presentSound: false,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(
        999, // ID de test
        'Test - $prayerName',
        '🕌 Test de l\'appel à la prière pour $prayerName',
        details,
        payload: 'prayer:test_${prayerName.toLowerCase()}',
      );
    }

    // Jouer l'adhan immédiatement
    await playAdhan();
  }

  Future<void> showPrayerDialog(BuildContext context, String prayerName) async {
    if (!await isPopupEnabled()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.mosque, color: Colors.green), const SizedBox(width: 8), const Text('Temps de prière')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🕌 Il est l\'heure de la prière du $prayerName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Qu\'Allah accepte votre prière', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              stopAdhan();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Jouer l'adhan
    playAdhan();
  }

  void dispose() {
    _dailyRefreshTimer?.cancel();
    for (final timer in _adhanTimers.values) {
      timer.cancel();
    }
    _adhanTimers.clear();
    _audioPlayer.dispose();
  }

  String _resolveAssetPath(String source) {
    // audioplayers assets are defined relative to the assets/ root
    if (source.startsWith('assets/')) {
      return source.replaceFirst('assets/', '');
    }
    return source;
  }

  Future<Position?> saveCityByName(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isEmpty) return null;

      final location = locations.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latitudeKey, location.latitude);
      await prefs.setDouble(_longitudeKey, location.longitude);

      String? resolvedCity;
      try {
        final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          resolvedCity = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
        }
      } catch (e) {
        debugPrint('Erreur lors de la résolution du nom de ville: $e');
      }

      await saveSelectedCity(resolvedCity ?? cityName);
      return _createPosition(location.latitude, location.longitude);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde manuelle de la ville: $e');
      return null;
    }
  }

  Position _createPosition(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
