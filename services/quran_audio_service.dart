import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sajda/services/alquran_cloud_service.dart';

/// QuranAudioService — Gestion audio du Coran.
/// Utilise l'API Al-Quran Cloud pour obtenir les URLs audio correctes
/// (numéro global de l'ayah, pas numberInSurah).
class QuranAudioService {
  // ─── Récitateurs étendus (identifiants Al-Quran Cloud) ─────────────────────
  static const Map<String, String> reciterNamesExtended = {
    'ar.alafasy': 'Mishary Rashid Alafasy',
    'ar.abdulbasitmurattal': 'Abdul Basit Abd us-Samad (Murattal)',
    'ar.abdulbasitmujawwad': 'Abdul Basit Abd us-Samad (Mujawwad)',
    'ar.abdurrahmaansudais': 'Abdurrahmaan As-Sudais',
    'ar.husary': 'Mahmoud Khalil Al-Husary (Murattal)',
    'ar.husarymujawwad': 'Mahmoud Khalil Al-Husary (Mujawwad)',
    'ar.minshawi': 'Muhammad Siddiq Al-Minshawi (Murattal)',
    'ar.minshawimujawwad': 'Muhammad Siddiq Al-Minshawi (Mujawwad)',
    'ar.mahermuaiqly': 'Maher Al Muaiqly',
    'ar.saoodshuraym': 'Saood Ash-Shuraym',
    'ar.abdullahbasfar': 'Abdullah Basfar',
    'ar.shaatree': 'Abu Bakr Ash-Shaatree',
    'ar.ahmedajamy': 'Ahmed ibn Ali al-Ajamy',
    'ar.hanirifai': 'Hani Rifai',
    'ar.hudhaify': 'Ali Al-Hudhaify',
    'ar.ibrahimakhbar': 'Ibrahim Akhdar',
    'ar.muhammadayyoub': 'Muhammad Ayyoub',
    'ar.muhammadjibreel': 'Muhammad Jibreel',
    'ar.abdulsamad': 'Abdul Samad',
    'ar.aymanswoaid': 'Ayman Sowaid',
    'en.walk': 'Ibrahim Walk (Anglais)',
    'fr.leclerc': 'Youssouf Leclerc (Français)',
    'ru.kuliev-audio': 'Elmir Kuliev (Russe)',
  };

  static const List<String> featuredReciters = [
    'ar.alafasy',
    'ar.abdurrahmaansudais',
    'ar.mahermuaiqly',
    'ar.husary',
    'ar.minshawi',
    'ar.abdulbasitmurattal',
    'ar.shaatree',
    'ar.muhammadayyoub',
  ];

  static const String defaultReciterIdentifier = 'ar.alafasy';

  // Rétrocompatibilité
  static const Map<int, String> reciterNames = {
    7: 'Mishary Rashid Alafasy',
    1: 'Mahmoud Khalil Al-Husary',
    2: 'Muhammad Siddiq Al-Minshawi',
    3: 'Abdul Rahman Al-Sudais',
  };

  static const Map<int, String> _legacyIdToIdentifier = {
    7: 'ar.alafasy',
    1: 'ar.husary',
    2: 'ar.minshawi',
    3: 'ar.abdurrahmaansudais',
  };

  static String identifierFromLegacyId(int id) =>
      _legacyIdToIdentifier[id] ?? defaultReciterIdentifier;

  static Future<List<AlQuranReciter>> fetchAllReciters() =>
      AlQuranCloudService.getReciters();

  static Future<List<AlQuranTranslation>> fetchAllTranslations() =>
      AlQuranCloudService.getTranslations();

  static Future<List<AlQuranTranslation>> fetchFrenchTranslations() =>
      AlQuranCloudService.getFrenchTranslations();

  // ─── Cache des URLs audio par verset ────────────────────────────────────────
  // Clé: "$surahNumber:$ayahInSurah:$reciterIdentifier" → URL audio
  static final Map<String, String> _audioUrlCache = {};

  /// Retourne l'URL audio directe depuis l'API Al-Quran Cloud.
  /// Utilise un cache en mémoire pour éviter les appels répétés.
  static Future<String?> fetchAyahAudioUrl(
    int surahNumber,
    int ayahInSurah, {
    String reciterIdentifier = 'ar.alafasy',
  }) async {
    final cacheKey = '$surahNumber:$ayahInSurah:$reciterIdentifier';
    if (_audioUrlCache.containsKey(cacheKey)) {
      return _audioUrlCache[cacheKey];
    }

    try {
      final url = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahInSurah/$reciterIdentifier',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final ayahData = data['data'] as Map<String, dynamic>?;
        final audioUrl = ayahData?['audio'] as String?;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          _audioUrlCache[cacheKey] = audioUrl;
          return audioUrl;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Pré-charge les URLs audio de toute une sourate en une seule requête.
  static Future<void> prefetchSurahAudio(
    int surahNumber, {
    String reciterIdentifier = 'ar.alafasy',
  }) async {
    try {
      final url = Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/$reciterIdentifier',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final surahData = data['data'] as Map<String, dynamic>?;
        final ayahs = surahData?['ayahs'] as List?;
        if (ayahs != null) {
          for (final ayah in ayahs) {
            if (ayah is Map<String, dynamic>) {
              final numberInSurah = ayah['numberInSurah'] as int?;
              final audioUrl = ayah['audio'] as String?;
              if (numberInSurah != null && audioUrl != null && audioUrl.isNotEmpty) {
                final cacheKey = '$surahNumber:$numberInSurah:$reciterIdentifier';
                _audioUrlCache[cacheKey] = audioUrl;
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Construit une liste d'URLs candidates pour un verset.
  /// Priorité : cache API → CDN Islamic.network (format global) → fallbacks.
  static List<String> buildAyahAudioUrls(
    int chapter,
    int ayah, {
    int recitationId = 7,
    String? reciterIdentifier,
  }) {
    final identifier = reciterIdentifier ??
        _legacyIdToIdentifier[recitationId] ??
        defaultReciterIdentifier;

    final urls = <String>[];
    final seen = <String>{};

    void addUrl(String url) {
      if (url.isEmpty) return;
      if (seen.add(url)) urls.add(url);
    }

    // 1. URL depuis le cache API (numéro global correct)
    final cacheKey = '$chapter:$ayah:$identifier';
    final cached = _audioUrlCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      addUrl(cached);
    }

    // 2. Fallbacks CDN Islamic.network avec le format surah/ayah
    // Note: le numéro global n'est pas connu statiquement, on utilise
    // l'endpoint /audio/surah/{identifier}/{surah}/{ayah} si disponible
    // Format alternatif qui fonctionne sur certains CDNs : chapitre + verset
    addUrl('https://cdn.islamic.network/quran/audio/128/$identifier/$chapter:$ayah.mp3');
    addUrl('https://cdn.islamic.network/quran/audio/64/$identifier/$chapter:$ayah.mp3');

    // 3. Fallback EveryAyah (format 001001.mp3 = chapitre + verset dans sourate)
    final legacyMapping = _legacyReciterMapping[recitationId] ?? _legacyReciterMapping[7]!;
    final everyAyahCode = legacyMapping['everyayah_code']!;
    final quranicAudioFolder = legacyMapping['quranicaudio_folder']!;
    final paddedChapter = _pad3(chapter);
    final paddedAyah = _pad3(ayah);
    final sixDigits = '$paddedChapter$paddedAyah';

    addUrl('https://www.everyayah.com/data/$everyAyahCode/$sixDigits.mp3');
    addUrl('https://download.quranicaudio.com/quran/$quranicAudioFolder/$sixDigits.mp3');

    return urls;
  }

  /// Retourne les URLs pour écouter une sourate complète.
  static List<String> buildFullSurahUrls(int chapter, {
    int recitationId = 7,
    String? reciterIdentifier,
  }) {
    final identifier = reciterIdentifier ??
        _legacyIdToIdentifier[recitationId] ??
        defaultReciterIdentifier;
    final legacyMapping = _legacyReciterMapping[recitationId] ?? _legacyReciterMapping[7]!;
    final quranicaudioFolder = legacyMapping['quranicaudio_folder']!;
    final everyAyahCode = legacyMapping['everyayah_code']!;
    final three = _pad3(chapter);

    return [
      'https://cdn.islamic.network/quran/audio-surah/128/$identifier/$chapter.mp3',
      'https://download.quranicaudio.com/quran/$quranicaudioFolder/$three.mp3',
      'https://www.everyayah.com/data/$everyAyahCode/$three.mp3',
    ];
  }

  // ─── Mapping legacy (rétrocompatibilité) ────────────────────────────────────
  static const Map<int, Map<String, String>> _legacyReciterMapping = {
    7: {
      'quranicaudio_folder': 'mishaari_raashid_al_3afaasee',
      'everyayah_code': 'Alafasy_128kbps',
      'islamic_network': 'ar.alafasy',
    },
    1: {
      'quranicaudio_folder': 'mahmood_khaleel_al-husaree',
      'everyayah_code': 'Husary_128kbps',
      'islamic_network': 'ar.husary',
    },
    2: {
      'quranicaudio_folder': 'mohammad_siddeeq_al-minshawi',
      'everyayah_code': 'Minshawy_Murattal_128kbps',
      'islamic_network': 'ar.minshawi',
    },
    3: {
      'quranicaudio_folder': 'abdulrahman_alsudaes',
      'everyayah_code': 'Abdurrahmaan_As-Sudais_192kbps',
      'islamic_network': 'ar.abdurrahmaansudais',
    },
  };

  /// Rétrocompatibilité : retourne des templates d'URL pour les ayahs.
  static List<String> buildPerAyahUrlTemplates(int chapter, {int recitationId = 7}) {
    final legacyMapping = _legacyReciterMapping[recitationId] ?? _legacyReciterMapping[7]!;
    final islamicNetworkCode = legacyMapping['islamic_network']!;
    return [
      'https://cdn.islamic.network/quran/audio/128/$islamicNetworkCode/$chapter:%s.mp3',
      'https://cdn.islamic.network/quran/audio/64/$islamicNetworkCode/$chapter:%s.mp3',
    ];
  }

  static String _pad3(int n) => n.toString().padLeft(3, '0');

  static String pickUrl(List<String> candidates) {
    if (candidates.isEmpty) return '';
    final len = candidates.length;
    final i = DateTime.now().millisecond % len;
    return candidates[i];
  }
}
