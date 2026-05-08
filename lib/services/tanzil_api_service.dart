import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight client for fetching Quran translations from Tanzil.
/// Default translation code: 'fr.hamidullah'
class TanzilApiService {
  static const String _baseTransUrl = 'https://tanzil.net/trans';

  // Verse counts per surah (1..114) according to Tanzil numbering
  static const List<int> _ayahCounts = [
    0, // placeholder for 0-index
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
  ];

  static List<int> get ayahCounts => List<int>.from(_ayahCounts);

  static int get totalAyahs => 6236;

  static int ayahCountForSurah(int surah) {
    if (surah < 1 || surah >= _ayahCounts.length) return 0;
    return _ayahCounts[surah];
  }

  static Map<String, int>? resolveFromGlobalIndex(int globalIndex) {
    if (globalIndex < 0) return null;
    int remaining = globalIndex;
    for (int surah = 1; surah < _ayahCounts.length; surah++) {
      final count = _ayahCounts[surah];
      if (remaining < count) {
        return {'surah': surah, 'ayah': remaining + 1};
      }
      remaining -= count;
    }
    return null;
  }

  static final Map<String, List<String>> _cacheByCode = {};

  /// Returns the full flattened list of ayah texts (length 6236) for a translation code.
  /// Caches in-memory for subsequent requests.
  static Future<List<String>> _getAllVerses(String code) async {
    if (_cacheByCode.containsKey(code)) return _cacheByCode[code]!;

    // Try a few common endpoints in order
    final candidates = <Uri>[
      Uri.parse('$_baseTransUrl/$code.json'),
      Uri.parse('$_baseTransUrl/$code.txt'),
      Uri.parse('$_baseTransUrl/$code'),
    ];

    for (final uri in candidates) {
      try {
        final res = await http.get(uri, headers: {'Accept': 'application/json, text/plain; charset=utf-8'});
        if (res.statusCode != 200 || (res.body.isEmpty)) continue;

        // Try JSON first
        try {
          final data = json.decode(res.body);
          // Possible formats: List<String> or {verses: List<String>} or List<Map{index,text}>
          List<String> verses;
          if (data is List) {
            if (data.isNotEmpty && data.first is String) {
              verses = List<String>.from(data);
            } else if (data.isNotEmpty && data.first is Map) {
              verses = data.map<String>((e) => e['text']?.toString() ?? '').toList();
            } else {
              continue;
            }
          } else if (data is Map && data['verses'] is List) {
            verses = List<String>.from(data['verses'].map((e) => e.toString()));
          } else {
            // Unknown JSON structure
            continue;
          }
          if (verses.length >= 6236) {
            _cacheByCode[code] = verses;
            return verses;
          }
        } catch (_) {
          // Not JSON, attempt plain text parsing
          final text = res.body;
          final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();

          // Tanzil formats commonly are either:
          // 1) "sura|ayah|text" per line
          // 2) Just one ayah per line (6236 lines)
          List<String> verses;
          if (lines.isNotEmpty && lines.first.contains('|')) {
            verses = lines.map((l) {
              final parts = l.split('|');
              return parts.length >= 3 ? parts.sublist(2).join('|').trim() : l.trim();
            }).toList();
          } else {
            verses = lines;
          }

          if (verses.length >= 6236) {
            _cacheByCode[code] = verses;
            return verses;
          }
        }
      } catch (_) {
        // try next candidate
        continue;
      }
    }

    throw Exception('Tanzil translation "$code" not available');
  }

  /// Get translation text for a specific ayah. 1-based surah and ayah.
  static Future<String?> getAyah(int surah, int ayah, {String code = 'fr.hamidullah'}) async {
    if (surah < 1 || surah > 114) return null;
    if (ayah < 1 || ayah > _ayahCounts[surah]) return null;

    final all = await _getAllVerses(code);
    final index = _globalIndex(surah, ayah);
    if (index < 0 || index >= all.length) return null;
    return all[index];
  }

  /// Get all translation verses for a surah. Returns a list of maps with numberInSurah and text.
  static Future<List<Map<String, dynamic>>> getSurahTranslation(int surah, {String code = 'fr.hamidullah'}) async {
    if (surah < 1 || surah > 114) return [];
    final all = await _getAllVerses(code);
    final start = _globalIndex(surah, 1);
    final count = _ayahCounts[surah];
    if (start < 0 || start + count > all.length) return [];
    final slice = all.sublist(start, start + count);
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < slice.length; i++) {
      list.add({
        'number': i + 1,
        'numberInSurah': i + 1,
        'text': slice[i],
      });
    }
    return list;
  }

  /// Compute 0-based global ayah index in the flattened list (length 6236)
  static int _globalIndex(int surah, int ayah) {
    int offset = 0;
    for (int s = 1; s < surah; s++) {
      offset += _ayahCounts[s];
    }
    return offset + (ayah - 1);
  }
}
