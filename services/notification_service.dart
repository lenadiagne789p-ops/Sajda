import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_calendar.dart';
import 'package:sajda/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:sajda/models/reminder.dart';
import 'package:sajda/services/reminder_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _scheduledRemindersKey = 'scheduled_islamic_reminders';
  static const String _scheduledGeneralIdsKey = 'scheduled_general_ids';
  static const String _scheduledEncouragementIdsKey = 'scheduled_encouragement_ids';
  static const String _encouragementsEnabledKey = 'encouragements_enabled';
  static const String _generalRemindersEnabledKey = 'general_reminders_enabled';

  static Future<void> initialize() async {
    // On Web, the flutter_local_notifications plugin is not supported.
    if (kIsWeb) {
      debugPrint('[NotificationService] Web detected: skipping native notifications init');
      return;
    }

      try {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      // Request permissions for Android 13+
      await _requestPermissions();

      // Initialize timezone database once
      try {
        tzdata.initializeTimeZones();
        // Best-effort: map device offset to Etc/GMT like other service
        final offset = DateTime.now().timeZoneOffset;
        final hours = offset.inHours.abs();
        final signForEtc = offset.isNegative ? '+' : '-';
        final etcName = 'Etc/GMT$signForEtc$hours';
        tz.setLocalLocation(tz.getLocation(etcName));
      } catch (e) {
        try {
          tz.setLocalLocation(tz.getLocation('Etc/UTC'));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // region: Toggles for categories
  static Future<bool> areEncouragementsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_encouragementsEnabledKey) ?? true;
  }

  static Future<void> setEncouragementsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_encouragementsEnabledKey, enabled);
    if (enabled) {
      await scheduleDailyEncouragements();
    } else {
      await cancelDailyEncouragements();
    }
  }

  static Future<bool> areGeneralRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_generalRemindersEnabledKey) ?? true;
  }

  static Future<void> setGeneralRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_generalRemindersEnabledKey, enabled);
    if (enabled) {
      await scheduleActiveReminders();
    } else {
      await cancelActiveReminders();
    }
  }
  // endregion

  static Future<void> scheduleIslamicEventReminder(IslamicEvent event) async {
    // Calculate the date 3 days before the event
    final reminderDate = _calculateReminderDate(event);
    
    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule reminder for past date: ${event.name}');
      return;
    }

    final title = '🕌 ${event.name} dans 3 jours';
    final body = _getNotificationBody(event);

    if (kIsWeb) {
      // Web: gracefully skip native notification and persist the intent
      debugPrint('[NotificationService] Web: would schedule "$title" -> "$body" at $reminderDate');
    } else {
      try {
        final androidDetails = AndroidNotificationDetails(
          'islamic_events_channel',
          'Événements Islamiques',
          channelDescription: 'Rappels pour les événements islamiques importants',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.reminder,
          colorized: true,
          color: IslamicColors.mysticBlue,
          styleInformation: BigTextStyleInformation(body,
              contentTitle: title,
              summaryText: 'Événement islamique'),
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // For now, show immediate notification as demo
        // In production, you'd use proper scheduling
        await _notifications.show(
          event.id.hashCode,
          title,
          body,
          details,
        );
      } catch (e) {
        debugPrint('[NotificationService] Show error: $e');
      }
    }

    // Save scheduled reminder
    await _saveScheduledReminder(event, reminderDate);

    debugPrint('Scheduled reminder for ${event.name} on ${reminderDate.toString()}');
  }

  static DateTime _calculateReminderDate(IslamicEvent event) {
    // Convert the Hijri event date to Gregorian and subtract 3 days
    final eventGregorian = event.date.toApproxGregorianDate();
    return eventGregorian.subtract(const Duration(days: 3));
  }



  static String _getNotificationBody(IslamicEvent event) {
    final fastingInfo = _getFastingRecommendation(event);
    if (fastingInfo.isNotEmpty) {
      return '${event.description}\n\n🌙 $fastingInfo';
    }
    return '${event.description}\n\nPréparez-vous pour ce jour béni avec du dhikr et des bonnes actions.';
  }

  static String _getFastingRecommendation(IslamicEvent event) {
    switch (event.id) {
      case 'ashura':
        return 'N\'oubliez pas de jeûner le jour d\'Ashura et le jour précédent ou suivant.';
      case 'arafat':
        return 'Préparez-vous à jeûner le jour d\'Arafat si vous ne faites pas le pèlerinage.';
      case 'laylat_nisf_shaban':
        return 'Considérez jeûner le jour suivant cette nuit bénie.';
      case 'hajj_start':
        return 'Préparez-vous à jeûner les 9 premiers jours de Dhul-Hijjah.';
      default:
        return '';
    }
  }

  static Future<void> _saveScheduledReminder(IslamicEvent event, DateTime reminderDate) async {
    final prefs = await SharedPreferences.getInstance();
    final existingReminders = prefs.getStringList(_scheduledRemindersKey) ?? [];
    
    final reminderData = {
      'eventId': event.id,
      'eventName': event.name,
      'reminderDate': reminderDate.toIso8601String(),
    };
    
    existingReminders.add(jsonEncode(reminderData));
    await prefs.setStringList(_scheduledRemindersKey, existingReminders);
  }

  static Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList(_scheduledRemindersKey) ?? [];
    
    return remindersJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  static Future<void> cancelReminder(String eventId) async {
    if (kIsWeb) {
      debugPrint('[NotificationService] Web: skipping cancel for id=$eventId');
    } else {
      try {
        await _notifications.cancel(eventId.hashCode);
      } catch (e) {
        debugPrint('[NotificationService] Cancel error for $eventId: $e');
      }
    }
    
    // Remove from saved reminders
    final prefs = await SharedPreferences.getInstance();
    final existingReminders = prefs.getStringList(_scheduledRemindersKey) ?? [];
    
    existingReminders.removeWhere((reminderJson) {
      final reminder = jsonDecode(reminderJson) as Map<String, dynamic>;
      return reminder['eventId'] == eventId;
    });
    
    await prefs.setStringList(_scheduledRemindersKey, existingReminders);
  }

  static Future<bool> isReminderScheduled(String eventId) async {
    final reminders = await getScheduledReminders();
    return reminders.any((reminder) => reminder['eventId'] == eventId);
  }

  static Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) {
      debugPrint('[NotificationService] Web: Instant notification -> $title | $body');
      return;
    }
    try {
      final androidDetails = AndroidNotificationDetails(
        'instant_channel',
        'Notifications Instantanées',
        channelDescription: 'Notifications immédiates pour l\'application Sajda',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.reminder,
        colorized: true,
        color: IslamicColors.mysticBlue,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[NotificationService] Instant show error: $e');
    }
  }

  // Encouragement notifications (daily)
  static Future<void> scheduleDailyEncouragements() async {
    if (kIsWeb) return;
    try {
      await _cancelByStoredIds(_scheduledEncouragementIdsKey);
      final prefs = await SharedPreferences.getInstance();
      final List<int> usedIds = [];

      final androidDetails = AndroidNotificationDetails(
        'encouragements_channel',
        'Encouragements Quotidiens',
        channelDescription: 'Messages de motivation et rappels spirituels',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.reminder,
        colorized: true,
        color: IslamicColors.mysticBlue,
        styleInformation: const BigTextStyleInformation(''),
      );
      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final messages = <(String title, String body, TimeOfDay time)>[
        ('Rappel Dhikr', '💖 Souviens-toi d’Allah aujourd’hui: SubhanAllah, Alhamdulillah, Allahu Akbar.', const TimeOfDay(hour: 9, minute: 0)),
        ('Lecture du Coran', '📖 Prends 5 minutes pour lire quelques versets. BarakAllahu fik.', const TimeOfDay(hour: 14, minute: 0)),
        ('Bilan du Soir', '🌙 Quelques adhkar avant de dormir apaisent le cœur. Tu peux le faire.', const TimeOfDay(hour: 20, minute: 30)),
      ];

      int baseId = 4200;
      for (final m in messages) {
        final id = baseId++;
        final next = _nextInstanceOfTime(m.$3.hour, m.$3.minute);
        await _notifications.zonedSchedule(
          id,
          m.$1,
          m.$2,
          next,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        usedIds.add(id);
      }

      await prefs.setStringList(_scheduledEncouragementIdsKey, usedIds.map((e) => e.toString()).toList());
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyEncouragements error: $e');
    }
  }

  static Future<void> cancelDailyEncouragements() async {
    if (kIsWeb) return;
    await _cancelByStoredIds(_scheduledEncouragementIdsKey);
  }

  // Schedule active non-prayer reminders as native notifications (weekly repeats)
  static Future<void> scheduleActiveReminders() async {
    if (kIsWeb) return;
    try {
      await _cancelByStoredIds(_scheduledGeneralIdsKey);
      final prefs = await SharedPreferences.getInstance();
      final List<int> usedIds = [];

      final active = ReminderService.getActiveReminders();
      if (active.isEmpty) return;

      final androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Rappels Spirituels',
        channelDescription: 'Rappels réguliers (Dhikr, Coran, etc.)',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.reminder,
        colorized: true,
        color: IslamicColors.mysticBlue,
        styleInformation: const BigTextStyleInformation(''),
      );
      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      int baseId = 3000;
      for (final r in active) {
        if (r.type == ReminderType.prayer) continue; // Prayer handled by dedicated service
        for (final day in r.days) {
          final id = baseId++;
          final next = _nextInstanceOfWeekday(day, r.time.hour, r.time.minute);
          await _notifications.zonedSchedule(
            id,
            r.title,
            '${r.message}\n${r.arabicMessage}',
            next,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'reminder:${r.id}',
          );
          usedIds.add(id);
        }
      }

      await prefs.setStringList(_scheduledGeneralIdsKey, usedIds.map((e) => e.toString()).toList());
    } catch (e) {
      debugPrint('[NotificationService] scheduleActiveReminders error: $e');
    }
  }

  static Future<void> cancelActiveReminders() async {
    if (kIsWeb) return;
    await _cancelByStoredIds(_scheduledGeneralIdsKey);
  }

  static Future<void> _cancelByStoredIds(String storageKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(storageKey) ?? const <String>[];
      for (final s in stored) {
        final id = int.tryParse(s);
        if (id != null) {
          await _notifications.cancel(id);
        }
      }
      await prefs.remove(storageKey);
    } catch (e) {
      debugPrint('[NotificationService] _cancelByStoredIds error: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // weekday: 1=Mon ... 7=Sun to match Reminder model
  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}