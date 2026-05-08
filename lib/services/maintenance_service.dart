import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sajda/services/backup_service.dart';
import 'package:sajda/services/notification_service.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/utils/performance_monitor.dart';

/// Central maintenance scheduler/runner.
/// Runs lightweight jobs at startup and once per day while the app is open.
class MaintenanceService {
  static Timer? _heartbeat;
  static DateTime? _lastRunDate; // yyyy-mm-dd granularity

  /// Initialize background heartbeat and perform a startup maintenance pass.
  static Future<void> initialize() async {
    // Run immediately but non-blocking
    // ignore: discarded_futures
    runStartupMaintenance();

    // Heartbeat: check every 15 minutes for date rollover
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _maybeRunDailyMaintenance();
    });
  }

  static Future<void> dispose() async {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  /// Public manual trigger (useful for tests)
  static Future<void> runNow() async {
    await _runAllSafe(daily: true);
  }

  static Future<void> runStartupMaintenance() async {
    await _runAllSafe(daily: false);
    // Ensure we mark last run to today so we don't double-run immediately
    final now = DateTime.now();
    _lastRunDate = DateTime(now.year, now.month, now.day);
  }

  static Future<void> _maybeRunDailyMaintenance() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastRunDate == null || _lastRunDate!.difference(today).inDays != 0) {
      await _runAllSafe(daily: true);
      _lastRunDate = today;
    }
  }

  static Future<void> _runAllSafe({required bool daily}) async {
    try {
      PerformanceMonitor.startTimer('maintenance_total');

      // Always run these at startup and daily
      await _refreshDailyActionsIfStale();
      await _pruneOldPrayerDoneKeys(keepDays: 30);
      await _pruneExpiredCaches(prefix: 'cache:');

      // Rotate backup and tidy reminders only on daily pass
      if (daily) {
        await _rotateAutoBackup();
        await _dedupeAndPruneScheduledReminders();
        // Re-schedule soft notifications to align with timezone/day
        try {
          await NotificationService.scheduleDailyEncouragements();
          await NotificationService.scheduleActiveReminders();
        } catch (e) {
          debugPrint('[Maintenance] schedule notifications error: $e');
        }
      }
    } catch (e) {
      debugPrint('[Maintenance] error: $e');
    } finally {
      PerformanceMonitor.stopTimer('maintenance_total');
    }
  }

  // --- Jobs ---

  static Future<void> _refreshDailyActionsIfStale() async {
    try {
      // StorageService.getDailyActions already regenerates if outdated.
      // Calling it ensures today's plan exists early in the day.
      await StorageService.getDailyActions();
    } catch (e) {
      debugPrint('[Maintenance] refresh daily actions error: $e');
    }
  }

  static Future<void> _pruneOldPrayerDoneKeys({required int keepDays}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (!key.startsWith('prayer_done:')) continue;
        final datePart = key.substring('prayer_done:'.length);
        DateTime? date;
        try {
          final parts = datePart.split('-').map((e) => int.tryParse(e)).toList();
          if (parts.length == 3 && parts[0] != null && parts[1] != null && parts[2] != null) {
            date = DateTime(parts[0]!, parts[1]!, parts[2]!);
          }
        } catch (_) {}
        if (date == null) {
          // Unknown format -> remove to be safe
          await prefs.remove(key);
          continue;
        }
        final ageDays = now.difference(date).inDays;
        if (ageDays > keepDays) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[Maintenance] prune prayer_done keys error: $e');
    }
  }

  static Future<void> _pruneExpiredCaches({required String prefix}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (final key in keys) {
        if (!key.startsWith(prefix)) continue;
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) {
          await prefs.remove(key);
          continue;
        }
        try {
          final decoded = json.decode(raw);
          if (decoded is Map<String, dynamic>) {
            final ts = decoded['ts'];
            if (ts is int) {
              // Default TTL aligned with StorageService.getCachedJson (24h)
              final expired = (nowMs - ts) > const Duration(hours: 24).inMilliseconds;
              if (expired) {
                await prefs.remove(key);
              }
            } else {
              // Corrupted wrapper -> remove
              await prefs.remove(key);
            }
          } else {
            await prefs.remove(key);
          }
        } catch (_) {
          await prefs.remove(key); // Invalid JSON -> drop
        }
      }
    } catch (e) {
      debugPrint('[Maintenance] prune caches error: $e');
    }
  }

  static Future<void> _rotateAutoBackup() async {
    try {
      await BackupService.createAutoBackup();
    } catch (e) {
      debugPrint('[Maintenance] auto-backup error: $e');
    }
  }

  static Future<void> _dedupeAndPruneScheduledReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Uses NotificationService internal key
      const key = 'scheduled_islamic_reminders';
      final list = prefs.getStringList(key) ?? <String>[];
      if (list.isEmpty) return;

      final seen = <String, String>{}; // eventId -> json
      final pruned = <String>[];
      for (final item in list) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          final id = map['eventId']?.toString();
          final dateStr = map['reminderDate']?.toString();
          if (id == null || dateStr == null) continue;
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          if (date.isBefore(DateTime.now())) {
            // Past reminder -> skip
            continue;
          }
          // Keep the most recent entry if duplicates
          if (!seen.containsKey(id)) {
            seen[id] = item;
          } else {
            final prev = json.decode(seen[id]!) as Map<String, dynamic>;
            final prevDate = DateTime.tryParse(prev['reminderDate']?.toString() ?? '') ?? date;
            if (date.isAfter(prevDate)) {
              seen[id] = item;
            }
          }
        } catch (_) {
          // skip invalid item
        }
      }
      pruned.addAll(seen.values);
      await prefs.setStringList(key, pruned);
    } catch (e) {
      debugPrint('[Maintenance] prune reminders error: $e');
    }
  }
}
