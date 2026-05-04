import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranComApiClient {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  // Fetch chapters and map to app's expected structure
  static Future<List<Map<String, dynamic>>> getChapters({String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/chapters?language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final chapters = (data['chapters'] as List?) ?? [];
      return chapters.map<Map<String, dynamic>>((c) {
        final place = (c['revelation_place'] ?? '').toString().toLowerCase();
        return {
          'number': c['id'],
          'name': c['name_arabic'] ?? c['name_complex'] ?? c['name_simple'],
          'englishName': c['name_simple'],
          'englishNameTranslation': (c['translated_name']?['name'] ?? ''),
          'numberOfAyahs': c['verses_count'] ?? 0,
          'revelationType': place.contains('makkah') || place.contains('mecca') ? 'Meccan' : 'Medinan',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch Arabic verses (text_uthmani) for a chapter
  static Future<List<Map<String, dynamic>>> _getArabicVerses(int chapter) async {
    try {
      final uri = Uri.parse('$baseUrl/verses/by_chapter/$chapter?language=ar&fields=text_uthmani&per_page=300');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final verses = (data['verses'] as List?) ?? [];
      return verses.map<Map<String, dynamic>>((v) {
        final key = v['verse_key']?.toString();
        final numIn = v['verse_number'] ?? (key != null ? int.tryParse(key.split(':').last) : null);
        return {
          'number': v['id'],
          'numberInSurah': numIn,
          'text': v['text_uthmani'] ?? v['text_uthmani_simple'] ?? (v['words'] is List && v['words'].isNotEmpty ? v['words'][0]['text_uthmani'] : ''),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch translation verses for a chapter (default French). translationId example: 131 (Muhammad Hamidullah)
  static Future<List<Map<String, dynamic>>> _getTranslatedVerses(int chapter, {int translationId = 131, String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/verses/by_chapter/$chapter?language=$language&translations=$translationId&per_page=300');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final verses = (data['verses'] as List?) ?? [];
      return verses.map<Map<String, dynamic>>((v) {
        final t = (v['translations'] as List?)?.isNotEmpty == true ? v['translations'][0] : null;
        final key = v['verse_key']?.toString();
        final numIn = v['verse_number'] ?? (key != null ? int.tryParse(key.split(':').last) : null);
        return {
          'number': v['id'],
          'numberInSurah': numIn,
          'text': t?['text'] ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch per-ayah audio files for a chapter. recitationId example: 7 (Mishary Alafasy)
  static Future<List<Map<String, dynamic>>> _getAyahAudio(int chapter, {int recitationId = 7}) async {
    try {
      final uri = Uri.parse('$baseUrl/recitations/$recitationId/by_chapter/$chapter?per_page=300');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final files = (data['audio_files'] as List?) ?? [];
      return files.map<Map<String, dynamic>>((f) => {
        'numberInSurah': f['verse_number'],
        'audio': f['audio_url'],
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Compose a full surah pack compatible with current UI consumption
  static Future<Map<String, dynamic>?> getSurahPack(int chapter, {int recitationId = 7, int translationId = 131, String translationLanguage = 'fr'}) async {
    try {
      final arabic = await _getArabicVerses(chapter);
      final trans = await _getTranslatedVerses(chapter, translationId: translationId, language: translationLanguage);
      final audio = await _getAyahAudio(chapter, recitationId: recitationId);

      if (arabic.isEmpty && trans.isEmpty && audio.isEmpty) return null;

      // Merge audio into arabic verses to produce audioData ayahs with text + audio
      final audioMap = {for (final a in audio) a['numberInSurah']: a['audio']};
      final audioAyahs = arabic.map<Map<String, dynamic>>((v) => {
        'numberInSurah': v['numberInSurah'],
        'text': v['text'],
        'audio': audioMap[v['numberInSurah']],
      }).toList();

      return {
        'arabic': {
          'ayahs': arabic,
        },
        'translation': {
          'ayahs': trans,
        },
        'english': {
          'ayahs': trans,
        },
        'audio': {
          'ayahs': audioAyahs,
        },
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getTranslations({String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/translations?language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final list = (data['translations'] as List?) ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRecitations({String language = 'en'}) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/recitations?language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body);
      final list = (data['recitations'] as List?) ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getChapterInfo(int chapter, {String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/chapters/$chapter/info?language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> search(String query, {String language = 'fr', int page = 0, int size = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}&size=$size&page=$page&language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRandomVerse({String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/verses/random?language=$language&fields=text_uthmani');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPageVerses(int page, {String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/pages/$page/verses?language=$language&fields=text_uthmani');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getJuz(int juz, {String language = 'fr'}) async {
    try {
      final uri = Uri.parse('$baseUrl/juzs/$juz?language=$language');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) return null;
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }
}