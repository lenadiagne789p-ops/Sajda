import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BackupService centralizes export/import of all locally stored data
/// using SharedPreferences. It also maintains lightweight restore points.
class BackupService {
  static const String _backupLatestKey = 'backup_auto_latest';
  static const String _backupHistoryKey = 'backup_history_json_list';
  static const int _historyLimit = 3;

  /// Collect every key/value currently in SharedPreferences.
  static Future<Map<String, dynamic>> _collectAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = <String, dynamic>{};

    for (final key in keys) {
      // Skip backup keys by default to avoid backing up backups
      if (key == _backupLatestKey || key == _backupHistoryKey) continue;

      final value = prefs.get(key);
      if (value is int || value is double || value is bool || value is String) {
        data[key] = value;
      } else if (value is List<String>) {
        data[key] = value;
      } else {
        // Unknown type; try to read as string to be safe
        final asString = prefs.getString(key);
        if (asString != null) {
          data[key] = asString;
        }
      }
    }

    return data;
  }

  /// Export all app data to a JSON string with metadata.
  static Future<String> exportAllToJson() async {
    final data = await _collectAllPrefs();
    final wrapped = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'mobile',
      'data': data,
    };
    return jsonEncode(wrapped);
  }

  /// Import data from a JSON string previously exported by [exportAllToJson].
  /// - overwrite: if true, existing keys will be overwritten when present in import
  static Future<void> importAllFromJson(String jsonString, {bool overwrite = true}) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('JSON invalide: $e');
    }

    if (!decoded.containsKey('data') || decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('Structure JSON inattendue: champ "data" manquant.');
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (!overwrite && prefs.containsKey(key)) {
        // Skip existing key when not overwriting
        continue;
      }

      // Write back using best matching setter
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        // Only String lists are supported by SharedPreferences
        final allStrings = value.every((e) => e is String);
        if (allStrings) {
          await prefs.setStringList(key, value.cast<String>());
        } else {
          // Fallback: store as String JSON
          await prefs.setString(key, jsonEncode(value));
        }
      } else {
        // Unknown structure: store as String JSON
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }

  /// Create or update a local auto-backup restore point and rotate history.
  static Future<void> createAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final json = await exportAllToJson();
    await prefs.setString(_backupLatestKey, json);

    // Maintain small history of backups (JSON strings)
    final history = prefs.getStringList(_backupHistoryKey) ?? <String>[];
    history.insert(0, json);
    while (history.length > _historyLimit) {
      history.removeLast();
    }
    await prefs.setStringList(_backupHistoryKey, history);
  }

  static Future<bool> hasAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_backupLatestKey);
  }

  static Future<void> restoreLatestAutoBackup({bool overwrite = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_backupLatestKey);
    if (json == null) {
      throw const FormatException('Aucun point de restauration disponible.');
    }
    await importAllFromJson(json, overwrite: overwrite);
  }
}
