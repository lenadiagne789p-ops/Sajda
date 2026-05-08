import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/models/sajda_verse.dart';
import 'package:sajda/services/quran_audio_service.dart';
import 'package:sajda/services/quran_com_api_client.dart';
import 'package:sajda/services/tanzil_api_service.dart';

class QuranApiService {
  static const String baseUrl = 'https://alquran-api.pages.dev/api';
  static const String legacyBaseUrl = 'https://quranapi.pages.dev/api';
  static const String githubCdnBase = 'https://cdn.jsdelivr.net/gh/saikothasan/quran-api@latest';
  static const String githubRawBase = 'https://raw.githubusercontent.com/saikothasan/quran-api/main';
  static const String fallbackUrl = 'http://api.alquran.cloud/v1';
  static const String alQuranCloudUrl = 'https://api.alquran.cloud/v1';
  static const String quraniBaseUrl = 'https://api.qurani.ai/gw/qh/v1';

  static const Map<String, String> availableEditions = {
    'ar.alafasy': 'Arabe avec récitation Alafasy',
    'ar.husary': 'Arabe avec récitation Husary',
    'ar.minshawi': 'Arabe avec récitation Minshawi',
    'ar.sudais': 'Arabe avec récitation Sudais',
    'ar.muyassar': 'Arabe littéraire (Al‑Muyassar)',
    'quran-simple': 'Texte arabe simple',
    'quran-uthmani': 'Texte arabe Uthmani',
    'fr.hamidullah': 'Traduction française Hamidullah',
    'en.asad': 'Traduction anglaise Muhammad Asad',
    'en.sahih': 'Traduction anglaise Sahih International',
    'en.pickthall': 'Traduction anglaise Pickthall',
  };

  static final RegExp _htmlTagRegex = RegExp(r'<[^>]+>');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');
  static final RegExp _decimalEntityRegex = RegExp(r'&#(\d+);');
  static final RegExp _hexEntityRegex = RegExp(r'&#x([0-9A-Fa-f]+);');
  static const Map<String, String> _htmlEntityMap = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&rsquo;': "'",
    '&lsquo;': "'",
    '&rdquo;': '"',
    '&ldquo;': '"',
    '&hellip;': '...',
    '&mdash;': '--',
    '&ndash;': '-',
    '&lt;': '<',
    '&gt;': '>',
  };

  static const Map<int, String> _recitationEditionMap = {
    1: 'ar.husary',
    2: 'ar.minshawi',
    3: 'ar.sudais',
    7: 'ar.alafasy',
  };

  static final Map<String, Map<String, dynamic>> _fullEditionCache = {};
  static final Map<String, DateTime> _fullEditionCacheTimestamps = {};
  static const Duration _fullEditionCacheTtl = Duration(hours: 12);
  static final Map<String, Map<String, dynamic>> _githubRecitationCache = {};
  static final Map<String, DateTime> _githubRecitationCacheTimestamps = {};
  static const Duration _githubRecitationCacheTtl = Duration(hours: 12);
  static final Map<String, Map<String, dynamic>> _quraniSurahCache = {};
  static final Map<String, DateTime> _quraniSurahCacheTimestamps = {};
  static const Duration _quraniSurahCacheTtl = Duration(hours: 6);

  // Persistent cache TTLs
  static const Duration _surahPackCacheTtl = Duration(hours: 48);
  static const Duration _readingCacheTtl = Duration(hours: 12);

  static String? _normalizeAudioUrl(String? url) {
    if (url == null) return null;
    var value = url.trim();
    if (value.isEmpty) return null;
    value = value.replaceAll('\\', '/');
    if (value.startsWith('//')) {
      value = 'https:$value';
    }
    if (value.startsWith('http://')) {
      value = 'https://${value.substring(7)}';
    }
    if (!value.startsWith('https://')) {
      final cleaned = value.startsWith('/') ? value.substring(1) : value;
      value = '$githubCdnBase/$cleaned';
    }
    return value;
  }

  static String sanitizeTranslationText(String text) {
    var cleaned = text.replaceAll('\r', ' ').replaceAll('\n', ' ');
    cleaned = cleaned.replaceAll(_htmlTagRegex, ' ');
    _htmlEntityMap.forEach((entity, replacement) {
      cleaned = cleaned.replaceAll(entity, replacement);
    });
    cleaned = cleaned.replaceAllMapped(_decimalEntityRegex, (match) {
      final code = int.tryParse(match.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : '';
    });
    cleaned = cleaned.replaceAllMapped(_hexEntityRegex, (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      return code != null ? String.fromCharCode(code) : '';
    });
    cleaned = cleaned.replaceAll(_whitespaceRegex, ' ').trim();
    return cleaned;
  }

  static void _sanitizeTranslationPayload(Map<String, dynamic>? payload) {
    if (payload == null) return;
    final ayahs = payload['ayahs'];
    if (ayahs is List) {
      for (final ayah in ayahs) {
        if (ayah is Map<String, dynamic>) {
          final raw = ayah['text'];
          if (raw is String && raw.isNotEmpty) {
            ayah['text'] = sanitizeTranslationText(raw);
          }
        }
      }
    }
  }

  static void _sanitizeTranslationList(List<dynamic>? ayahs) {
    if (ayahs == null) return;
    for (final ayah in ayahs) {
      if (ayah is Map<String, dynamic>) {
        final raw = ayah['text'];
        if (raw is String && raw.isNotEmpty) {
          ayah['text'] = sanitizeTranslationText(raw);
        }
      }
    }
  }

  static void _normalizeAudioPayload(Map<String, dynamic>? payload) {
    if (payload == null) return;
    final ayahs = payload['ayahs'];
    if (ayahs is List) {
      for (final ayah in ayahs) {
        if (ayah is! Map<String, dynamic>) continue;
        final primary = _normalizeAudioUrl(ayah['audio'] as String?);
        if (primary != null) {
          ayah['audio'] = primary;
        } else {
          ayah.remove('audio');
        }
        final secondary = ayah['audioSecondary'];
        if (secondary is List) {
          final normalized = <String>[];
          for (final item in secondary) {
            if (item is! String) continue;
            final resolved = _normalizeAudioUrl(item);
            if (resolved != null) normalized.add(resolved);
          }
          ayah['audioSecondary'] = _mergeUniqueUrls(normalized);
        }
      }
    }

    final primaryUrl = _normalizeAudioUrl(payload['surahUrl'] as String?);
    if (primaryUrl != null) {
      payload['surahUrl'] = primaryUrl;
    } else {
      payload.remove('surahUrl');
    }

    final list = payload['surahUrls'];
    if (list is List) {
      payload['surahUrls'] = _mergeUniqueUrls(list);
    }
  }

  static List<String> _buildPrimaryEndpoints(String relativePath) {
    final cleaned = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return [
      '$baseUrl/$cleaned',
      '$legacyBaseUrl/$cleaned',
    ];
  }

  static Future<Map<String, dynamic>?> _fetchJsonFromEndpoints(
    List<String> endpoints, {
    Duration timeout = const Duration(seconds: 12),
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(Uri.parse(endpoint), headers: mergedHeaders)
            .timeout(timeout);
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<dynamic> _fetchQuraniJson(
    String relativePath, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final cleaned = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    final url = '$quraniBaseUrl/$cleaned';
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'sajda-app-quran-client',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  static bool _isQuraniCacheValid(String key) {
    final timestamp = _quraniSurahCacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _quraniSurahCacheTtl;
  }

  static void _cacheQuraniSurah(String key, Map<String, dynamic> value) {
    _quraniSurahCache[key] = _cloneMap(value);
    _quraniSurahCacheTimestamps[key] = DateTime.now();
  }

  static Future<Map<String, dynamic>?> _getSurahFromQurani(
    int surahNumber, {
    required String edition,
  }) async {
    final normalizedEdition = edition.trim();
    if (normalizedEdition.isEmpty) return null;
    final cacheKey = '$normalizedEdition:$surahNumber';
    if (_quraniSurahCache.containsKey(cacheKey) && _isQuraniCacheValid(cacheKey)) {
      final cached = _quraniSurahCache[cacheKey];
      if (cached != null) return _cloneMap(cached);
    }

    final payload = await _fetchQuraniJson('surah/$surahNumber/$normalizedEdition');
    final normalized = _normalizeQuraniSurah(payload, surahNumber);
    if (normalized != null && normalized.isNotEmpty) {
      _cacheQuraniSurah(cacheKey, normalized);
      return normalized;
    }
    return null;
  }

  static Map<String, dynamic>? _normalizeQuraniSurah(dynamic payload, int surahNumber) {
    if (payload == null) return null;
    final queue = <dynamic>[payload];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current is Map<String, dynamic>) {
        if (current.isEmpty) continue;
        if (current.containsKey('status') && current['status'] == 'error') continue;
        final normalized = _tryNormalizeQuraniNode(current, surahNumber);
        if (normalized != null && normalized.isNotEmpty) return normalized;
        for (final value in current.values) {
          if (value is Map<String, dynamic> || value is List) {
            queue.add(value);
          }
        }
      } else if (current is List) {
        if (current.isEmpty) continue;
        final normalized = _tryNormalizeQuraniList(current, surahNumber);
        if (normalized != null && normalized.isNotEmpty) return normalized;
        for (final item in current) {
          if (item is Map<String, dynamic> || item is List) {
            queue.add(item);
          }
        }
      }
    }

    return null;
  }

  static Map<String, dynamic>? _tryNormalizeQuraniNode(Map<String, dynamic> node, int surahNumber) {
    final map = Map<String, dynamic>.from(node);

    // Normalize ayah containers to a list when possible
    if (map['ayahs'] is Map) {
      final ayahMap = map['ayahs'] as Map;
      map['ayahs'] = ayahMap.entries
          .where((entry) => entry.value is Map)
          .map<Map<String, dynamic>>((entry) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            data['numberInSurah'] ??= _parseInt(entry.key) ?? _parseInt(data['ayah']) ?? _parseInt(data['verse']);
            return data;
          })
          .toList()
        ..sort((a, b) => (_parseInt(a['numberInSurah']) ?? 0).compareTo(_parseInt(b['numberInSurah']) ?? 0));
    }

    if (map['verses'] is Map) {
      final ayahMap = map['verses'] as Map;
      map['verses'] = ayahMap.entries
          .where((entry) => entry.value is Map)
          .map<Map<String, dynamic>>((entry) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            data['numberInSurah'] ??= _parseInt(entry.key) ?? _parseInt(data['ayah']) ?? _parseInt(data['verse']);
            return data;
          })
          .toList()
        ..sort((a, b) => (_parseInt(a['numberInSurah']) ?? 0).compareTo(_parseInt(b['numberInSurah']) ?? 0));
    }

    final listCandidate = map['ayahs'] ?? map['verses'] ?? map['ayat'] ?? map['items'];
    if (listCandidate is List && listCandidate.isNotEmpty) {
      final surahData = <String, dynamic>{
        ...map,
        'number': _parseInt(map['number']) ?? _parseInt(map['surah']) ?? _parseInt(map['chapter']) ?? surahNumber,
        'ayahs': listCandidate,
      };
      return _normalizeSurah(surahData, includeAudio: false);
    }

    if (map['data'] is List) {
      final surahData = <String, dynamic>{
        ...map,
        'number': _parseInt(map['number']) ?? surahNumber,
        'ayahs': map['data'],
      };
      return _normalizeSurah(surahData, includeAudio: false);
    }

    if (map.containsKey('verse') && map.containsKey('text')) {
      // Single ayah object; treat as list of one
      final ayahNumber = _parseInt(map['verse']) ?? _parseInt(map['ayah']) ?? _parseInt(map['numberInSurah']);
      if (ayahNumber != null) {
        return _normalizeSurah({
          'number': surahNumber,
          'ayahs': [
            {
              ...map,
              'numberInSurah': ayahNumber,
            },
          ],
        }, includeAudio: false);
      }
    }

    return null;
  }

  static Map<String, dynamic>? _tryNormalizeQuraniList(List<dynamic> list, int surahNumber) {
    if (list.isEmpty) return null;
    final ayahs = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        ayahs.add(Map<String, dynamic>.from(item));
      }
    }
    if (ayahs.isEmpty) return null;
    return _normalizeSurah({
      'number': surahNumber,
      'ayahs': ayahs,
    }, includeAudio: false);
  }

  static bool _isCacheValid(String key) {
    if (!_fullEditionCache.containsKey(key)) return false;
    final timestamp = _fullEditionCacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _fullEditionCacheTtl;
  }

  static void _cacheEdition(String key, Map<String, dynamic> value) {
    _fullEditionCache[key] = value;
    _fullEditionCacheTimestamps[key] = DateTime.now();
  }

  static bool _isGithubRecitationCacheValid(String key) {
    if (!_githubRecitationCache.containsKey(key)) return false;
    final timestamp = _githubRecitationCacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _githubRecitationCacheTtl;
  }

  static void _cacheGithubRecitation(String key, Map<String, dynamic> value) {
    _githubRecitationCache[key] = value;
    _githubRecitationCacheTimestamps[key] = DateTime.now();
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Future<Map<String, dynamic>?> _getFullEditionData(String edition) async {
    if (_isCacheValid(edition)) {
      return _fullEditionCache[edition];
    }

    final endpoints = _buildPrimaryEndpoints('quran/$edition');
    final primary = await _fetchJsonFromEndpoints(endpoints, timeout: const Duration(seconds: 14));
    if (primary != null && primary.isNotEmpty) {
      _cacheEdition(edition, primary);
      return primary;
    }

    final githubEdition = await _fetchEditionFromGithub(edition);
    if (githubEdition != null && githubEdition.isNotEmpty) {
      _cacheEdition(edition, githubEdition);
      return githubEdition;
    }

    // Fallback vers l'API AlQuranCloud qui partage les mêmes éditions
    final fallbackCandidates = <String>[];
    if (edition.startsWith('ar.') || edition.startsWith('en.') || edition.startsWith('fr.') || edition.startsWith('quran')) {
      fallbackCandidates.add('$alQuranCloudUrl/quran/$edition');
    }
    if (fallbackCandidates.isNotEmpty) {
      try {
        final fallback = await _fetchJsonFromEndpoints(
          fallbackCandidates,
          timeout: const Duration(seconds: 14),
        );
        if (fallback != null && fallback.isNotEmpty) {
          _cacheEdition(edition, fallback);
          return fallback;
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _fetchEditionFromGithub(String edition) async {
    final payload = await _fetchGithubJson(_buildGithubEditionCandidates(edition));
    if (payload is Map<String, dynamic>) return payload;
    return null;
  }

  static List<String> _buildGithubEditionCandidates(String edition) {
    final normalized = edition.trim();
    if (normalized.isEmpty) return const [];
    final dash = normalized.replaceAll('.', '-');
    final underscore = normalized.replaceAll('.', '_');

    final candidates = <String>{
      'editions/$normalized.json',
      'editions/$normalized.min.json',
      'editions/$dash.json',
      'editions/$dash.min.json',
      'editions/$underscore.json',
      'editions/$underscore.min.json',
      'audio/$normalized.json',
      'audio/$dash.json',
      'audio/$underscore.json',
      'audio/recitations/$normalized.json',
      'audio/recitations/$dash.json',
      'audio/recitations/$underscore.json',
      'recitations/$normalized.json',
      'recitations/$dash.json',
      'recitations/$underscore.json',
      'data/editions/$normalized.json',
      'data/audio/$normalized.json',
      'data/recitations/$normalized.json',
      '$normalized.json',
      '$underscore.json',
      '$dash.json',
    };

    return candidates.where((c) => c.isNotEmpty).toList();
  }

  static Future<dynamic> _fetchGithubJson(Iterable<String> relativePaths) async {
    final seen = <String>{};
    const githubBases = [githubCdnBase, githubRawBase];

    for (final base in githubBases) {
      for (final relative in relativePaths) {
        if (relative.isEmpty) continue;
        final url = '$base/$relative';
        if (!seen.add(url)) continue;
        try {
          final response = await http.get(Uri.parse(url), headers: {
            'Accept': 'application/json',
            'User-Agent': 'sajda-app-quran-client',
          }).timeout(const Duration(seconds: 12));
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            return json.decode(response.body);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  static bool _matchesSurahNumber(Map<String, dynamic> data, int target) {
    final candidates = [
      data['number'],
      data['surahNumber'],
      data['surah_number'],
      data['chapter'],
      data['chapterNumber'],
      data['chapter_number'],
      data['id'],
      data['index'],
    ];
    for (final candidate in candidates) {
      final parsed = _parseInt(candidate);
      if (parsed != null && parsed == target) return true;
    }
    return false;
  }

  static Map<String, dynamic>? _extractSurahFromEditionData(Map<String, dynamic> editionData, int surahNumber) {
    dynamic data = editionData['data'] ?? editionData['result'] ?? editionData['surahs'];
    if (data is Map<String, dynamic>) {
      // Structure: { data: { surahs: [...] } }
      final nestedKeys = ['surahs', 'chapters', 'data', 'verses', 'items'];
      for (final key in nestedKeys) {
        final value = data[key];
        if (value is List) {
          final match = value.cast<dynamic>().firstWhere(
                (item) => item is Map<String, dynamic> && _matchesSurahNumber(item, surahNumber),
                orElse: () => null,
              );
          if (match is Map<String, dynamic>) return match;
        } else if (value is Map<String, dynamic>) {
          final direct = value['$surahNumber'] ?? value[surahNumber];
          if (direct is Map<String, dynamic>) return direct;
        }
      }

      if (_matchesSurahNumber(data, surahNumber)) {
        return Map<String, dynamic>.from(data);
      }
    } else if (data is List) {
      final match = data.cast<dynamic>().firstWhere(
            (item) => item is Map<String, dynamic> && _matchesSurahNumber(item, surahNumber),
            orElse: () => null,
          );
      if (match is Map<String, dynamic>) return match;
    }

    // Some payloads embed the surah directly at root
    if (_matchesSurahNumber(editionData, surahNumber)) {
      return Map<String, dynamic>.from(editionData);
    }

    return null;
  }

  static List<Map<String, dynamic>> _normalizeAyahs(dynamic ayahsRaw, {bool includeAudio = false}) {
    if (ayahsRaw is! List) return [];
    final normalized = <Map<String, dynamic>>[];

    for (var i = 0; i < ayahsRaw.length; i++) {
      final raw = ayahsRaw[i];
      if (raw is! Map<String, dynamic>) continue;

      final numberInSurah = _parseInt(raw['numberInSurah']) ??
          _parseInt(raw['number_in_surah']) ??
          _parseInt(raw['ayah']) ??
          _parseInt(raw['verse']) ??
          _parseInt(raw['id']) ??
          (i + 1);
      final text = _extractAyahText(raw) ?? '';

      final entry = <String, dynamic>{
        'numberInSurah': numberInSurah,
        'text': text,
      };

      if (includeAudio) {
        final audio = _extractAyahAudio(raw);
        if (audio != null && audio.isNotEmpty) {
          entry['audio'] = audio;
        }
        final secondary = _extractAyahAudioSecondary(raw);
        if (secondary.isNotEmpty) {
          entry['audioSecondary'] = secondary;
        }
      }

      normalized.add(entry);
    }

    return normalized;
  }

  static String? _extractAyahText(Map<String, dynamic> ayah) {
    final textCandidates = [
      ayah['text'],
      ayah['textUthmani'],
      ayah['text_uthmani'],
      ayah['ayahText'],
      ayah['verse'],
      ayah['content'],
      ayah['arabic'],
      ayah['arabic_text'],
      ayah['quran_text'],
      ayah['uthmani'],
    ];

    for (final candidate in textCandidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  static String? _extractAyahAudio(Map<String, dynamic> ayah) {
    final audio = ayah['audio'] ?? ayah['audioPrimary'] ?? ayah['audio_primary'] ?? ayah['audio_url'];
    if (audio is String) {
      return _normalizeAudioUrl(audio);
    }
    if (audio is List && audio.isNotEmpty) {
      for (final item in audio) {
        if (item is String) {
          final candidate = _normalizeAudioUrl(item);
          if (candidate != null) return candidate;
        }
      }
    }
    if (audio is Map && audio['url'] is String) {
      return _normalizeAudioUrl(audio['url'] as String);
    }

    final additionalKeys = ['primary', 'src', 'file', 'mp3'];
    for (final key in additionalKeys) {
      final value = ayah[key];
      if (value is String) {
        final candidate = _normalizeAudioUrl(value);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  static List<String> _extractAyahAudioSecondary(Map<String, dynamic> ayah) {
    final urls = <String>{};
    final candidates = [
      ayah['audioSecondary'],
      ayah['audio_secondary'],
      ayah['audio_secondary_urls'],
      ayah['audioSecondaryUrls'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          if (item is String) {
            final normalized = _normalizeAudioUrl(item);
            if (normalized != null) urls.add(normalized);
          }
        }
      }
    }

    return urls.toList();
  }

  static Map<String, dynamic> _normalizeSurah(
    Map<String, dynamic> raw, {
    bool includeAudio = false,
  }) {
    final number = _parseInt(raw['number']) ??
        _parseInt(raw['surahNumber']) ??
        _parseInt(raw['chapter']) ??
        _parseInt(raw['chapter_number']) ??
        _parseInt(raw['id']) ??
        0;
    final ayahs = _normalizeAyahs(
      raw['ayahs'] ?? raw['verses'] ?? raw['items'] ?? raw['data'],
      includeAudio: includeAudio,
    );

    final revelation = (raw['revelationType'] ?? raw['revelation_type'] ?? raw['revelationCity'] ?? raw['revelation']).toString();

    return {
      'number': number,
      'name': raw['name'] ?? raw['arabicName'] ?? raw['surahName'] ?? raw['title'] ?? '',
      'englishName': raw['englishName'] ?? raw['english_name'] ?? raw['latinName'] ?? raw['transliteration'] ?? '',
      'englishNameTranslation': raw['englishNameTranslation'] ??
          raw['translation'] ??
          raw['translatedName'] ??
          (raw['translated_name'] is Map ? raw['translated_name']['name'] : raw['translated_name']) ??
          '',
      'revelationType': revelation.isNotEmpty ? revelation : 'Unknown',
      'numberOfAyahs': _parseInt(raw['numberOfAyahs']) ?? _parseInt(raw['ayahCount']) ?? ayahs.length,
      'ayahs': ayahs,
    };
  }

  static Map<String, dynamic>? _mergeAudioWithArabic(
    Map<String, dynamic> audioSurah,
    Map<String, dynamic>? arabicSurah,
    int surahNumber,
    int recitationId,
  ) {
    final audioAyahs = (audioSurah['ayahs'] is List)
        ? List<Map<String, dynamic>>.from(audioSurah['ayahs'] as List)
        : _normalizeAyahs(audioSurah['ayahs'], includeAudio: true);

    if (audioAyahs.isEmpty) return null;

    final arabicAyahs = (arabicSurah != null && arabicSurah['ayahs'] is List)
        ? List<Map<String, dynamic>>.from(arabicSurah['ayahs'] as List)
        : <Map<String, dynamic>>[];

    final arabicMap = <int, String>{};
    for (final ayah in arabicAyahs) {
      final number = _parseInt(ayah['numberInSurah']);
      if (number != null) {
        final text = ayah['text'];
        if (text is String) arabicMap[number] = text;
      }
    }

    final merged = <Map<String, dynamic>>[];
    for (final ayah in audioAyahs) {
      final number = _parseInt(ayah['numberInSurah']);
      if (number == null) continue;

      final entry = <String, dynamic>{
        'numberInSurah': number,
        'text': arabicMap[number] ?? ayah['text'] ?? '',
      };

      final audioUrl = ayah['audio'] ?? _extractAyahAudio(ayah);
      if (audioUrl is String && audioUrl.isNotEmpty) {
        entry['audio'] = audioUrl;
      }
      if (ayah['audioSecondary'] is List) {
        entry['audioSecondary'] = ayah['audioSecondary'];
      }
      merged.add(entry);
    }

    merged.sort((a, b) {
      final left = _parseInt(a['numberInSurah']) ?? 0;
      final right = _parseInt(b['numberInSurah']) ?? 0;
      return left.compareTo(right);
    });

    final primaryUrls = _extractFullSurahAudioUrls(audioSurah);
    final fallbackUrls = QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: recitationId);
    final combined = _mergeUniqueUrls([...primaryUrls, ...fallbackUrls]);

    final payload = {
      'ayahs': merged,
      'surahUrls': combined,
      'surahUrl': combined.isNotEmpty ? combined.first : null,
    };
    _normalizeAudioPayload(payload);
    return payload;
  }

  static Future<Map<String, dynamic>?> _getGithubRecitation(int surahNumber, int recitationId) async {
    final edition = _editionForRecitation(recitationId);
    final dash = edition.replaceAll('.', '-');
    final underscore = edition.replaceAll('.', '_');
    final reciterId = recitationId.toString();
    final surahId = surahNumber.toString();
    final surahIdPadded = surahNumber.toString().padLeft(3, '0');
    final cacheKey = '$recitationId-$surahNumber';

    if (_isGithubRecitationCacheValid(cacheKey)) {
      final cached = _githubRecitationCache[cacheKey];
      if (cached != null) {
        return _cloneMap(cached);
      }
    }

    final candidatePaths = <String>{
      'audio/verse-by-verse/$edition/$surahId.json',
      'audio/verse-by-verse/$edition/$surahIdPadded.json',
      'audio/verse_by_verse/$edition/$surahId.json',
      'audio/verse_by_verse/$edition/$surahIdPadded.json',
      'audio/verse-by-verse/$dash/$surahId.json',
      'audio/verse-by-verse/$dash/$surahIdPadded.json',
      'audio/verse_by_verse/$dash/$surahId.json',
      'audio/verse_by_verse/$dash/$surahIdPadded.json',
      'audio/verse-by-verse/$underscore/$surahId.json',
      'audio/verse-by-verse/$underscore/$surahIdPadded.json',
      'audio/verse_by_verse/$underscore/$surahId.json',
      'audio/verse_by_verse/$underscore/$surahIdPadded.json',
      'audio/verses/$edition/$surahId.json',
      'audio/verses/$edition/$surahIdPadded.json',
      'audio/verses/$dash/$surahId.json',
      'audio/verses/$dash/$surahIdPadded.json',
      'audio/verses/$underscore/$surahId.json',
      'audio/verses/$underscore/$surahIdPadded.json',
      'audio/ayah/$edition/$surahId.json',
      'audio/ayah/$edition/$surahIdPadded.json',
      'audio/ayah/$dash/$surahId.json',
      'audio/ayah/$dash/$surahIdPadded.json',
      'audio/ayah/$underscore/$surahId.json',
      'audio/ayah/$underscore/$surahIdPadded.json',
      'audio/surah/$edition/$surahId.json',
      'audio/surah/$edition/$surahIdPadded.json',
      'audio/surah/$dash/$surahId.json',
      'audio/surah/$dash/$surahIdPadded.json',
      'audio/surah/$underscore/$surahId.json',
      'audio/surah/$underscore/$surahIdPadded.json',
      'audio/$edition/$surahId.json',
      'audio/$edition/$surahIdPadded.json',
      'audio/$dash/$surahId.json',
      'audio/$dash/$surahIdPadded.json',
      'audio/$underscore/$surahId.json',
      'audio/$underscore/$surahIdPadded.json',
      'audio/recitations/$reciterId/$surahId.json',
      'audio/recitations/$reciterId/$surahIdPadded.json',
      'recitations/$reciterId/$surahId.json',
      'recitations/$reciterId/$surahIdPadded.json',
      'data/audio/$edition/$surahId.json',
      'data/audio/$edition/$surahIdPadded.json',
      'data/audio/$dash/$surahId.json',
      'data/audio/$dash/$surahIdPadded.json',
      'data/audio/$underscore/$surahId.json',
      'data/audio/$underscore/$surahIdPadded.json',
      'data/recitations/$reciterId/$surahId.json',
      'data/recitations/$reciterId/$surahIdPadded.json',
    };

    final payload = await _fetchGithubJson(candidatePaths);
    if (payload == null) return null;

    Map<String, dynamic>? rawSurah;
    if (payload is Map<String, dynamic>) {
      rawSurah = _extractSurahFromEditionData(payload, surahNumber) ?? payload;
    } else if (payload is List) {
      rawSurah = {'number': surahNumber, 'ayahs': payload};
    }

    if (rawSurah == null || rawSurah.isEmpty) return null;

    final normalized = _normalizeSurah(rawSurah, includeAudio: true);
    final ayahs = (normalized['ayahs'] is List)
        ? List<Map<String, dynamic>>.from(normalized['ayahs'] as List)
        : <Map<String, dynamic>>[];
    if (ayahs.isEmpty) return null;

    final audioUrls = <String>[];
    if (rawSurah.isNotEmpty) {
      audioUrls.addAll(_extractFullSurahAudioUrls(rawSurah));
    }
    final fallbacks = QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: recitationId);
    final mergedUrls = _mergeUniqueUrls([...audioUrls, ...fallbacks]);

    final result = {
      'name': normalized['name'],
      'englishName': normalized['englishName'],
      'number': normalized['number'],
      'ayahs': ayahs,
      'surahUrls': mergedUrls,
      'surahUrl': mergedUrls.isNotEmpty ? mergedUrls.first : null,
    };
    _normalizeAudioPayload(result);
    _cacheGithubRecitation(cacheKey, _cloneMap(result));
    return result;
  }

  static List<String> _extractFullSurahAudioUrls(Map<String, dynamic> audioSurah) {
    final urls = <String>{};

    void collect(dynamic value) {
      if (value is String) {
        final normalized = _normalizeAudioUrl(value);
        if (normalized != null) {
          urls.add(normalized);
        }
      } else if (value is List) {
        for (final item in value) {
          collect(item);
        }
      } else if (value is Map) {
        for (final entry in value.values) {
          collect(entry);
        }
      }
    }

    final directKeys = [
      'audio',
      'audioFile',
      'audio_file',
      'audioFull',
      'audio_full',
      'audioUrl',
      'audio_url',
      'audioSurah',
      'fullAudio',
      'surahAudio',
      'mp3',
      'mp3Url',
      'url',
    ];

    for (final key in directKeys) {
      if (audioSurah.containsKey(key)) collect(audioSurah[key]);
    }

    if (audioSurah['data'] is Map) {
      collect(audioSurah['data']);
    }

    return urls.toList();
  }

  static List<String> _mergeUniqueUrls(List<dynamic> urls) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final url in urls) {
      if (url is! String) continue;
      final normalized = _normalizeAudioUrl(url);
      if (normalized == null) continue;
      if (seen.add(normalized)) ordered.add(normalized);
    }
    return ordered;
  }


  static String _editionForRecitation(int recitationId) =>
      _recitationEditionMap[recitationId] ?? _recitationEditionMap[7]!;

  static dynamic _cloneValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      final copy = <String, dynamic>{};
      value.forEach((key, val) {
        copy[key] = _cloneValue(val);
      });
      return copy;
    }
    if (value is List) {
      return value.map(_cloneValue).toList();
    }
    return value;
  }

  static Map<String, dynamic> _cloneMap(Map<String, dynamic> source) {
    final clone = <String, dynamic>{};
    source.forEach((key, value) {
      clone[key] = _cloneValue(value);
    });
    return clone;
  }

  static Future<Map<String, dynamic>?> _getSurahFromEdition(
    String edition,
    int surahNumber, {
    bool includeAudio = false,
  }) async {
    // Fast path: per-surah from AlQuran Cloud when available (much lighter than full edition)
    try {
      final perSurah = await _getSurahFromCloudPerSurah(edition, surahNumber);
      if (perSurah != null && perSurah.isNotEmpty) return perSurah;
    } catch (_) {}

    // Fallback: full edition dataset
    final dataset = await _getFullEditionData(edition);
    if (dataset == null || dataset.isEmpty) return null;
    final rawSurah = _extractSurahFromEditionData(dataset, surahNumber);
    if (rawSurah == null) return null;
    return _normalizeSurah(rawSurah, includeAudio: includeAudio);
  }

  static Future<Map<String, dynamic>?> _getSurahFromCloudPerSurah(String edition, int surahNumber) async {
    try {
      // Only editions supported by AlQuran Cloud per-surah
      final supported = edition.startsWith('ar.') || edition.startsWith('en.') || edition.startsWith('fr.') || edition.contains('quran');
      if (!supported) return null;
      final url = '$alQuranCloudUrl/surah/$surahNumber/$edition';
      final res = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
        'User-Agent': 'sajda-app-quran-client',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 || res.body.isEmpty) return null;
      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
      if (data is Map<String, dynamic>) {
        // Normalize to expected structure
        return _normalizeSurah(data, includeAudio: edition.startsWith('ar.'));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // New: AlQuran Cloud helpers as requested by user (list, range, multi-editions)
  static Future<List<Map<String, dynamic>>> getSurahsListCloud() async {
    try {
      final url = '$alQuranCloudUrl/surah';
      final res = await http
          .get(Uri.parse(url), headers: {
            'Accept': 'application/json',
            'User-Agent': 'sajda-app-quran-client',
          })
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final body = json.decode(res.body);
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is List) {
          final list = <Map<String, dynamic>>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final norm = _normalizeSurah(item);
              list.add({
                'number': norm['number'],
                'name': norm['name'],
                'englishName': norm['englishName'],
                'englishNameTranslation': norm['englishNameTranslation'],
                'numberOfAyahs': norm['numberOfAyahs'],
                'revelationType': norm['revelationType'],
              });
            }
          }
          list.sort((a, b) => (_parseInt(a['number']) ?? 0).compareTo(_parseInt(b['number']) ?? 0));
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getSurahRangeCloud(int surahNumber, {int? offset, int? limit}) async {
    try {
      final params = <String>[];
      if (offset != null) params.add('offset=$offset');
      if (limit != null) params.add('limit=$limit');
      final qs = params.isEmpty ? '' : '?${params.join('&')}';
      final url = '$alQuranCloudUrl/surah/$surahNumber$qs';
      final res = await http
          .get(Uri.parse(url), headers: {
            'Accept': 'application/json',
            'User-Agent': 'sajda-app-quran-client',
          })
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final body = json.decode(res.body);
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          return _normalizeSurah(data);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _getSurahFromCloudMultiEditions(
    int surahNumber,
    List<String> editions,
  ) async {
    if (editions.isEmpty) return null;
    try {
      final csv = editions.join(',');
      final url = '$alQuranCloudUrl/surah/$surahNumber/editions/$csv';
      final res = await http
          .get(Uri.parse(url), headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip',
            'User-Agent': 'sajda-app-quran-client',
          })
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 || res.body.isEmpty) return null;
      final body = json.decode(res.body);
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is List) {
        Map<String, dynamic>? arabic;
        Map<String, dynamic>? translation;
        Map<String, dynamic>? audio;

        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          final edition = (item['edition'] is Map) ? (item['edition']['identifier']?.toString() ?? '') : (item['edition']?.toString() ?? '');
          final isArabic = edition == 'quran-uthmani' || edition.contains('quran');
          final isAudio = edition.startsWith('ar.');
          final norm = _normalizeSurah(item, includeAudio: isAudio);
          if (isAudio) {
            audio = norm;
          } else if (isArabic) {
            arabic = norm;
          } else {
            translation = norm;
          }
        }

        if (translation != null) _sanitizeTranslationPayload(translation);
        if (audio != null) {
          // Ensure surah-level audio URLs present using our known patterns
          final surahNum = surahNumber;
          final reciterEdition = editions.firstWhere((e) => e.startsWith('ar.'), orElse: () => 'ar.alafasy');
          final recitationId = _recitationEditionMap.entries.firstWhere(
            (e) => e.value == reciterEdition,
            orElse: () => const MapEntry(7, 'ar.alafasy'),
          ).key;
          final merged = _mergeAudioWithArabic(audio, arabic, surahNum, recitationId);
          if (merged != null) audio = merged; else _normalizeAudioPayload(audio);
        }

        return {
          if (arabic != null) 'arabic': arabic,
          if (translation != null) 'translation': translation,
          if (translation != null) 'english': translation,
          if (audio != null) 'audio': audio,
        };
      }
    } catch (_) {}
    return null;
  }


  static List<Map<String, dynamic>> _extractSurahSummaries(Map<String, dynamic> editionData) {
    final summaries = <Map<String, dynamic>>[];
    dynamic data = editionData['data'] ?? editionData;
    List<dynamic>? surahList;

    if (data is Map<String, dynamic>) {
      if (data['surahs'] is List) {
        surahList = data['surahs'] as List;
      } else if (data['chapters'] is List) {
        surahList = data['chapters'] as List;
      } else if (data['data'] is List) {
        surahList = data['data'] as List;
      }
    } else if (data is List) {
      surahList = data;
    }

    if (surahList == null) return summaries;

    for (final item in surahList) {
      if (item is! Map<String, dynamic>) continue;
      final normalized = _normalizeSurah(item);
      summaries.add({
        'number': normalized['number'],
        'name': normalized['name'],
        'englishName': normalized['englishName'],
        'englishNameTranslation': normalized['englishNameTranslation'],
        'numberOfAyahs': normalized['numberOfAyahs'],
        'revelationType': normalized['revelationType'],
      });
    }

    summaries.sort((a, b) => (_parseInt(a['number']) ?? 0).compareTo(_parseInt(b['number']) ?? 0));
    return summaries;
  }

  static Future<List<Map<String, dynamic>>> _getGithubSurahList() async {
    const candidatePaths = [
      'meta/chapters.json',
      'meta/surahs.json',
      'data/chapters.json',
      'data/surahs.json',
      'chapters/chapters.json',
      'chapters/index.json',
      'chapters.json',
      'surahs.json',
    ];

    final payload = await _fetchGithubJson(candidatePaths);
    if (payload == null) return [];

    final results = <int, Map<String, dynamic>>{};

    void addFromList(List<dynamic> list) {
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final normalized = _normalizeSurah(item);
        final number = _parseInt(normalized['number']);
        if (number == null || number <= 0) continue;
        results[number] = {
          'number': number,
          'name': normalized['name'],
          'englishName': normalized['englishName'],
          'englishNameTranslation': normalized['englishNameTranslation'],
          'numberOfAyahs': normalized['numberOfAyahs'],
          'revelationType': normalized['revelationType'],
        };
      }
    }

    void processNode(dynamic node) {
      if (node is List) {
        addFromList(node);
        return;
      }
      if (node is Map<String, dynamic>) {
        final candidates = [
          node['chapters'],
          node['surahs'],
          node['data'],
          node['items'],
          node['result'],
        ];
        for (final candidate in candidates) {
          if (candidate == null) continue;
          if (candidate is List) {
            addFromList(candidate);
          } else if (candidate is Map<String, dynamic>) {
            processNode(candidate);
          }
        }

        if (node.containsKey('number') && node.containsKey('name')) {
          addFromList([node]);
        }
      }
    }

    processNode(payload);

    final ordered = results.values.toList()
      ..sort((a, b) => (_parseInt(a['number']) ?? 0).compareTo(_parseInt(b['number']) ?? 0));
    return ordered;
  }

  // Sajda (prosternations)
  static Future<SajdaResponse> getSajdaVerses({String edition = 'quran-simple'}) async {
    try {
      final url = '$baseUrl/sajda/$edition';
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SajdaResponse.fromJson(jsonData);
      } else {
        // pages.dev unavailable -> fallback
        return await _getSajdaFromAlQuranCloud(edition: edition);
      }
    } catch (_) {
      // Network error -> fallback
      return await _getSajdaFromAlQuranCloud(edition: edition);
    }
  }

  static const List<Map<String, int>> _sajdaAyahs = [
    {'surah': 7, 'ayah': 206},
    {'surah': 13, 'ayah': 15},
    {'surah': 16, 'ayah': 50},
    {'surah': 17, 'ayah': 109},
    {'surah': 19, 'ayah': 58},
    {'surah': 22, 'ayah': 18},
    {'surah': 22, 'ayah': 77},
    {'surah': 25, 'ayah': 60},
    {'surah': 27, 'ayah': 26},
    {'surah': 32, 'ayah': 15},
    {'surah': 38, 'ayah': 24},
    {'surah': 41, 'ayah': 38},
    {'surah': 53, 'ayah': 62},
    {'surah': 84, 'ayah': 21},
    {'surah': 96, 'ayah': 19},
  ];

  static Future<SajdaResponse> _getSajdaFromAlQuranCloud({required String edition}) async {
    // Normalize edition for text fallback when audio or reciter edition requested
    final String textEdition = (edition.startsWith('ar.') || edition.startsWith('en.') || edition.startsWith('fr.')) ? edition : (edition.contains('uthmani') || edition.contains('quran') ? edition : 'quran-uthmani');
    final List<SajdaVerse> verses = [];

    for (final ref in _sajdaAyahs) {
      final surah = ref['surah']!;
      final ayah = ref['ayah']!;
      // Try preferred edition
      Map<String, dynamic>? data;
      try {
        final res = await http.get(Uri.parse('$alQuranCloudUrl/ayah/$surah:$ayah/$textEdition'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          data = body['data'];
        }
      } catch (_) {}

      // If audio edition returned without text, fallback to uthmani for text
      if (data == null || (data['text'] == null || (data['text'] as String).isEmpty)) {
        try {
          final resText = await http.get(Uri.parse('$alQuranCloudUrl/ayah/$surah:$ayah/quran-uthmani'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
          if (resText.statusCode == 200) {
            final body = json.decode(resText.body);
            data = body['data'];
            // Attach edition info
            data!['edition'] = {'identifier': textEdition};
          }
        } catch (_) {}
      }

      if (data != null) {
        // Ensure sajda true for these known references
        data['sajda'] = true;
        verses.add(SajdaVerse.fromJson(data));
      }
    }

    return SajdaResponse(code: 200, status: 'OK', data: verses);
  }

  static Future<SajdaResponse> getSajdaVersesFrench() async => getSajdaVerses(edition: 'fr.hamidullah');
  static Future<SajdaResponse> getSajdaVersesEnglish() async => getSajdaVerses(edition: 'en.sahih');
  static Future<SajdaResponse> getSajdaVersesWithAudio({String reciter = 'alafasy'}) async => getSajdaVerses(edition: 'ar.$reciter');

  static Future<Map<String, String>> getSajdaVersesAudioUrls({int recitationId = 7}) async {
    final audioMap = <String, String>{};
    final uniqueSurahs = <int>{for (final ref in _sajdaAyahs) ref['surah']!};

    final fetchTasks = uniqueSurahs.map((surah) async {
      try {
        final response = await getChapterAudio(surah, recitationId.toString());
        final perAyah = _extractAudioForSurah(response, surah);
        return MapEntry(surah, perAyah);
      } catch (_) {
        return MapEntry(surah, <int, String>{});
      }
    }).toList();

    final resolved = await Future.wait(fetchTasks);
    for (final entry in resolved) {
      for (final ayahEntry in entry.value.entries) {
        final key = '${entry.key}:${ayahEntry.key}';
        if (ayahEntry.value.isNotEmpty) {
          audioMap[key] = ayahEntry.value;
        }
      }
    }

    for (final ref in _sajdaAyahs) {
      final surah = ref['surah']!;
      final ayah = ref['ayah']!;
      final key = '$surah:$ayah';
      if (!audioMap.containsKey(key) || audioMap[key]!.isEmpty) {
        final fallback = _buildPerAyahAudioFallback(surah, ayah, recitationId: recitationId);
        if (fallback != null && fallback.isNotEmpty) {
          audioMap[key] = fallback;
        }
      }
    }

    return audioMap;
  }

  static Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/meta'), headers: {'Accept': 'application/json'});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getEditionInfo(String edition) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/edition/$edition'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String getEditionDisplayName(String edition) => availableEditions[edition] ?? edition;
  static List<String> getAllEditions() => availableEditions.keys.toList();

  static Map<int, String> _extractAudioForSurah(Map<String, dynamic>? response, int surahNumber) {
    final perAyah = <int, String>{};
    if (response == null || response.isEmpty) return perAyah;

    Iterable<dynamic>? _candidateList(dynamic root) {
      if (root is List) return root;
      if (root is Map && root['audio_files'] is List) return root['audio_files'] as List;
      if (root is Map && root['audioFiles'] is List) return root['audioFiles'] as List;
      return null;
    }

    final candidates = <Iterable<dynamic>>[];
    final direct = _candidateList(response);
    if (direct != null) candidates.add(direct);
    if (response['data'] != null) {
      final fromData = _candidateList(response['data']);
      if (fromData != null) candidates.add(fromData);
    }
    if (response['audio'] != null) {
      final fromAudio = _candidateList(response['audio']);
      if (fromAudio != null) candidates.add(fromAudio);
    }

    for (final list in candidates) {
      for (final item in list) {
        if (item is! Map) continue;
        final rawUrl = item['url'] ?? item['audio_url'] ?? item['audio'] ?? item['src'];
        if (rawUrl == null || (rawUrl is String && rawUrl.trim().isEmpty)) continue;

        int? ayahNumber;
        final verseKey = item['verse_key'] ?? item['verseKey'];
        if (verseKey is String && verseKey.contains(':')) {
          final parts = verseKey.split(':');
          final surah = int.tryParse(parts.first);
          final ayah = int.tryParse(parts.last);
          if (surah == surahNumber && ayah != null) ayahNumber = ayah;
        }

        if (ayahNumber == null) {
          final dynamic candidate = item['verse_number'] ?? item['verseNumber'] ?? item['ayah'] ?? item['ayahNumber'];
          if (candidate is num) {
            ayahNumber = candidate.toInt();
          } else if (candidate is String) {
            ayahNumber = int.tryParse(candidate);
          }
        }

        if (ayahNumber != null && ayahNumber > 0) {
          final url = rawUrl is String ? rawUrl : rawUrl.toString();
          if (url.isNotEmpty) perAyah[ayahNumber] ??= url;
        }
      }
    }

    return perAyah;
  }

  static String? _buildPerAyahAudioFallback(int surahNumber, int ayahNumber, {int recitationId = 7}) {
    final templates = QuranAudioService.buildPerAyahUrlTemplates(surahNumber, recitationId: recitationId);
    for (final template in templates) {
      if (!template.contains('%s')) continue;
      final needsPadded = template.contains('_%s');
      final replacement = needsPadded ? ayahNumber.toString().padLeft(3, '0') : ayahNumber.toString();
      final candidate = template.replaceFirst('%s', replacement);
      if (candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  // New API (pages.dev) helpers
  static Future<List<Map<String, dynamic>>> getChaptersFromNewApi() async {
    try {
      final url = '$baseUrl/chapters';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map && jsonData['chapters'] != null) return List<Map<String, dynamic>>.from(jsonData['chapters']);
        if (jsonData is List) return List<Map<String, dynamic>>.from(jsonData);
        return [];
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getChapterWithVerses(int chapterNumber) async {
    try {
      final url = '$baseUrl/chapters/$chapterNumber/verses';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getTranslations() async {
    try {
      final url = '$baseUrl/translations';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map && jsonData['translations'] != null) return List<Map<String, dynamic>>.from(jsonData['translations']);
        if (jsonData is List) return List<Map<String, dynamic>>.from(jsonData);
        return [];
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getChapterWithTranslation(int chapterNumber, String translationId) async {
    try {
      final url = '$baseUrl/chapters/$chapterNumber/translations/$translationId';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getReciters() async {
    try {
      final url = '$baseUrl/reciters';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map && jsonData['reciters'] != null) return List<Map<String, dynamic>>.from(jsonData['reciters']);
        if (jsonData is List) return List<Map<String, dynamic>>.from(jsonData);
        return [];
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getChapterAudio(int chapterNumber, String reciterId) async {
    try {
      final url = '$baseUrl/chapters/$chapterNumber/recitations/$reciterId';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> searchQuran(String query, {String? language}) async {
    try {
      final url = '$baseUrl/search?q=${Uri.encodeComponent(query)}${language != null ? '&lang=$language' : ''}';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getSurahHybrid(int surahNumber) async {
    final newApiResult = await getChapterWithVerses(surahNumber);
    if (newApiResult != null && newApiResult.isNotEmpty) {
      return {'source': 'new_api', 'data': newApiResult};
    }
    try {
      final fallbackResult = await getSurahWithTranslationAndAudio(surahNumber);
      return {'source': 'fallback_api', 'data': fallbackResult};
    } catch (_) {
      return {'source': 'static', 'data': _getFallbackSurahData(surahNumber)};
    }
  }

  // Quran full datasets
  static Future<Map<String, dynamic>> getQuranArabic() async {
    final data = await _getFullEditionData('quran-uthmani');
    if (data != null) return data;
    return await _getQuranArabicFallback();
  }

  static Future<Map<String, dynamic>> _getQuranArabicFallback() async {
    try {
      final url = '$fallbackUrl/quran/quran-uthmani';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Erreur API: ${response.statusCode} - ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération du Coran arabe: $e');
    }
  }

  static Future<Map<String, dynamic>> getQuranEnglishAsad() async {
    final data = await _getFullEditionData('en.asad');
    if (data != null) return data;
    throw Exception("Erreur lors de la récupération de la traduction anglaise: édition 'en.asad' indisponible");
  }

  static Future<Map<String, dynamic>> getQuranAudioAlafasy() async {
    final data = await _getFullEditionData('ar.alafasy');
    if (data != null) return data;
    throw Exception("Erreur lors de la récupération de l'audio Alafasy: édition 'ar.alafasy' indisponible");
  }

  // AlQuranCloud helpers (requested)
  static Future<Map<String, dynamic>> getQuranUthmaniCloud() async {
    final url = '$alQuranCloudUrl/quran/quran-uthmani';
    final res = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
  }

  static Future<Map<String, dynamic>> getQuranFrenchHamidullahCloud() async {
    final url = '$alQuranCloudUrl/quran/fr.hamidullah';
    final res = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
  }

  static Future<Map<String, dynamic>> getQuranAudioAlafasyCloud() async {
    final url = '$alQuranCloudUrl/quran/ar.alafasy';
    final res = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
  }

  static Future<Map<String, dynamic>?> _fetchArabicSurahForReading(int surahNumber) async {
    Map<String, dynamic>? arabic = await _getSurahFromQurani(
      surahNumber,
      edition: 'quran-uthmani',
    );
    if (arabic != null && arabic.isNotEmpty) return arabic;
    return await _getSurahFromEdition('quran-uthmani', surahNumber, includeAudio: false);
  }

  static Future<Map<String, dynamic>?> _fetchTranslationSurahForReading(
    int surahNumber,
    String edition,
  ) async {
    final normalized = edition.trim();
    if (normalized.isEmpty) return null;

    Map<String, dynamic>? translation = await _getSurahFromQurani(
      surahNumber,
      edition: normalized,
    );
    if (translation != null && translation.isNotEmpty) {
      _sanitizeTranslationPayload(translation);
      return translation;
    }

    translation = await _getSurahFromEdition(normalized, surahNumber, includeAudio: false);
    if (translation != null && translation.isNotEmpty) {
      _sanitizeTranslationPayload(translation);
    }
    return translation;
  }

  static Map<int, String> _buildTranslationLookup(Map<String, dynamic>? payload) {
    if (payload == null) return const {};
    final ayahs = payload['ayahs'];
    if (ayahs is! List) return const {};

    final lookup = <int, String>{};
    for (final entry in ayahs) {
      if (entry is! Map<String, dynamic>) continue;
      final index = _parseInt(entry['numberInSurah']) ??
          _parseInt(entry['number_in_surah']) ??
          _parseInt(entry['ayah']) ??
          _parseInt(entry['verse']);
      if (index == null) continue;
      final raw = entry['text'];
      if (raw is String && raw.trim().isNotEmpty) {
        lookup[index] = raw.trim();
      }
    }
    return lookup;
  }

  static Future<Map<String, dynamic>> getSurahForReading(
    int surahNumber, {
    String translationEdition = 'fr.hamidullah',
    bool includeTranslation = true,
  }) async {
    final normalizedEdition = translationEdition.trim().isEmpty ? 'fr.hamidullah' : translationEdition.trim();
    final editionKey = includeTranslation ? normalizedEdition : 'none';
    final cacheKey = 'cache:quran:reading:v1:s=$surahNumber:t=$editionKey';

    final cached = await StorageService.getCachedJson(cacheKey, ttl: _readingCacheTtl);
    if (cached != null && cached.isNotEmpty) {
      return _cloneMap(cached);
    }

    final fallbackData = _getFallbackSurahData(surahNumber);
    Map<String, dynamic>? arabic = await _fetchArabicSurahForReading(surahNumber);
    arabic ??= fallbackData['arabic'] as Map<String, dynamic>?;

    Map<String, dynamic>? translation;
    String translationUsed = '';
    if (includeTranslation) {
      final editions = <String>{normalizedEdition, 'fr.hamidullah'};
      editions.removeWhere((code) => code.trim().isEmpty);

      for (final edition in editions) {
        translation = await _fetchTranslationSurahForReading(surahNumber, edition);
        if (translation != null && translation.isNotEmpty) {
          translationUsed = edition;
          break;
        }
      }

      translation ??= fallbackData['english'] as Map<String, dynamic>?;
      if (translation != null) {
        _sanitizeTranslationPayload(translation);
      }
      if (translation != null && translationUsed.isEmpty) {
        translationUsed = normalizedEdition;
      }
    }

    final arabicAyahsRaw = <Map<String, dynamic>>[];
    if (arabic != null && arabic['ayahs'] is List) {
      for (final ayah in (arabic['ayahs'] as List)) {
        if (ayah is Map) {
          arabicAyahsRaw.add(Map<String, dynamic>.from(ayah));
        }
      }
    }

    final translationLookup = includeTranslation ? _buildTranslationLookup(translation) : const <int, String>{};

    final ayahs = <Map<String, dynamic>>[];
    if (arabicAyahsRaw.isNotEmpty) {
      for (final ayah in arabicAyahsRaw) {
        final number = _parseInt(ayah['numberInSurah']) ??
            _parseInt(ayah['number_in_surah']) ??
            _parseInt(ayah['ayah']) ??
            _parseInt(ayah['verse']);
        final text = ayah['text']?.toString().trim() ?? '';
        if (number == null || text.isEmpty) continue;
        final entry = <String, dynamic>{
          'number': number,
          'arabic': text,
        };
        final translationText = translationLookup[number];
        if (includeTranslation && translationText != null && translationText.isNotEmpty) {
          entry['translation'] = translationText;
        }
        ayahs.add(entry);
      }
    } else if (translationLookup.isNotEmpty) {
      // Fallback: translation only (rare)
      translationLookup.forEach((number, text) {
        ayahs.add({
          'number': number,
          'arabic': '',
          if (includeTranslation) 'translation': text,
        });
      });
      ayahs.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    }

    // Quran.com fallback to ensure full verses when other sources fail
    if (ayahs.isEmpty) {
      try {
        final pack = await QuranComApiClient.getSurahPack(
          surahNumber,
          recitationId: 7,
          translationId: 131, // Hamidullah (FR)
          translationLanguage: 'fr',
        );
        if (pack != null) {
          final arabicList = (pack['arabic'] is Map && pack['arabic']['ayahs'] is List)
              ? List<Map<String, dynamic>>.from(pack['arabic']['ayahs'] as List)
              : <Map<String, dynamic>>[];
          final transList = (pack['translation'] is Map && pack['translation']['ayahs'] is List)
              ? List<Map<String, dynamic>>.from(pack['translation']['ayahs'] as List)
              : <Map<String, dynamic>>[];
          final transLookupQc = <int, String>{};
          for (final t in transList) {
            final idx = _parseInt(t['numberInSurah']) ?? _parseInt(t['number']) ?? 0;
            final tx = t['text']?.toString().trim() ?? '';
            if (idx > 0 && tx.isNotEmpty) transLookupQc[idx] = sanitizeTranslationText(tx);
          }
          for (final a in arabicList) {
            final idx = _parseInt(a['numberInSurah']) ?? _parseInt(a['number']) ?? 0;
            final tx = a['text']?.toString().trim() ?? '';
            if (idx > 0 && tx.isNotEmpty) {
              ayahs.add({
                'number': idx,
                'arabic': tx,
                if (includeTranslation && (transLookupQc[idx]?.isNotEmpty == true)) 'translation': transLookupQc[idx],
              });
            }
          }
          if (ayahs.isNotEmpty) {
            ayahs.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
          }
        }
      } catch (_) {}
    }

    if (ayahs.isEmpty) {
      // Last resort: use fallback minimal data
      final fallbackArabic = fallbackData['arabic'] as Map<String, dynamic>?;
      if (fallbackArabic != null && fallbackArabic['ayahs'] is List) {
        for (final ayah in (fallbackArabic['ayahs'] as List)) {
          if (ayah is! Map) continue;
          final number = _parseInt(ayah['numberInSurah']) ?? _parseInt(ayah['number']);
          final text = ayah['text']?.toString().trim() ?? '';
          if (number == null || text.isEmpty) continue;
          ayahs.add({
            'number': number,
            'arabic': text,
          });
        }
      }
    }

    final fallbackArabicMeta = fallbackData['arabic'] as Map<String, dynamic>?;
    final metaSource = arabic ?? translation ?? fallbackArabicMeta ?? <String, dynamic>{};
    final meta = <String, dynamic>{
      'number': metaSource['number'] ?? surahNumber,
      'name': metaSource['name'] ?? fallbackArabicMeta?['name'] ?? '',
      'englishName': metaSource['englishName'] ?? fallbackArabicMeta?['englishName'] ?? '',
      'englishNameTranslation': metaSource['englishNameTranslation'] ?? fallbackArabicMeta?['englishNameTranslation'] ?? '',
      'revelationType': metaSource['revelationType'] ?? fallbackArabicMeta?['revelationType'] ?? '',
      'numberOfAyahs': metaSource['numberOfAyahs'] ?? fallbackArabicMeta?['numberOfAyahs'] ?? ayahs.length,
      'translationEdition': includeTranslation ? translationUsed : null,
      'translationAvailable': includeTranslation && translation != null,
    };

    final result = <String, dynamic>{
      'meta': meta,
      'ayahs': ayahs,
    };

    final output = _cloneMap(result);
    unawaited(StorageService.setCachedJson(cacheKey, _cloneMap(output)));
    return output;
  }

  // Unified per-surah pack: Arabic, French translation, audio
  static Future<Map<String, dynamic>> getSurahWithTranslationAndAudio(
    int surahNumber, {
    int recitationId = 7,
    int? quranComTranslationId,
    String? tanzilCode,
    String? alquranEditionCode,
    bool prefetch = false,
  }) async {
    // Persistent cache lookup first
    final cacheKey = _buildSurahPackCacheKey(
      surahNumber: surahNumber,
      recitationId: recitationId,
      quranComTranslationId: quranComTranslationId,
      tanzilCode: tanzilCode,
      alquranEditionCode: alquranEditionCode,
    );
    final cached = await StorageService.getCachedJson(cacheKey, ttl: _surahPackCacheTtl);
    if (cached != null && cached.isNotEmpty && !prefetch) {
      // Ensure payload shapes are normalized
      if (cached['translation'] is Map<String, dynamic>) _sanitizeTranslationPayload(cached['translation'] as Map<String, dynamic>);
      if (cached['audio'] is Map<String, dynamic>) _normalizeAudioPayload(cached['audio'] as Map<String, dynamic>);
      return cached;
    }

    final useTanzil = tanzilCode != null && tanzilCode.isNotEmpty;

    // Fast path: when using AlQuran Cloud translation, try multi-editions in a single call
    final reciterEditionFast = _editionForRecitation(recitationId);
    final canUseMulti = !useTanzil && (alquranEditionCode != null && alquranEditionCode.isNotEmpty) && quranComTranslationId == null;
    if (canUseMulti) {
      try {
        final editions = <String>{'quran-uthmani', alquranEditionCode, reciterEditionFast}.toList();
        final multi = await _getSurahFromCloudMultiEditions(surahNumber, editions);
        if (multi != null && multi.isNotEmpty && !prefetch) {
          unawaited(StorageService.setCachedJson(cacheKey, _cloneMap(multi)));
          return multi;
        }
      } catch (_) {}
    }

    // Start all fetches in parallel (fast, per-surah endpoints first)
    final arabicFuture = () async {
      final qurani = await _getSurahFromQurani(
        surahNumber,
        edition: 'quran-uthmani',
      );
      if (qurani != null && qurani.isNotEmpty) return qurani;
      try {
        return await _getSurahFromCloudPerSurah('quran-uthmani', surahNumber);
      } catch (_) {
        return null;
      }
    }();

    Future<Map<String, dynamic>?> translationFuture;
    if (useTanzil) {
      translationFuture = () async {
        try {
          final t = await TanzilApiService.getSurahTranslation(surahNumber, code: tanzilCode);
          _sanitizeTranslationList(t);
          return {'ayahs': t};
        } catch (_) {
          return null;
        }
      }();
    } else if (alquranEditionCode != null && alquranEditionCode.isNotEmpty) {
      translationFuture = () async {
        final edition = alquranEditionCode;
        final qurani = await _getSurahFromQurani(
          surahNumber,
          edition: edition,
        );
        if (qurani != null && qurani.isNotEmpty) {
          _sanitizeTranslationPayload(qurani);
          return qurani;
        }
        try {
          final cloud = await _getSurahFromCloudPerSurah(edition, surahNumber);
          if (cloud != null) _sanitizeTranslationPayload(cloud);
          return cloud;
        } catch (_) {
          return null;
        }
      }();
    } else if (quranComTranslationId != null) {
      translationFuture = () async {
        try {
          final pack = await QuranComApiClient.getSurahPack(
            surahNumber,
            recitationId: 7,
            translationId: quranComTranslationId,
            translationLanguage: 'fr',
          );
          if (pack != null && pack['translation'] is Map<String, dynamic>) {
            final tr = Map<String, dynamic>.from(pack['translation'] as Map);
            _sanitizeTranslationPayload(tr);
            return tr;
          }
        } catch (_) {}
        return null;
      }();
    } else {
      // Default to Hamidullah from Cloud
      translationFuture = () async {
        const edition = 'fr.hamidullah';
        final qurani = await _getSurahFromQurani(
          surahNumber,
          edition: edition,
        );
        if (qurani != null && qurani.isNotEmpty) {
          _sanitizeTranslationPayload(qurani);
          return qurani;
        }
        try {
          final cloud = await _getSurahFromCloudPerSurah(edition, surahNumber);
          if (cloud != null) _sanitizeTranslationPayload(cloud);
          return cloud;
        } catch (_) {
          return null;
        }
      }();
    }

    final audioFuture = () async {
      try {
        final response = await getChapterAudio(surahNumber, recitationId.toString());
        final perAyah = _extractAudioForSurah(response, surahNumber);
        if (perAyah.isEmpty) return null;
        // Build a minimal audio surah payload; arabic will be merged later
        final ayahs = perAyah.entries.map<Map<String, dynamic>>((e) => {
              'numberInSurah': e.key,
              'audio': e.value,
            }).toList();
        final candidates = QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: recitationId);
        final payload = {
          'number': surahNumber,
          'ayahs': ayahs,
          'surahUrls': candidates,
          'surahUrl': candidates.isNotEmpty ? candidates.first : null,
        };
        _normalizeAudioPayload(payload);
        return payload;
      } catch (_) {
        return null;
      }
    }();

    Map<String, dynamic>? arabic;
    Map<String, dynamic>? translation;
    Map<String, dynamic>? audio;

    final results = await Future.wait([
      arabicFuture,
      translationFuture,
      audioFuture,
    ]);
    arabic = results[0] as Map<String, dynamic>?;
    translation = results[1] as Map<String, dynamic>?;
    audio = results[2] as Map<String, dynamic>?;

    // Fallbacks if fast-paths failed
    if (arabic == null) {
      try {
        arabic = await _getSurahFromEdition('quran-uthmani', surahNumber, includeAudio: false);
      } catch (_) {}
    }

    if (translation == null) {
      if (useTanzil) {
        try {
          final t = await TanzilApiService.getSurahTranslation(surahNumber, code: tanzilCode);
          _sanitizeTranslationList(t);
          translation = {'ayahs': t};
        } catch (_) {}
      }
      translation ??= await _getSurahFromEdition(alquranEditionCode ?? 'fr.hamidullah', surahNumber, includeAudio: false).catchError((_) => null);
    }

    if (audio == null) {
      try {
        // Try GitHub recitations
        final gh = await _getGithubRecitation(surahNumber, recitationId);
        if (gh != null) audio = gh;
      } catch (_) {}
      if (audio == null) {
        try {
          final rawAudio = await _getSurahFromEdition(_editionForRecitation(recitationId), surahNumber, includeAudio: true);
          if (rawAudio != null) {
            audio = _mergeAudioWithArabic(rawAudio, arabic, surahNumber, recitationId);
          }
        } catch (_) {}
      }
      if (audio == null) {
        final candidates = QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: recitationId);
        audio = {
          'surahUrl': candidates.isNotEmpty ? candidates.first : null,
          'surahUrls': candidates,
        };
      }
    } else {
      if (arabic != null) {
        final merged = _mergeAudioWithArabic(audio, arabic, surahNumber, recitationId);
        if (merged != null) audio = merged; // ensure text alongside audio where possible
      }
    }

    final output = <String, dynamic>{};
    if (arabic != null) output['arabic'] = arabic;
    if (translation != null) {
      output['translation'] = translation;
      output['english'] = translation;
      _sanitizeTranslationPayload(translation);
    }
    output['audio'] = audio;
    _normalizeAudioPayload(audio);
      if (output['translation'] != null && output['english'] == null) {
      output['english'] = output['translation'];
    }

    // Persist to cache (fire and forget)
    unawaited(StorageService.setCachedJson(cacheKey, _cloneMap(output)));

    return output;
  }

  static String _buildSurahPackCacheKey({
    required int surahNumber,
    required int recitationId,
    int? quranComTranslationId,
    String? tanzilCode,
    String? alquranEditionCode,
  }) {
    final tr = tanzilCode != null && tanzilCode.isNotEmpty
        ? 'tanzil:$tanzilCode'
        : (alquranEditionCode != null && alquranEditionCode.isNotEmpty
            ? 'cloud:$alquranEditionCode'
            : (quranComTranslationId != null ? 'qcom:$quranComTranslationId' : 'cloud:fr.hamidullah'));
    return 'cache:quran:surahPack:v2:s=$surahNumber:r=$recitationId:t=$tr';
  }

  static Future<void> prefetchSurahPack(
    int surahNumber, {
    int recitationId = 7,
    int? quranComTranslationId,
    String? tanzilCode,
    String? alquranEditionCode,
  }) async {
    try {
      await getSurahWithTranslationAndAudio(
        surahNumber,
        recitationId: recitationId,
        quranComTranslationId: quranComTranslationId,
        tanzilCode: tanzilCode,
        alquranEditionCode: alquranEditionCode,
        prefetch: true,
      );
    } catch (_) {}
  }

  static Map<String, dynamic> _getFallbackSurahData(int surahNumber) {
    if (surahNumber == 1) {
      return {
        'arabic': {
          'number': 1,
          'name': 'الفاتحة',
          'englishName': 'Al-Fatiha',
          'englishNameTranslation': 'The Opening',
          'numberOfAyahs': 7,
          'revelationType': 'Meccan',
          'ayahs': [
            {'number': 1, 'text': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', 'numberInSurah': 1},
            {'number': 2, 'text': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', 'numberInSurah': 2},
            {'number': 3, 'text': 'الرَّحْمَٰنِ الرَّحِيمِ', 'numberInSurah': 3},
            {'number': 4, 'text': 'مَالِكِ يَوْمِ الدِّينِ', 'numberInSurah': 4},
            {'number': 5, 'text': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', 'numberInSurah': 5},
            {'number': 6, 'text': 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', 'numberInSurah': 6},
            {'number': 7, 'text': 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ ...', 'numberInSurah': 7},
          ],
        },
        'english': {
          'number': 1,
          'name': 'الفاتحة',
          'englishName': 'Al-Fatiha',
          'englishNameTranslation': 'The Opening',
          'numberOfAyahs': 7,
          'revelationType': 'Meccan',
          'ayahs': [
            {'number': 1, 'text': 'In the name of Allah, the Entirely Merciful, the Especially Merciful.', 'numberInSurah': 1},
            {'number': 2, 'text': '[All] praise is [due] to Allah, Lord of the worlds -', 'numberInSurah': 2},
            {'number': 3, 'text': 'The Entirely Merciful, the Especially Merciful,', 'numberInSurah': 3},
            {'number': 4, 'text': 'Sovereign of the Day of Recompense.', 'numberInSurah': 4},
            {'number': 5, 'text': 'It is You we worship and You we ask for help.', 'numberInSurah': 5},
            {'number': 6, 'text': 'Guide us to the straight path -', 'numberInSurah': 6},
            {'number': 7, 'text': 'The path of those upon whom You have bestowed favor ...', 'numberInSurah': 7},
          ],
        },
      };
    }

    final surahInfo = _getStaticSurahsList().firstWhere(
      (s) => s['number'] == surahNumber,
      orElse: () => {
        'number': surahNumber,
        'name': 'غير متاح',
        'englishName': 'Not Available',
        'englishNameTranslation': 'Not Available',
        'numberOfAyahs': 0,
        'revelationType': 'Unknown',
      },
    );

    return {
      'arabic': {
        ...surahInfo,
        'ayahs': [
          {'number': 1, 'text': 'المحتوى غير متاح حالياً. يرجى المحاولة لاحقاً.', 'numberInSurah': 1},
        ],
      },
      'english': {
        ...surahInfo,
        'ayahs': [
          {'number': 1, 'text': 'Content not available at the moment. Please try again later.', 'numberInSurah': 1},
        ],
      },
    };
  }

  static Future<List<Map<String, dynamic>>> getSurahsList() async {
    // Persistent cache first
    const cacheKey = 'cache:quran:surah_list:v1';
    final cached = await StorageService.getCachedJson(cacheKey, ttl: Duration(days: 7));
    if (cached != null && cached['list'] is List) {
      try {
        final list = List<Map<String, dynamic>>.from(cached['list'] as List);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    // Preferred: AlQuran Cloud /surah (user-requested)
    try {
      final cloud = await getSurahsListCloud();
      if (cloud.isNotEmpty && cloud.length >= 114) {
        await _cacheSurahListSafely(cloud);
        return cloud;
      }
      if (cloud.isNotEmpty) {
        await _cacheSurahListSafely(cloud);
        return cloud; // even partial list is useful
      }
    } catch (_) {}

    try {
      final primaryEdition = await _getFullEditionData('quran-uthmani');
      if (primaryEdition != null && primaryEdition.isNotEmpty) {
        final summaries = _extractSurahSummaries(primaryEdition);
        if (summaries.isNotEmpty && summaries.length >= 114) {
          await _cacheSurahListSafely(summaries);
          return summaries;
        }
      }
    } catch (_) {}

    final quranComSurahs = await QuranComApiClient.getChapters(language: 'fr');
    if (quranComSurahs.isNotEmpty) {
      if (quranComSurahs.length == 114) {
        await _cacheSurahListSafely(quranComSurahs);
        return quranComSurahs;
      }
    }

    final githubSurahs = await _getGithubSurahList();
    if (githubSurahs.isNotEmpty) {
      if (quranComSurahs.isNotEmpty && quranComSurahs.length < 114) {
        final merged = <int, Map<String, dynamic>>{for (final s in quranComSurahs) s['number'] as int: s};
        for (final s in githubSurahs) {
          final number = s['number'];
          if (number is int) {
            merged[number] = merged[number] ?? s;
          }
        }
        final ordered = merged.values.toList()
          ..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
        if (ordered.length >= 114) {
          await _cacheSurahListSafely(ordered);
          return ordered;
        }
        await _cacheSurahListSafely(ordered);
        return ordered;
      }
      if (githubSurahs.length >= 114) {
        await _cacheSurahListSafely(githubSurahs);
        return githubSurahs;
      }
      if (githubSurahs.isNotEmpty) {
        await _cacheSurahListSafely(githubSurahs);
        return githubSurahs;
      }
    }

    final newApiSurahs = await getChaptersFromNewApi();
    if (newApiSurahs.isNotEmpty) {
      if (quranComSurahs.isNotEmpty && quranComSurahs.length < 114) {
        final existing = {for (final s in quranComSurahs) s['number']: s};
        for (final s in newApiSurahs) {
          existing[s['number']] = existing[s['number']] ?? s;
        }
        final merged = existing.values.toList()
          ..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
        await _cacheSurahListSafely(List<Map<String, dynamic>>.from(merged));
        return merged;
      }
      await _cacheSurahListSafely(newApiSurahs);
      return newApiSurahs;
    }

    try {
      final url = '$fallbackUrl/meta';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] != null && jsonData['data']['surahs'] != null) {
          final surahsData = jsonData['data']['surahs'];
          final surahsList = surahsData['references'] ?? surahsData;
          if (surahsList is List) {
            final list = List<Map<String, dynamic>>.from(surahsList);
            list.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
            await _cacheSurahListSafely(list);
            return list;
          }
        }
        final fallback = _getStaticSurahsList();
        await _cacheSurahListSafely(fallback);
        return fallback;
      } else {
        final fallback = _getStaticSurahsList();
        await _cacheSurahListSafely(fallback);
        return fallback;
      }
    } catch (_) {
      final fallback = _getStaticSurahsList();
      await _cacheSurahListSafely(fallback);
      return fallback;
    }
  }

  static Future<void> _cacheSurahListSafely(List<Map<String, dynamic>> list) async {
    try {
      const cacheKey = 'cache:quran:surah_list:v1';
      await StorageService.setCachedJson(cacheKey, {'list': list});
    } catch (_) {}
  }

  static List<Map<String, dynamic>> _getStaticSurahsList() {
    return [
      {'number': 1, 'name': 'الفاتحة', 'englishName': 'Al-Fatiha', 'englishNameTranslation': 'The Opening', 'numberOfAyahs': 7, 'revelationType': 'Meccan'},
      {'number': 2, 'name': 'البقرة', 'englishName': 'Al-Baqarah', 'englishNameTranslation': 'The Cow', 'numberOfAyahs': 286, 'revelationType': 'Medinan'},
      {'number': 3, 'name': 'آل عمران', 'englishName': 'Aal-E-Imran', 'englishNameTranslation': 'The Family of Imran', 'numberOfAyahs': 200, 'revelationType': 'Medinan'},
      {'number': 4, 'name': 'النساء', 'englishName': 'An-Nisa', 'englishNameTranslation': 'The Women', 'numberOfAyahs': 176, 'revelationType': 'Medinan'},
      {'number': 5, 'name': 'المائدة', 'englishName': 'Al-Maidah', 'englishNameTranslation': 'The Table', 'numberOfAyahs': 120, 'revelationType': 'Medinan'},
      {'number': 6, 'name': 'الأنعام', 'englishName': 'Al-Anam', 'englishNameTranslation': 'The Cattle', 'numberOfAyahs': 165, 'revelationType': 'Meccan'},
      {'number': 7, 'name': 'الأعراف', 'englishName': 'Al-Araf', 'englishNameTranslation': 'The Heights', 'numberOfAyahs': 206, 'revelationType': 'Meccan'},
      {'number': 8, 'name': 'الأنفال', 'englishName': 'Al-Anfal', 'englishNameTranslation': 'The Spoils of War', 'numberOfAyahs': 75, 'revelationType': 'Medinan'},
      {'number': 9, 'name': 'التوبة', 'englishName': 'At-Taubah', 'englishNameTranslation': 'The Repentance', 'numberOfAyahs': 129, 'revelationType': 'Medinan'},
      {'number': 10, 'name': 'يونس', 'englishName': 'Yunus', 'englishNameTranslation': 'Jonah', 'numberOfAyahs': 109, 'revelationType': 'Meccan'},
      {'number': 11, 'name': 'هود', 'englishName': 'Hud', 'englishNameTranslation': 'Hud', 'numberOfAyahs': 123, 'revelationType': 'Meccan'},
      {'number': 12, 'name': 'يوسف', 'englishName': 'Yusuf', 'englishNameTranslation': 'Joseph', 'numberOfAyahs': 111, 'revelationType': 'Meccan'},
      {'number': 18, 'name': 'الكهف', 'englishName': 'Al-Kahf', 'englishNameTranslation': 'The Cave', 'numberOfAyahs': 110, 'revelationType': 'Meccan'},
      {'number': 19, 'name': 'مريم', 'englishName': 'Maryam', 'englishNameTranslation': 'Mary', 'numberOfAyahs': 98, 'revelationType': 'Meccan'},
      {'number': 24, 'name': 'النور', 'englishName': 'An-Nur', 'englishNameTranslation': 'The Light', 'numberOfAyahs': 64, 'revelationType': 'Medinan'},
      {'number': 36, 'name': 'يس', 'englishName': 'Ya-Seen', 'englishNameTranslation': 'Ya-Seen', 'numberOfAyahs': 83, 'revelationType': 'Meccan'},
      {'number': 55, 'name': 'الرحمن', 'englishName': 'Ar-Rahman', 'englishNameTranslation': 'The Most Merciful', 'numberOfAyahs': 78, 'revelationType': 'Medinan'},
      {'number': 56, 'name': 'الواقعة', 'englishName': "Al-Waqiah", 'englishNameTranslation': 'The Event', 'numberOfAyahs': 96, 'revelationType': 'Meccan'},
      {'number': 67, 'name': 'الملك', 'englishName': 'Al-Mulk', 'englishNameTranslation': 'The Kingdom', 'numberOfAyahs': 30, 'revelationType': 'Meccan'},
      {'number': 78, 'name': 'النبأ', 'englishName': 'An-Naba', 'englishNameTranslation': 'The Great News', 'numberOfAyahs': 40, 'revelationType': 'Meccan'},
      {'number': 112, 'name': 'الإخلاص', 'englishName': 'Al-Ikhlas', 'englishNameTranslation': 'The Purity', 'numberOfAyahs': 4, 'revelationType': 'Meccan'},
      {'number': 113, 'name': 'الفلق', 'englishName': 'Al-Falaq', 'englishNameTranslation': 'The Daybreak', 'numberOfAyahs': 5, 'revelationType': 'Meccan'},
      {'number': 114, 'name': 'الناس', 'englishName': 'An-Nas', 'englishNameTranslation': 'The Mankind', 'numberOfAyahs': 6, 'revelationType': 'Meccan'},
    ];
  }

  // Utilities
  static List<Map<String, dynamic>> staticSurahsList() => _getStaticSurahsList();

  static Future<List<Map<String, dynamic>>> getFrenchTranslationsCatalog() async {
    final list = <Map<String, dynamic>>[];
    list.add({'code': 'fr.hamidullah', 'name': 'Muhammad Hamidullah (AlQuran API)', 'language': 'Français', 'source': 'alquran_api'});
    final qCom = await QuranComApiClient.getTranslations(language: 'fr');
    for (final t in qCom) {
      list.add({
        'id': t['id'],
        'name': t['name'] ?? t['author_name'] ?? 'Traduction',
        'language': t['language_name'] ?? 'Français',
        'source': 'quran_com',
      });
    }
    list.add({'code': 'fr.hamidullah', 'name': 'Muhammad Hamidullah (Tanzil)', 'language': 'Français', 'source': 'tanzil'});
    return list;
  }

  // New: Multi-language catalog including AlQuran Cloud editions (e.g., en.asad)
  static Future<List<Map<String, dynamic>>> getTranslationsCatalog() async {
    final catalog = <Map<String, dynamic>>[];
    // AlQuran Cloud built-ins
    catalog.addAll([
      {
        'code': 'fr.hamidullah',
        'name': 'Muhammad Hamidullah (FR) — AlQuran Cloud',
        'language': 'Français',
        'source': 'alquran_cloud',
      },
      {
        'code': 'en.asad',
        'name': 'Muhammad Asad (EN) — AlQuran Cloud',
        'language': 'English',
        'source': 'alquran_cloud',
      },
      {
        'code': 'ar.muyassar',
        'name': 'Arabe littéraire (Al‑Muyassar) — AlQuran Cloud',
        'language': 'العربية',
        'source': 'alquran_cloud',
      },
    ]);

    // Quran.com French translations
    try {
      final qCom = await QuranComApiClient.getTranslations(language: 'fr');
      for (final t in qCom) {
        catalog.add({
          'id': t['id'],
          'name': t['name'] ?? t['author_name'] ?? 'Traduction',
          'language': t['language_name'] ?? 'Français',
          'source': 'quran_com',
        });
      }
    } catch (_) {}

    // Tanzil FR fallback option
    catalog.add({'code': 'fr.hamidullah', 'name': 'Muhammad Hamidullah (FR) — Tanzil', 'language': 'Français', 'source': 'tanzil'});

    return catalog;
  }

  static Future<List<Map<String, dynamic>>> getRecitersCatalog() async {
    final list = await QuranComApiClient.getRecitations(language: 'en');
    return list.map<Map<String, dynamic>>((r) => {
      'id': r['id'],
      'name': r['reciter_name'] ?? r['translated_name']?['name'] ?? 'Reciter',
    }).toList();
  }

  static Future<Map<String, dynamic>?> getRandomVerse() async {
    try {
      final url = '$baseUrl/random-verse';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}

    try {
      final surahsList = _getStaticSurahsList();
      final randomSurah = surahsList[DateTime.now().millisecond % surahsList.length];
      final surahNumber = randomSurah['number'];
      final surahData = await getSurahHybrid(surahNumber);
      if (surahData['data'] != null) {
        final verses = surahData['data']['ayahs'] ?? surahData['data']['verses'];
        if (verses != null && verses.isNotEmpty) {
          final randomVerse = verses[DateTime.now().second % verses.length];
          return {'verse': randomVerse, 'surah': randomSurah, 'source': 'fallback_random'};
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getQuranPage(int pageNumber) async {
    try {
      final url = '$baseUrl/pages/$pageNumber';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getJuz(int juzNumber) async {
    try {
      final url = '$baseUrl/juz/$juzNumber';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> testNewApiConnectivity() async {
    try {
      final url = '$baseUrl/chapters';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getChapterStats(int chapterNumber) async {
    try {
      final url = '$baseUrl/chapters/$chapterNumber/info';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }
}
