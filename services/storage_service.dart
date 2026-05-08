import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/islamic_action.dart';
import '../models/badge.dart';
import '../utils/performance_monitor.dart';
import 'subscription_service.dart';
import 'reminder_service.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _badgesKey = 'unlocked_badges';
  static const String _dailyActionsKey = 'daily_actions';
  static const String _dailyActionsHistoryKey = 'daily_actions_history';
  static const String _firstTimeKey = 'first_time_user';
  static const String _forceLogoutOnceKey = 'force_logout_once';
  static const String _pinnedActionsKey = 'pinned_actions_ids';
  static const String _pinnedActionsOrderKey = 'pinned_actions_order';
  static const String _actionStreaksKey = 'action_streaks_map';
  static const String _languageCodeKey = 'app_language_code';
  static const String _themeModeKey = 'app_theme_mode';

  static SharedPreferences? _cachedPrefs;
  static Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  // Broadcast changes to user data so UI can refresh live
  static final StreamController<void> _userChangedController =
      StreamController<void>.broadcast();
  static Stream<void> get userChanged => _userChangedController.stream;

  // Broadcast changes to daily actions so home widgets can refresh counters (0/12)
  static final StreamController<void> _dailyActionsChangedController =
      StreamController<void>.broadcast();
  static Stream<void> get dailyActionsChanged => _dailyActionsChangedController.stream;

  // Broadcast changes to pinned actions so Home can refresh the pinned section
  static final StreamController<void> _pinnedActionsChangedController =
      StreamController<void>.broadcast();
  static Stream<void> get pinnedActionsChanged => _pinnedActionsChangedController.stream;

  // User data methods
  static User? _cachedUser;
  static Future<User> getUser() async {
    PerformanceMonitor.startTimer('getUser');
    try {
      // Local storage only (Firebase removed)
      if (_cachedUser != null) {
        PerformanceMonitor.stopTimer('getUser');
        return _cachedUser!;
      }
      final prefs = await _prefs;
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        var user = User.fromJson(json.decode(userData));
        // Sync premium flag with subscription/trial status
        final premiumNow = await SubscriptionService.isPremium();
        if (user.isPremium != premiumNow) {
          user = user.copyWith(isPremium: premiumNow);
          await saveUser(user);
        }
        _cachedUser = user;
        PerformanceMonitor.stopTimer('getUser');
        return _cachedUser!;
      }
      // Return default user (no generic "Utilisateur" fallback)
      final defaultUser = User(
        id: 'current_user_${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        totalHassanat: 0,
        currentLevel: 0,
        streak: 0,
        lastActivityDate: DateTime.now(),
        isPremium: await SubscriptionService.isPremium(),
      );
      await saveUser(defaultUser);
      PerformanceMonitor.stopTimer('getUser');
      return defaultUser;
    } catch (e) {
      PerformanceMonitor.stopTimer('getUser');
      rethrow;
    }
  }

  static Future<void> saveUser(User user) async {
    _cachedUser = user;
    
    // Save to local storage only
    final prefs = await _prefs;
    // IMPORTANT: Avoid Firestore-specific types in local JSON (Timestamp/FieldValue)
    // Serialize a clean, JSON-encodable map for SharedPreferences
    final localJson = {
      'id': user.id,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'totalHassanat': user.totalHassanat,
      'currentLevel': user.currentLevel,
      'streak': user.streak,
      'lastActivityDate': user.lastActivityDate.toIso8601String(),
      'isPremium': user.isPremium,
    };
    await prefs.setString(_userKey, json.encode(localJson));
    
    // Notify listeners that user data changed
    if (!_userChangedController.isClosed) {
      _userChangedController.add(null);
    }
  }

  /// Returns the locally stored user without consulting Firebase auth state.
  /// Useful to merge offline progress back to server on next login.
  static Future<User?> getLocalUserOnly() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_userKey);
      if (raw == null || raw.isEmpty) return null;
      return User.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Explicitly clear the local-only user snapshot (used after merging into server).
  static Future<void> clearLocalUser() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_userKey);
    } catch (_) {}
  }

  static Future<void> updateUserName(String name) async {
    final user = await getUser();
    final updatedUser = user.copyWith(name: name);
    await saveUser(updatedUser);
  }

  static Future<void> updateUserAvatar(String? url) async {
    final user = await getUser();
    final updatedUser = user.copyWith(avatarUrl: (url != null && url.trim().isNotEmpty) ? url.trim() : null);
    await saveUser(updatedUser);
  }

  // First time user methods
  static Future<bool> isFirstTime() async {
    final prefs = await _prefs;
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeCompleted() async {
    final prefs = await _prefs;
    await prefs.setBool(_firstTimeKey, false);
  }

  /// Réactive l'onboarding pour revoir l'écran de présentation
  static Future<void> resetOnboardingFlag() async {
    final prefs = await _prefs;
    await prefs.setBool(_firstTimeKey, true);
  }

  /// Consomme un indicateur de déconnexion forcée (true par défaut si absent),
  /// puis le positionne à false pour ne l'exécuter qu'une seule fois.
  static Future<bool> consumeForceLogoutFlag() async {
    final prefs = await _prefs;
    final value = prefs.getBool(_forceLogoutOnceKey);
    await prefs.setBool(_forceLogoutOnceKey, false);
    return value ?? true; // Par défaut: forcer une fois
  }

  static Future<void> addHassanat(int points) async {
    // Local implementation only (no Firestore)
    final user = await getUser();
    final now = DateTime.now();
    final lastDate = user.lastActivityDate;
    final isNewDay = now.difference(lastDate).inDays >= 1;
    final isConsecutiveDay = now.difference(lastDate).inDays == 1;
    int newStreak = user.streak;
    if (isNewDay) {
      if (isConsecutiveDay) {
        newStreak += 1;
      } else if (now.difference(lastDate).inDays > 1) {
        newStreak = 1;
      }
    }
    final updatedUser = user.copyWith(
      totalHassanat: user.totalHassanat + points,
      streak: newStreak,
      lastActivityDate: now,
    );
    await saveUser(updatedUser);
    // saveUser already emits the change event
  }

  // Daily actions methods
  /// Returns the full catalog of actions for today with completion state merged.
  /// If signed-in, delegates to Firestore; otherwise, reads the local snapshot for today
  /// and overlays completion flags onto the default catalog.
  static Future<List<IslamicAction>> getAllActionsForToday() async {
    // Local-only implementation
    try {
      final defaults = IslamicAction.getDefaultActions();
      final prefs = await _prefs;
      final actionsData = prefs.getString(_dailyActionsKey);
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      Map<String, Map<String, dynamic>> map = {};
      if (actionsData != null && actionsData.isNotEmpty) {
        final data = json.decode(actionsData);
        if (data is Map<String, dynamic> && data['date'] == todayString) {
          final List<dynamic> actionsList = data['actions'] ?? <dynamic>[];
          for (final item in actionsList) {
            if (item is Map<String, dynamic> && item['id'] is String) {
              map[item['id']] = item;
            }
          }
        }
      }

      return defaults.map((a) {
        final m = map[a.id];
        if (m == null) return a;
        return a.copyWith(
          isCompleted: (m['isCompleted'] ?? false) as bool,
          completionDate: m['completionDate'] != null
              ? DateTime.tryParse(m['completionDate'] as String)
              : null,
        );
      }).toList();
    } catch (_) {
      // On any failure, still return the full default catalog without completion overlay
      return IslamicAction.getDefaultActions();
    }
  }

  static Future<List<IslamicAction>> getDailyActions() async {
    // Local storage only
    try {
      final prefs = await _prefs;
      final actionsData = prefs.getString(_dailyActionsKey);
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (actionsData != null && actionsData.isNotEmpty) {
        final data = json.decode(actionsData);
        if (data is Map<String, dynamic> && data['date'] == todayString) {
          final List<dynamic> actionsList = data['actions'] ?? <dynamic>[];
          if (actionsList.isNotEmpty) {
            final defaults = IslamicAction.getDefaultActions();
            return actionsList.map((actionData) {
              final String id = actionData['id'];
              final defaultAction = defaults.firstWhere((a) => a.id == id, orElse: () => defaults.first);
              return defaultAction.copyWith(
                isCompleted: actionData['isCompleted'] ?? false,
                completionDate: actionData['completionDate'] != null ? DateTime.parse(actionData['completionDate']) : null,
              );
            }).toList();
          }
        }
      }

      // No valid saved actions for today -> build a curated daily plan (~12 items)
      final curated = _buildCuratedDailyActions();
      await saveDailyActions(curated);
      return curated;
    } catch (_) {
      // Fallback safe: still provide a small meaningful set instead of the whole catalog
      final curated = _buildCuratedDailyActions();
      await saveDailyActions(curated);
      return curated;
    }
  }

  static Future<void> saveDailyActions(List<IslamicAction> actions) async {
    // Local storage only
    final prefs = await _prefs;
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final data = {
      'date': todayString,
      'actions': actions.map((action) => {
            'id': action.id,
            'isCompleted': action.isCompleted,
            'completionDate': action.completionDate?.toIso8601String(),
          }).toList(),
    };
    await prefs.setString(_dailyActionsKey, json.encode(data));
    // Mirror into a rolling history (keep last 60 days)
    try {
      final rawHistory = prefs.getString(_dailyActionsHistoryKey);
      Map<String, dynamic> history = {};
      if (rawHistory != null && rawHistory.isNotEmpty) {
        final decoded = json.decode(rawHistory);
        if (decoded is Map<String, dynamic>) history = decoded;
      }
      history[todayString] = data;
      // Trim to last 60 entries by date
      final keys = history.keys.toList()
        ..sort((a, b) => a.compareTo(b)); // ascending
      if (keys.length > 60) {
        final toRemove = keys.sublist(0, keys.length - 60);
        for (final k in toRemove) {
          history.remove(k);
        }
      }
      await prefs.setString(_dailyActionsHistoryKey, json.encode(history));
    } catch (_) {}
    // Notify listeners that daily actions changed (for real-time UI refresh)
    if (!_dailyActionsChangedController.isClosed) {
      _dailyActionsChangedController.add(null);
    }
  }

  /// Construit un plan d'actions quotidiennes concis et pertinent pour la journée (~12)
  static List<IslamicAction> _buildCuratedDailyActions() {
    final all = IslamicAction.getDefaultActions();

    T find<T extends IslamicAction>(String id) {
      return all.firstWhere((a) => a.id == id) as T;
    }

    // Base: prières obligatoires (5)
    final items = <IslamicAction>[
      find('prayer_fajr'),
      find('prayer_dhuhr'),
      find('prayer_asr'),
      find('prayer_maghrib'),
      find('prayer_isha'),
    ];

    // Suivi global: prier à l'heure (ajoutée en plus des 5)
    if (all.any((a) => a.id == 'prayer_on_time')) items.add(find('prayer_on_time'));

    // Dhikr matin/soir (2)
    if (all.any((a) => a.id == 'dhikr_morning')) items.add(find('dhikr_morning'));
    if (all.any((a) => a.id == 'dhikr_evening')) items.add(find('dhikr_evening'));

    // Lecture du Coran (1)
    if (all.any((a) => a.id == 'quran_reading')) items.add(find('quran_reading'));

    // Sunnah légère du jour (1) — Duha si présent
    if (all.any((a) => a.id == 'sunnah_duha')) items.add(find('sunnah_duha'));

    // Adorations récurrentes simples (2)
    if (all.any((a) => a.id == 'istighfar')) items.add(find('istighfar'));
    if (all.any((a) => a.id == 'salawat')) items.add(find('salawat'));

    // Bonnes actions sociales/familiales (2, pick safe defaults if present)
    if (all.any((a) => a.id == 'good_deed')) items.add(find('good_deed'));
    if (all.any((a) => a.id == 'help_neighbor')) {
      items.add(find('help_neighbor'));
    } else if (all.any((a) => a.id == 'respect_parents')) {
      items.add(find('respect_parents'));
    }

    // Cap à ~12 éléments, dédoublonnage par id (sécurité)
    final seen = <String>{};
    final curated = <IslamicAction>[];
    for (final a in items) {
      if (!seen.contains(a.id)) {
        curated.add(a);
        seen.add(a.id);
      }
      if (curated.length >= 12) break;
    }
    return curated;
  }

  static Future<void> completeAction(String actionId) async {
    // Local implementation only
    // Upsert completion for any action (even if not part of the curated 12)
    try {
      final prefs = await _prefs;
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Load today's snapshot (or initialize)
      Map<String, dynamic> todayData = {'date': todayString, 'actions': <Map<String, dynamic>>[]};
      final raw = prefs.getString(_dailyActionsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic> && decoded['date'] == todayString) {
          todayData = decoded;
        }
      }

      // Build current list and index by id
      final List<dynamic> list = (todayData['actions'] as List?)?.toList() ?? <dynamic>[];
      final List<Map<String, dynamic>> normalized = list
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'id': e['id'],
                'isCompleted': e['isCompleted'] ?? false,
                'completionDate': e['completionDate'],
              })
          .where((e) => e['id'] is String)
          .toList();

      final idx = normalized.indexWhere((e) => e['id'] == actionId);
      if (idx >= 0) {
        if (!(normalized[idx]['isCompleted'] as bool)) {
          normalized[idx]['isCompleted'] = true;
          normalized[idx]['completionDate'] = DateTime.now().toIso8601String();
        }
      } else {
        normalized.add({
          'id': actionId,
          'isCompleted': true,
          'completionDate': DateTime.now().toIso8601String(),
        });
      }

      // Persist back using existing save routine (keeps history in sync)
      // Map normalized back to IslamicAction list for saveDailyActions
      final defaults = IslamicAction.getDefaultActions();
      final byId = {for (final a in defaults) a.id: a};
      final toSave = <IslamicAction>[];
      for (final m in normalized) {
        final base = byId[m['id']] ?? defaults.first;
        toSave.add(base.copyWith(
          isCompleted: (m['isCompleted'] ?? false) as bool,
          completionDate: m['completionDate'] != null
              ? DateTime.tryParse(m['completionDate'] as String)
              : null,
        ));
      }
      await saveDailyActions(toSave);

      // Hassanat and streaks from the canonical model entry
      final canonical = byId[actionId];
      if (canonical != null) {
        await addHassanat(canonical.hassanatReward);
      }
      await updateActionStreakOnComplete(actionId);

      // Ensure history mirrors the updated completion state (saveDailyActions already mirrors)
    } catch (_) {
      // ignore write failures
    }
  }

  /// Retourne l'historique local des actions quotidiennes (par date) si non connecté à Firestore
  /// Map<YYYY-MM-DD, {date, actions: [{id, isCompleted, completionDate}]}>
  static Future<Map<String, dynamic>> getLocalDailyActionsHistory() async {
    try {
      final prefs = await _prefs;
      final rawHistory = prefs.getString(_dailyActionsHistoryKey);
      if (rawHistory == null || rawHistory.isEmpty) return <String, dynamic>{};
      final decoded = json.decode(rawHistory);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // Badge methods
  static Future<List<SpiritualBadge>> getBadges() async {
    // Local storage only
    final prefs = await _prefs;
    final badgesData = prefs.getString(_badgesKey);
    final user = await getUser();
    final defaultBadges = SpiritualBadge.getDefaultBadges();
    if (badgesData != null) {
      final List<dynamic> unlockedBadgesData = json.decode(badgesData);
      final unlockedIds = unlockedBadgesData.map((badge) => badge['id']).toSet();
      return defaultBadges.map((badge) {
        if (unlockedIds.contains(badge.id)) {
          final unlockedBadge = unlockedBadgesData.firstWhere((b) => b['id'] == badge.id);
          return badge.copyWith(isUnlocked: true, unlockedDate: DateTime.parse(unlockedBadge['unlockedDate']));
        }
        return badge;
      }).toList();
    }
    final updatedBadges = <SpiritualBadge>[];
    final newlyUnlocked = <SpiritualBadge>[];
    for (final badge in defaultBadges) {
      if (user.totalHassanat >= badge.requiredHassanat && !badge.isUnlocked) {
        final unlockedBadge = badge.copyWith(isUnlocked: true, unlockedDate: DateTime.now());
        updatedBadges.add(unlockedBadge);
        newlyUnlocked.add(unlockedBadge);
      } else {
        updatedBadges.add(badge);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      await _saveBadges(updatedBadges.where((b) => b.isUnlocked).toList());
    }
    return updatedBadges;
  }

  static Future<void> _saveBadges(List<SpiritualBadge> unlockedBadges) async {
    final prefs = await _prefs;
    final badgesData = unlockedBadges.map((badge) => {'id': badge.id, 'unlockedDate': badge.unlockedDate?.toIso8601String()}).toList();
    await prefs.setString(_badgesKey, json.encode(badgesData));
  }

  static Future<void> resetAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // --------------------
  // Language (Locale) persistence
  // --------------------
  static Future<String> getLanguageCode() async {
    try {
      final prefs = await _prefs;
      final code = prefs.getString(_languageCodeKey);
      if (code != null && (code == 'ar' || code == 'fr' || code == 'en')) return code;
      return 'fr';
    } catch (_) {
      return 'fr';
    }
  }

  static Future<void> setLanguageCode(String code) async {
    try {
      final prefs = await _prefs;
      // Persist only supported languages; default to 'fr'
      final supported = {'fr', 'en', 'ar'};
      await prefs.setString(_languageCodeKey, supported.contains(code) ? code : 'fr');
    } catch (_) {
      // ignore write failures silently
    }
  }

  // --------------------
  // Theme mode persistence (light / dark / system)
  // --------------------
  static Future<String> getThemeModeCode() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_themeModeKey) ?? 'system';
    } catch (_) {
      return 'system';
    }
  }

  static Future<void> setThemeModeCode(String code) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_themeModeKey, code);
    } catch (_) {}
  }

  // --------------------
  // Daily prayer completion state (per-day persistence, auto-expires by date key)
  // Keys are namespaced as: prayer_done:YYYY-MM-DD
  // --------------------
  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          .toString();

  static String _prayerDoneKeyFor(DateTime date) => 'prayer_done:${_dateKey(date)}';

  /// Returns a map like {"fajr": true/false, "dhuhr": ..., "asr": ..., "maghrib": ..., "isha": ...}
  static Future<Map<String, bool>> getPrayerDoneForDate(DateTime date) async {
    // Local storage only
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_prayerDoneKeyFor(date));
      if (raw == null || raw.isEmpty) return <String, bool>{};
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) return <String, bool>{};
      // Sanitize booleans
      final result = <String, bool>{};
      for (final e in decoded.entries) {
        final v = e.value;
        if (v is bool) result[e.key] = v;
      }
      return result;
    } catch (_) {
      return <String, bool>{};
    }
  }

  static Future<void> setPrayerDoneForDate(DateTime date, Map<String, bool> values) async {
    // Local storage only
    try {
      final prefs = await _prefs;
      await prefs.setString(_prayerDoneKeyFor(date), json.encode(values));
    } catch (_) {
      // ignore write failures
    }
  }

  // --------------------
  // Generic JSON cache (with TTL) for API payloads
  // Keys should be namespaced, e.g. "cache:quran:..."
  // --------------------
  static Future<Map<String, dynamic>?> getCachedJson(String key, {Duration ttl = const Duration(hours: 24)}) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final ts = decoded['ts'];
      final data = decoded['data'];
      if (ts is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > ttl.inMilliseconds) {
        // Expired -> remove to keep storage clean
        await prefs.remove(key);
        return null;
      }
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      // Corrupted entry -> remove and ignore
      try {
        final prefs = await _prefs;
        await prefs.remove(key);
      } catch (_) {}
      return null;
    }
  }

  static Future<void> setCachedJson(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await _prefs;
      final wrapped = {
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, json.encode(wrapped));
    } catch (e) {
      // ignore write failures silently
    }
  }

  // Pinned actions methods
  static Future<Set<String>> getPinnedActionIds() async {
    // Prefer ordered list to build a set (backward compatible)
    final order = await getPinnedActionOrder();
    if (order.isNotEmpty) return order.toSet();
    final prefs = await _prefs;
    final legacy = prefs.getStringList(_pinnedActionsKey) ?? <String>[];
    return legacy.toSet();
  }

  /// Returns the ordered list of pinned action IDs (local or Firestore if signed-in)
  static Future<List<String>> getPinnedActionOrder() async {
    final prefs = await _prefs;
    final order = prefs.getStringList(_pinnedActionsOrderKey);
    if (order != null) return List<String>.from(order);
    // Fallback to legacy set ordering if present
    final legacy = prefs.getStringList(_pinnedActionsKey);
    return legacy != null ? List<String>.from(legacy) : <String>[];
  }

  /// Persist the ordered list of pinned action IDs
  static Future<void> setPinnedActionsOrder(List<String> order) async {
    final prefs = await _prefs;
    await prefs.setStringList(_pinnedActionsOrderKey, order);
    // Keep legacy key loosely in sync for older readers
    await prefs.setStringList(_pinnedActionsKey, order);
    if (!_pinnedActionsChangedController.isClosed) {
      _pinnedActionsChangedController.add(null);
    }
  }

  static Future<bool> isActionPinned(String actionId) async {
    final ids = await getPinnedActionIds();
    return ids.contains(actionId);
  }

  static Future<void> togglePinnedAction(String actionId) async {
    final currentOrder = await getPinnedActionOrder();
    final isPinned = currentOrder.contains(actionId);
    if (isPinned) {
      currentOrder.removeWhere((id) => id == actionId);
      await setPinnedActionsOrder(currentOrder);
      // If there is a reminder attached to this action, disable it (soft-remove)
      try {
        await _disableRemindersForAction(actionId);
      } catch (_) {}
    } else {
      currentOrder.add(actionId);
      await setPinnedActionsOrder(currentOrder);
      // Auto-create a daily reminder for this pinned action (can be edited later)
      try {
        await _ensureReminderForPinnedAction(actionId);
      } catch (_) {}
    }
  }

  static Future<void> _ensureReminderForPinnedAction(String actionId) async {
    final List<Reminder> all = ReminderService.getReminders();
    final existing = all.where((Reminder r) => r.actionId == actionId).toList();
    if (existing.isNotEmpty) {
      // Ensure it is active
      for (final r in existing) {
        if (!r.isActive) {
          await ReminderService.updateReminder(r.copyWith(isActive: true));
        }
      }
    } else {
      final defaults = IslamicAction.getDefaultActions();
      final action = defaults.firstWhere((a) => a.id == actionId, orElse: () => defaults.first);
      final type = _mapActionTypeToReminderType(action.type);
      final reminder = Reminder(
        id: 'act_${actionId}_reminder',
        title: 'Rappel — ${action.title}',
        message: 'N\'oubliez pas: ${action.title}',
        arabicMessage: action.arabicTitle,
        time: const TimeOfDay(hour: 20, minute: 0),
        days: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        type: type,
        actionId: actionId,
      );
      await ReminderService.addReminder(reminder);
    }
    await NotificationService.scheduleActiveReminders();
  }

  static Future<void> _disableRemindersForAction(String actionId) async {
    final List<Reminder> all = ReminderService.getReminders();
    bool changed = false;
    for (final Reminder r in all.where((Reminder r) => r.actionId == actionId)) {
      if (r.isActive) {
        await ReminderService.updateReminder(r.copyWith(isActive: false));
        changed = true;
      }
    }
    if (changed) {
      await NotificationService.scheduleActiveReminders();
    }
  }

  static ReminderType _mapActionTypeToReminderType(ActionType t) {
    switch (t) {
      case ActionType.prayer:
        return ReminderType.prayer;
      case ActionType.dhikr:
        return ReminderType.dhikr;
      case ActionType.quranReading:
        return ReminderType.quran;
      case ActionType.charity:
        return ReminderType.charity;
      case ActionType.goodDeed:
        return ReminderType.general;
      case ActionType.hadith:
      case ActionType.sunnah:
      case ActionType.socialService:
      case ActionType.family:
      case ActionType.worship:
      case ActionType.names99:
        return ReminderType.general;
    }
  }

  // ========== PER-ACTION STREAKS (local mirror) ==========

  /// Returns actionId -> {currentStreak:int, bestStreak:int, lastCompletionDate:String}
  static Future<Map<String, Map<String, dynamic>>> getLocalActionStreaks() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_actionStreaksKey);
      if (raw == null || raw.isEmpty) return <String, Map<String, dynamic>>{};
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) return <String, Map<String, dynamic>>{};
      final result = <String, Map<String, dynamic>>{};
      for (final e in decoded.entries) {
        final v = e.value;
        if (v is Map<String, dynamic>) {
          result[e.key] = v;
        }
      }
      return result;
    } catch (_) {
      return <String, Map<String, dynamic>>{};
    }
  }

  static Future<void> _saveLocalActionStreaks(Map<String, Map<String, dynamic>> data) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_actionStreaksKey, json.encode(data));
    } catch (_) {}
  }

  /// Get all action streaks (Firestore if signed-in, else local)
  static Future<Map<String, Map<String, dynamic>>> getAllActionStreaks() async {
    return getLocalActionStreaks();
  }

  /// Update per-action streak on completion
  static Future<void> updateActionStreakOnComplete(String actionId) async {
    final all = await getLocalActionStreaks();
    final now = DateTime.now();
    final existing = all[actionId];
    DateTime? last;
    int current = 0;
    int best = 0;
    if (existing != null) {
      final lastStr = existing['lastCompletionDate'] as String?;
      if (lastStr != null) {
        try { last = DateTime.parse(lastStr); } catch (_) {}
      }
      current = (existing['currentStreak'] ?? 0) as int;
      best = (existing['bestStreak'] ?? 0) as int;
    }
    bool sameDay = false;
    if (last != null) {
      sameDay = last.year == now.year && last.month == now.month && last.day == now.day;
    }
    if (!sameDay) {
      final daysDiff = last == null ? 9999 : now.difference(last).inDays;
      if (daysDiff == 1 || last == null) {
        current = (last == null) ? 1 : (current + 1);
      } else if (daysDiff > 1) {
        current = 1;
      }
      if (current > best) best = current;
    }
    all[actionId] = {
      'currentStreak': current,
      'bestStreak': best,
      'lastCompletionDate': now.toIso8601String(),
    };
    await _saveLocalActionStreaks(all);
  }

  /// Obtient les données de lecture du Coran
  static Future<Map<String, dynamic>> getQuranReadingData() async {
    // Local storage only
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString('quran_reading_data');
      if (jsonString != null) {
        return json.decode(jsonString);
      }
      return {};
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la récupération des données de lecture du Coran: $e');
      return {};
    }
  }

  /// Sauvegarde les données de lecture du Coran
  static Future<void> setQuranReadingData(Map<String, dynamic> data) async {
    // Local storage only
    try {
      final prefs = await _prefs;
      await prefs.setString('quran_reading_data', json.encode(data));
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la sauvegarde des données de lecture du Coran: $e');
    }
  }

  /// Obtient les statistiques de récitation du Coran
  static Future<Map<String, dynamic>> getQuranRecitationStats() async {
    // Local storage only
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString('quran_recitation_stats');
      if (jsonString != null) {
        return json.decode(jsonString);
      }
      return {
        'totalAyahsRecited': 0,
        'totalSurahsCompleted': 0,
        'favoriteReciter': 'ar.alafasy',
        'totalListeningTime': 0,
        'completedSurahs': <int>[],
        'currentProgress': {},
      };
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la récupération des statistiques de récitation: $e');
      return {};
    }
  }

  /// Met à jour les statistiques de récitation du Coran
  static Future<void> updateQuranRecitationStats(Map<String, dynamic> stats) async {
    // Local storage only
    try {
      final prefs = await _prefs;
      await prefs.setString('quran_recitation_stats', json.encode(stats));
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la mise à jour des statistiques de récitation: $e');
    }
  }
}