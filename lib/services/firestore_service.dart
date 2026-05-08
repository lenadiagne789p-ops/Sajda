import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:sajda/models/user.dart' as app_user;
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/models/badge.dart';
import 'package:sajda/models/streak.dart';
import 'package:sajda/models/reminder.dart';
import 'package:sajda/services/subscription_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Cached user to reduce reads
  static app_user.User? _cachedUser;
  static final StreamController<void> _userChangedController = StreamController<void>.broadcast();
  static Stream<void> get userChanged => _userChangedController.stream;
  
  // Get current Firebase user ID
  static String? get _userId => auth.FirebaseAuth.instance.currentUser?.uid;
  
  // ========== USER OPERATIONS ==========
  
  /// Get user data from Firestore or create default
  static Future<app_user.User> getUser() async {
    if (_cachedUser != null) return _cachedUser!;
    
    final uid = _userId;
    if (uid == null) {
      // Not authenticated, return default user
      return _createDefaultUser();
    }
    
    try {
      final doc = await _db.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        // Create new user in Firestore
        final newUser = await _createUserInFirestore(uid);
        _cachedUser = newUser;
        return newUser;
      }
      
      var user = app_user.User.fromJson(doc.data()!);
      
      // Sync premium status
      final isPremium = await SubscriptionService.isPremium();
      if (user.isPremium != isPremium) {
        user = user.copyWith(isPremium: isPremium);
        await saveUser(user);
      }
      
      _cachedUser = user;
      return user;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user: $e');
      return _createDefaultUser();
    }
  }
  
  /// Save user data to Firestore
  static Future<void> saveUser(app_user.User user) async {
    _cachedUser = user;
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('users').doc(uid).set(user.toJson(), SetOptions(merge: true));
      
      // Update leaderboard entry
      await _updateLeaderboard(user);
      
      if (!_userChangedController.isClosed) {
        _userChangedController.add(null);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving user: $e');
    }
  }
  
  /// Create a new user document in Firestore
  static Future<app_user.User> _createUserInFirestore(String uid) async {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    final name = (firebaseUser?.displayName?.trim() ?? firebaseUser?.email?.split('@').first.trim() ?? '');
    
    final user = app_user.User(
      id: uid,
      name: name,
      avatarUrl: firebaseUser?.photoURL,
      totalHassanat: 0,
      currentLevel: 0,
      streak: 0,
      lastActivityDate: DateTime.now(),
      isPremium: await SubscriptionService.isPremium(),
    );
    
    await _db.collection('users').doc(uid).set(user.toJson());
    return user;
  }
  
  static app_user.User _createDefaultUser() {
    return app_user.User(
      id: 'local_user',
      name: '',
      totalHassanat: 0,
      currentLevel: 0,
      streak: 0,
      lastActivityDate: DateTime.now(),
      isPremium: false,
    );
  }
  
  /// Update leaderboard with user's current stats
  static Future<void> _updateLeaderboard(app_user.User user) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('leaderboard').doc(uid).set({
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'totalHassanat': user.totalHassanat,
        'currentLevel': user.currentLevel,
        'streak': user.streak,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating leaderboard: $e');
    }
  }
  
  /// Update user name
  static Future<void> updateUserName(String name) async {
    final user = await getUser();
    await saveUser(user.copyWith(name: name));
  }
  
  /// Update user avatar
  static Future<void> updateUserAvatar(String? url) async {
    final user = await getUser();
    await saveUser(user.copyWith(avatarUrl: (url != null && url.trim().isNotEmpty) ? url.trim() : null));
  }
  
  /// Add hassanat and update streaks
  static Future<void> addHassanat(int points) async {
    final user = await getUser();
    final now = DateTime.now();
    final lastDate = user.lastActivityDate;
    final daysDiff = now.difference(lastDate).inDays;
    
    int newStreak = user.streak;
    if (daysDiff >= 1) {
      if (daysDiff == 1) {
        newStreak += 1; // Consecutive day
      } else {
        newStreak = 1; // Reset streak
      }
    }
    
    final updatedUser = user.copyWith(
      totalHassanat: user.totalHassanat + points,
      streak: newStreak,
      lastActivityDate: now,
    );
    
    await saveUser(updatedUser);
  }
  
  // ========== DAILY ACTIONS ==========
  
  /// Get daily actions for today
  static Future<List<IslamicAction>> getDailyActions() async {
    final uid = _userId;
    if (uid == null) return _buildCuratedDailyActions();
    
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final snapshot = await _db
          .collection('daily_actions')
          .doc(uid)
          .collection('actions')
          .where('date', isEqualTo: dateKey)
          .limit(50)
          .get();
      
      if (snapshot.docs.isEmpty) {
        final curated = _buildCuratedDailyActions();
        await saveDailyActions(curated);
        return curated;
      }
      
      final defaults = IslamicAction.getDefaultActions();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final id = data['id'] as String;
        final defaultAction = defaults.firstWhere((a) => a.id == id, orElse: () => defaults.first);
        return defaultAction.copyWith(
          isCompleted: data['isCompleted'] ?? false,
          completionDate: data['completionDate'] != null ? (data['completionDate'] as Timestamp).toDate() : null,
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching daily actions: $e');
      return _buildCuratedDailyActions();
    }
  }

  /// Get the full catalog of actions with today's completion state merged
  static Future<List<IslamicAction>> getAllActionsForToday() async {
    final defaults = IslamicAction.getDefaultActions();
    final uid = _userId;
    if (uid == null) return defaults;

    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final snapshot = await _db
          .collection('daily_actions')
          .doc(uid)
          .collection('actions')
          .where('date', isEqualTo: dateKey)
          .limit(200)
          .get();

      final map = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        map[doc.data()['id'] as String] = doc.data();
      }
      return defaults.map((a) {
        final d = map[a.id];
        if (d == null) return a;
        return a.copyWith(
          isCompleted: (d['isCompleted'] ?? false) as bool,
          completionDate: d['completionDate'] != null ? (d['completionDate'] as Timestamp).toDate() : null,
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching full actions for today: $e');
      return defaults;
    }
  }
  
  /// Save daily actions
  static Future<void> saveDailyActions(List<IslamicAction> actions) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final batch = _db.batch();
      final collectionRef = _db.collection('daily_actions').doc(uid).collection('actions');
      
      for (final action in actions) {
        final docRef = collectionRef.doc('${dateKey}_${action.id}');
        batch.set(docRef, {
          'id': action.id,
          'date': dateKey,
          'isCompleted': action.isCompleted,
          'completionDate': action.completionDate != null ? Timestamp.fromDate(action.completionDate!) : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      // ignore: avoid_print
      print('Error saving daily actions: $e');
    }
  }
  
  /// Complete an action
  static Future<void> completeAction(String actionId) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final defaults = IslamicAction.getDefaultActions();
      final base = defaults.firstWhere(
        (a) => a.id == actionId,
        orElse: () => defaults.first,
      );

      // Upsert a single action document for today
      final docRef = _db
          .collection('daily_actions')
          .doc(uid)
          .collection('actions')
          .doc('${dateKey}_$actionId');
      await docRef.set({
        'id': actionId,
        'date': dateKey,
        'isCompleted': true,
        'completionDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await addHassanat(base.hassanatReward);
      // Track per-action streak for analytics/progression
      await updateActionStreakOnComplete(actionId);
    } catch (e) {
      // ignore: avoid_print
      print('Error completing action: $e');
    }
  }

  // ========== PINNED ACTIONS (ORDERED) ==========

  /// Returns the ordered list of pinned action IDs for the current user.
  static Future<List<String>> getPinnedActionOrder() async {
    final uid = _userId;
    if (uid == null) return <String>[];
    try {
      final doc = await _db.collection('user_settings').doc(uid).get();
      if (!doc.exists) return <String>[];
      final data = doc.data() ?? {};
      final pins = (data['pinnedActionOrder'] as List<dynamic>?)?.whereType<String>().toList() ?? <String>[];
      return pins;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching pinned order: $e');
      return <String>[];
    }
  }

  /// Persists the ordered list of pinned action IDs for the current user.
  static Future<void> setPinnedActionOrder(List<String> order) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _db.collection('user_settings').doc(uid).set({
        'pinnedActionOrder': order,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving pinned order: $e');
    }
  }

  /// Stream pinned action order for realtime UI refresh.
  static Stream<List<String>> pinnedActionOrderStream() {
    final uid = _userId;
    if (uid == null) return const Stream<List<String>>.empty();
    return _db.collection('user_settings').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() ?? {};
      final pins = (data['pinnedActionOrder'] as List<dynamic>?)?.whereType<String>().toList() ?? <String>[];
      return pins;
    });
  }

  // ========== PER-ACTION STREAKS ==========

  /// Returns a map actionId -> {currentStreak, bestStreak, lastCompletionDate}
  static Future<Map<String, Map<String, dynamic>>> getAllActionStreaks() async {
    final uid = _userId;
    if (uid == null) return <String, Map<String, dynamic>>{};
    try {
      final snap = await _db.collection('action_streaks').doc(uid).collection('actions').get();
      final result = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final data = d.data();
        result[d.id] = {
          'currentStreak': data['currentStreak'] ?? 0,
          'bestStreak': data['bestStreak'] ?? 0,
          'lastCompletionDate': data['lastCompletionDate'] is Timestamp
              ? (data['lastCompletionDate'] as Timestamp).toDate()
              : null,
        };
      }
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching action streaks: $e');
      return <String, Map<String, dynamic>>{};
    }
  }

  /// Increment and persist the streak for a specific action after completion.
  static Future<void> updateActionStreakOnComplete(String actionId) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final docRef = _db.collection('action_streaks').doc(uid).collection('actions').doc(actionId);
      final doc = await docRef.get();
      DateTime? last;
      int current = 0;
      int best = 0;
      if (doc.exists) {
        final data = doc.data()!;
        last = (data['lastCompletionDate'] is Timestamp) ? (data['lastCompletionDate'] as Timestamp).toDate() : null;
        current = (data['currentStreak'] ?? 0) as int;
        best = (data['bestStreak'] ?? 0) as int;
      }

      final now = DateTime.now();
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

      await docRef.set({
        'currentStreak': current,
        'bestStreak': best,
        'lastCompletionDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error updating action streak: $e');
    }
  }
  
  static List<IslamicAction> _buildCuratedDailyActions() {
    final all = IslamicAction.getDefaultActions();
    
    T find<T extends IslamicAction>(String id) {
      return all.firstWhere((a) => a.id == id) as T;
    }
    
    final items = <IslamicAction>[
      find('prayer_fajr'),
      find('prayer_dhuhr'),
      find('prayer_asr'),
      find('prayer_maghrib'),
      find('prayer_isha'),
    ];
    if (all.any((a) => a.id == 'prayer_on_time')) items.add(find('prayer_on_time'));
    
    if (all.any((a) => a.id == 'dhikr_morning')) items.add(find('dhikr_morning'));
    if (all.any((a) => a.id == 'dhikr_evening')) items.add(find('dhikr_evening'));
    if (all.any((a) => a.id == 'quran_reading')) items.add(find('quran_reading'));
    if (all.any((a) => a.id == 'sunnah_duha')) items.add(find('sunnah_duha'));
    if (all.any((a) => a.id == 'istighfar')) items.add(find('istighfar'));
    if (all.any((a) => a.id == 'salawat')) items.add(find('salawat'));
    if (all.any((a) => a.id == 'good_deed')) items.add(find('good_deed'));
    
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
  
  // ========== BADGES ==========
  
  /// Get badges for current user
  static Future<List<SpiritualBadge>> getBadges() async {
    final uid = _userId;
    if (uid == null) return SpiritualBadge.getDefaultBadges();
    
    try {
      final user = await getUser();
      final defaultBadges = SpiritualBadge.getDefaultBadges();
      
      final snapshot = await _db
          .collection('badges')
          .doc(uid)
          .collection('unlocked')
          .get();
      
      final unlockedIds = snapshot.docs.map((doc) => doc.data()['id'] as String).toSet();
      
      return defaultBadges.map((badge) {
        if (unlockedIds.contains(badge.id)) {
          final doc = snapshot.docs.firstWhere((d) => d.data()['id'] == badge.id);
          final data = doc.data();
          return badge.copyWith(
            isUnlocked: true,
            unlockedDate: data['unlockedDate'] != null ? (data['unlockedDate'] as Timestamp).toDate() : null,
          );
        }
        
        // Auto-unlock if requirements met
        if (user.totalHassanat >= badge.requiredHassanat && !badge.isUnlocked) {
          final unlockedBadge = badge.copyWith(isUnlocked: true, unlockedDate: DateTime.now());
          _unlockBadge(uid, unlockedBadge);
          return unlockedBadge;
        }
        
        return badge;
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching badges: $e');
      return SpiritualBadge.getDefaultBadges();
    }
  }
  
  static Future<void> _unlockBadge(String uid, SpiritualBadge badge) async {
    try {
      await _db.collection('badges').doc(uid).collection('unlocked').doc(badge.id).set({
        'id': badge.id,
        'unlockedDate': Timestamp.fromDate(badge.unlockedDate!),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error unlocking badge: $e');
    }
  }
  
  // ========== STREAKS ==========
  
  /// Get user streaks
  static Future<List<Streak>> getStreaks() async {
    final uid = _userId;
    if (uid == null) return Streak.getDefaultStreaks();
    
    try {
      final snapshot = await _db
          .collection('streaks')
          .doc(uid)
          .collection('user_streaks')
          .get();
      
      if (snapshot.docs.isEmpty) {
        return Streak.getDefaultStreaks();
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final defaults = Streak.getDefaultStreaks();
        final defaultStreak = defaults.firstWhere((s) => s.id == doc.id, orElse: () => defaults.first);
        
        return defaultStreak.copyWith(
          currentStreak: data['currentStreak'] ?? 0,
          bestStreak: data['bestStreak'] ?? 0,
          lastCompletionDate: data['lastCompletionDate'] != null ? (data['lastCompletionDate'] as Timestamp).toDate() : null,
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching streaks: $e');
      return Streak.getDefaultStreaks();
    }
  }
  
  /// Save streak
  static Future<void> saveStreak(Streak streak) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('streaks').doc(uid).collection('user_streaks').doc(streak.id).set({
        'currentStreak': streak.currentStreak,
        'bestStreak': streak.bestStreak,
        'lastCompletionDate': streak.lastCompletionDate != null ? Timestamp.fromDate(streak.lastCompletionDate!) : null,
        'isActive': streak.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving streak: $e');
    }
  }
  
  // ========== REMINDERS ==========
  
  /// Get user reminders
  static Future<List<Reminder>> getReminders() async {
    final uid = _userId;
    if (uid == null) return Reminder.getDefaultReminders();
    
    try {
      final snapshot = await _db
          .collection('reminders')
          .doc(uid)
          .collection('user_reminders')
          .get();
      
      if (snapshot.docs.isEmpty) {
        return Reminder.getDefaultReminders();
      }
      
      return snapshot.docs.map((doc) => Reminder.fromJson(doc.data())).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching reminders: $e');
      return Reminder.getDefaultReminders();
    }
  }
  
  /// Save reminder
  static Future<void> saveReminder(Reminder reminder) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('reminders').doc(uid).collection('user_reminders').doc(reminder.id).set({
        ...reminder.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error saving reminder: $e');
    }
  }
  
  /// Delete reminder
  static Future<void> deleteReminder(String reminderId) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('reminders').doc(uid).collection('user_reminders').doc(reminderId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting reminder: $e');
    }
  }
  
  // ========== QURAN READING DATA ==========
  
  /// Get Quran reading data
  static Future<Map<String, dynamic>> getQuranReadingData() async {
    final uid = _userId;
    if (uid == null) return {};
    
    try {
      final doc = await _db.collection('quran_reading').doc(uid).get();
      if (!doc.exists) return {};
      return doc.data() ?? {};
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching Quran reading data: $e');
      return {};
    }
  }
  
  /// Set Quran reading data
  static Future<void> setQuranReadingData(Map<String, dynamic> data) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      await _db.collection('quran_reading').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving Quran reading data: $e');
    }
  }
  
  /// Get Quran recitation stats
  static Future<Map<String, dynamic>> getQuranRecitationStats() async {
    final data = await getQuranReadingData();
    return data['recitationStats'] ?? {
      'totalAyahsRecited': 0,
      'totalSurahsCompleted': 0,
      'favoriteReciter': 'ar.alafasy',
      'totalListeningTime': 0,
      'completedSurahs': <int>[],
      'currentProgress': {},
    };
  }
  
  /// Update Quran recitation stats
  static Future<void> updateQuranRecitationStats(Map<String, dynamic> stats) async {
    final data = await getQuranReadingData();
    data['recitationStats'] = stats;
    await setQuranReadingData(data);
  }
  
  // ========== PRAYER COMPLETION ==========
  
  /// Get prayer completion for a specific date
  static Future<Map<String, bool>> getPrayerDoneForDate(DateTime date) async {
    final uid = _userId;
    if (uid == null) return {};
    
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await _db.collection('prayer_completion').doc(uid).collection('dates').doc(dateKey).get();
      
      if (!doc.exists) return {};
      
      final data = doc.data() ?? {};
      return data.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching prayer completion: $e');
      return {};
    }
  }
  
  /// Set prayer completion for a specific date
  static Future<void> setPrayerDoneForDate(DateTime date, Map<String, bool> values) async {
    final uid = _userId;
    if (uid == null) return;
    
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _db.collection('prayer_completion').doc(uid).collection('dates').doc(dateKey).set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error saving prayer completion: $e');
    }
  }
  
  // ========== LEADERBOARD ==========
  
  /// Get top users from leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection('leaderboard')
          .orderBy('totalHassanat', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching leaderboard: $e');
      return [];
    }
  }
  
  /// Get user's rank in leaderboard
  static Future<int> getUserRank() async {
    final uid = _userId;
    if (uid == null) return -1;
    
    try {
      final user = await getUser();
      final snapshot = await _db
          .collection('leaderboard')
          .where('totalHassanat', isGreaterThan: user.totalHassanat)
          .get();
      
      return snapshot.docs.length + 1;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user rank: $e');
      return -1;
    }
  }
  
  // ========== UTILITY ==========
  
  /// Clear cached data
  static void clearCache() {
    _cachedUser = null;
  }
  
  /// Listen to user changes in real-time
  static Stream<app_user.User?> userStream() {
    final uid = _userId;
    if (uid == null) return Stream.value(null);
    
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final user = app_user.User.fromJson(doc.data()!);
      _cachedUser = user;
      return user;
    });
  }
}
