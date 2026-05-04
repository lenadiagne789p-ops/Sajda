import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service d'intégration de l'API publique Al-Quran Cloud (api.alquran.cloud/v1)
/// Fournit la liste complète des récitateurs et des traductions disponibles,
/// ainsi que les méthodes pour récupérer les versets avec audio et traduction.
class AlQuranCloudService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _audioCdnBase = 'https://cdn.islamic.network/quran/audio/128';
  static const String _audioCdnBase64 = 'https://cdn.islamic.network/quran/audio/64';

  // ─── Cache en mémoire ───────────────────────────────────────────────────────
  static List<AlQuranReciter>? _cachedReciters;
  static List<AlQuranTranslation>? _cachedTranslations;
  static DateTime? _editionCacheTime;
  static const Duration _cacheTtl = Duration(hours: 12);

  // ─── Catalogue complet des récitateurs connus ────────────────────────────────
  /// Liste statique enrichie : identifiant API + métadonnées pour l'UI
  static const List<Map<String, String>> _knownReciters = [
    {
      'identifier': 'ar.alafasy',
      'name': 'Mishary Rashid Alafasy',
      'nameAr': 'مشاري راشد العفاسي',
      'style': 'Murattal',
      'country': 'Koweït',
    },
    {
      'identifier': 'ar.abdulbasitmurattal',
      'name': 'Abdul Basit Abd us-Samad',
      'nameAr': 'عبد الباسط عبد الصمد',
      'style': 'Murattal',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.abdurrahmaansudais',
      'name': 'Abdurrahmaan As-Sudais',
      'nameAr': 'عبد الرحمن السديس',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.husary',
      'name': 'Mahmoud Khalil Al-Husary',
      'nameAr': 'محمود خليل الحصري',
      'style': 'Murattal',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.husarymujawwad',
      'name': 'Al-Husary (Mujawwad)',
      'nameAr': 'محمود خليل الحصري (مجوّد)',
      'style': 'Mujawwad',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.minshawi',
      'name': 'Muhammad Siddiq Al-Minshawi',
      'nameAr': 'محمد صديق المنشاوي',
      'style': 'Murattal',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.minshawimujawwad',
      'name': 'Al-Minshawi (Mujawwad)',
      'nameAr': 'محمد صديق المنشاوي (مجوّد)',
      'style': 'Mujawwad',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.mahermuaiqly',
      'name': 'Maher Al Muaiqly',
      'nameAr': 'ماهر المعيقلي',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.saoodshuraym',
      'name': 'Saood Ash-Shuraym',
      'nameAr': 'سعود الشريم',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.abdullahbasfar',
      'name': 'Abdullah Basfar',
      'nameAr': 'عبدالله بصفر',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.shaatree',
      'name': 'Abu Bakr Ash-Shaatree',
      'nameAr': 'أبو بكر الشاطري',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.ahmedajamy',
      'name': 'Ahmed ibn Ali al-Ajamy',
      'nameAr': 'أحمد بن علي العجمي',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.hanirifai',
      'name': 'Hani Rifai',
      'nameAr': 'هاني الرفاعي',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.hudhaify',
      'name': 'Ali ibn Abd-ur-Rahman al-Hudhaify',
      'nameAr': 'علي بن عبد الرحمن الحذيفي',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.ibrahimakhbar',
      'name': 'Ibrahim Akhdar',
      'nameAr': 'إبراهيم الأخضر',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.muhammadayyoub',
      'name': 'Muhammad Ayyoub',
      'nameAr': 'محمد أيوب',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.muhammadjibreel',
      'name': 'Muhammad Jibreel',
      'nameAr': 'محمد جبريل',
      'style': 'Murattal',
      'country': 'Égypte',
    },
    {
      'identifier': 'ar.abdulsamad',
      'name': 'Abdul Samad',
      'nameAr': 'عبد الصمد',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'ar.aymanswoaid',
      'name': 'Ayman Sowaid',
      'nameAr': 'أيمن سويد',
      'style': 'Murattal',
      'country': 'Arabie Saoudite',
    },
    {
      'identifier': 'en.walk',
      'name': 'Ibrahim Walk',
      'nameAr': 'إبراهيم ووك',
      'style': 'Murattal',
      'country': 'Allemagne',
    },
    {
      'identifier': 'fr.leclerc',
      'name': 'Youssouf Leclerc',
      'nameAr': 'يوسف لوكليرك',
      'style': 'Murattal',
      'country': 'France',
    },
    {
      'identifier': 'ru.kuliev-audio',
      'name': 'Elmir Kuliev',
      'nameAr': 'إلمير كولييف',
      'style': 'Murattal',
      'country': 'Russie',
    },
  ];

  // ─── Catalogue complet des traductions ──────────────────────────────────────
  static const List<Map<String, String>> _knownTranslations = [
    // Français
    {
      'identifier': 'fr.hamidullah',
      'name': 'Muhammad Hamidullah',
      'language': 'Français',
      'languageCode': 'fr',
    },
    {
      'identifier': 'fr.leclerc',
      'name': 'Youssouf Leclerc',
      'language': 'Français',
      'languageCode': 'fr',
    },
    // Anglais
    {
      'identifier': 'en.sahih',
      'name': 'Saheeh International',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.asad',
      'name': 'Muhammad Asad',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.pickthall',
      'name': 'Mohammed Pickthall',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.hilali',
      'name': 'Al-Hilali & Khan',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.arberry',
      'name': 'A. J. Arberry',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.ahmedali',
      'name': 'Ahmed Ali',
      'language': 'English',
      'languageCode': 'en',
    },
    {
      'identifier': 'en.sarwar',
      'name': 'Muhammad Sarwar',
      'language': 'English',
      'languageCode': 'en',
    },
    // Arabe (texte / tafsir)
    {
      'identifier': 'quran-uthmani',
      'name': 'Texte Uthmani',
      'language': 'العربية',
      'languageCode': 'ar',
    },
    {
      'identifier': 'ar.muyassar',
      'name': 'Al-Muyassar (Tafsir)',
      'language': 'العربية',
      'languageCode': 'ar',
    },
    {
      'identifier': 'ar.jalalayn',
      'name': 'Tafsir Al-Jalalayn',
      'language': 'العربية',
      'languageCode': 'ar',
    },
    // Turc
    {
      'identifier': 'tr.diyanet',
      'name': 'Diyanet İşleri',
      'language': 'Türkçe',
      'languageCode': 'tr',
    },
    {
      'identifier': 'tr.ates',
      'name': 'Suleyman Ates',
      'language': 'Türkçe',
      'languageCode': 'tr',
    },
    // Espagnol
    {
      'identifier': 'es.asad',
      'name': 'Muhammad Asad (ES)',
      'language': 'Español',
      'languageCode': 'es',
    },
    {
      'identifier': 'es.cortes',
      'name': 'Julio Cortes',
      'language': 'Español',
      'languageCode': 'es',
    },
    // Allemand
    {
      'identifier': 'de.bubenheim',
      'name': 'Bubenheim & Elyas',
      'language': 'Deutsch',
      'languageCode': 'de',
    },
    {
      'identifier': 'de.khoury',
      'name': 'Adel Theodor Khoury',
      'language': 'Deutsch',
      'languageCode': 'de',
    },
    // Ourdou
    {
      'identifier': 'ur.jalandhry',
      'name': 'Fateh Muhammad Jalandhry',
      'language': 'اردو',
      'languageCode': 'ur',
    },
    {
      'identifier': 'ur.maududi',
      'name': 'Abul Ala Maududi',
      'language': 'اردو',
      'languageCode': 'ur',
    },
    // Persan
    {
      'identifier': 'fa.fooladvand',
      'name': 'Mohammad Mahdi Fooladvand',
      'language': 'فارسی',
      'languageCode': 'fa',
    },
    // Bengali
    {
      'identifier': 'bn.bengali',
      'name': 'Muhiuddin Khan',
      'language': 'বাংলা',
      'languageCode': 'bn',
    },
    // Indonésien
    {
      'identifier': 'id.indonesian',
      'name': 'Bahasa Indonesia',
      'language': 'Bahasa Indonesia',
      'languageCode': 'id',
    },
    // Russe
    {
      'identifier': 'ru.kuliev',
      'name': 'Elmir Kuliev',
      'language': 'Русский',
      'languageCode': 'ru',
    },
    // Chinois
    {
      'identifier': 'zh.jian',
      'name': 'Ma Jian',
      'language': '中文',
      'languageCode': 'zh',
    },
  ];

  // ─── Méthodes publiques ──────────────────────────────────────────────────────

  /// Retourne la liste de tous les récitateurs disponibles.
  /// Essaie d'abord l'API, sinon retourne la liste statique enrichie.
  static Future<List<AlQuranReciter>> getReciters() async {
    if (_cachedReciters != null &&
        _editionCacheTime != null &&
        DateTime.now().difference(_editionCacheTime!) < _cacheTtl) {
      return _cachedReciters!;
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/edition?format=audio'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final editions = data['data'] as List<dynamic>;
        final reciters = editions.map((e) {
          final identifier = e['identifier'] as String;
          final known = _knownReciters.firstWhere(
            (k) => k['identifier'] == identifier,
            orElse: () => {},
          );
          return AlQuranReciter(
            identifier: identifier,
            name: known['name'] ?? e['englishName'] as String,
            nameAr: known['nameAr'] ?? '',
            style: known['style'] ?? (e['type'] as String? ?? 'Murattal'),
            country: known['country'] ?? '',
          );
        }).toList();
        _cachedReciters = reciters;
        _editionCacheTime = DateTime.now();
        return reciters;
      }
    } catch (_) {}

    // Fallback statique
    return _knownReciters
        .map((r) => AlQuranReciter(
              identifier: r['identifier']!,
              name: r['name']!,
              nameAr: r['nameAr']!,
              style: r['style']!,
              country: r['country']!,
            ))
        .toList();
  }

  /// Retourne la liste de toutes les traductions disponibles.
  static Future<List<AlQuranTranslation>> getTranslations() async {
    if (_cachedTranslations != null &&
        _editionCacheTime != null &&
        DateTime.now().difference(_editionCacheTime!) < _cacheTtl) {
      return _cachedTranslations!;
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/edition?format=text&type=translation'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final editions = data['data'] as List<dynamic>;
        final translations = editions.map((e) {
          final identifier = e['identifier'] as String;
          final known = _knownTranslations.firstWhere(
            (k) => k['identifier'] == identifier,
            orElse: () => {},
          );
          return AlQuranTranslation(
            identifier: identifier,
            name: known['name'] ?? e['englishName'] as String,
            language: known['language'] ?? e['language'] as String? ?? '',
            languageCode: known['languageCode'] ?? e['language'] as String? ?? '',
          );
        }).toList();
        _cachedTranslations = translations;
        return translations;
      }
    } catch (_) {}

    // Fallback statique
    return _knownTranslations
        .map((t) => AlQuranTranslation(
              identifier: t['identifier']!,
              name: t['name']!,
              language: t['language']!,
              languageCode: t['languageCode']!,
            ))
        .toList();
  }

  /// Retourne les traductions filtrées par code de langue.
  static Future<List<AlQuranTranslation>> getTranslationsByLanguage(
      String languageCode) async {
    final all = await getTranslations();
    return all.where((t) => t.languageCode == languageCode).toList();
  }

  /// Retourne les traductions françaises uniquement.
  static Future<List<AlQuranTranslation>> getFrenchTranslations() async {
    return getTranslationsByLanguage('fr');
  }

  /// Construit l'URL audio d'un verset pour un récitateur donné.
  /// Format : https://cdn.islamic.network/quran/audio/128/<identifier>/<surah>:<ayah>.mp3
  static String buildAyahAudioUrl(
    String reciterIdentifier,
    int surah,
    int ayah, {
    int bitrate = 128,
  }) {
    final base = bitrate == 64 ? _audioCdnBase64 : _audioCdnBase;
    return '$base/$reciterIdentifier/$surah:$ayah.mp3';
  }

  /// Construit l'URL audio d'une sourate complète.
  static String buildSurahAudioUrl(
    String reciterIdentifier,
    int surah, {
    int bitrate = 128,
  }) {
    return 'https://cdn.islamic.network/quran/audio-surah/$bitrate/$reciterIdentifier/$surah.mp3';
  }

  /// Récupère les versets d'une sourate avec une traduction donnée.
  static Future<List<AlQuranAyah>?> getSurahWithTranslation(
    int surahNumber,
    String translationIdentifier,
  ) async {
    try {
      final url =
          '$_baseUrl/surah/$surahNumber/$translationIdentifier';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ayahs = data['data']['ayahs'] as List<dynamic>;
        return ayahs
            .map((a) => AlQuranAyah(
                  number: a['number'] as int,
                  numberInSurah: a['numberInSurah'] as int,
                  text: a['text'] as String,
                  surahNumber: surahNumber,
                ))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  /// Récupère un verset avec son texte arabe + traduction en parallèle.
  static Future<Map<String, String>?> getAyahWithTranslation(
    int surahNumber,
    int ayahNumber,
    String translationIdentifier,
  ) async {
    try {
      final arabicFuture = http
          .get(Uri.parse('$_baseUrl/ayah/$surahNumber:$ayahNumber/quran-uthmani'))
          .timeout(const Duration(seconds: 8));
      final translationFuture = http
          .get(Uri.parse(
              '$_baseUrl/ayah/$surahNumber:$ayahNumber/$translationIdentifier'))
          .timeout(const Duration(seconds: 8));

      final results = await Future.wait([arabicFuture, translationFuture]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final arabicData = json.decode(results[0].body);
        final translationData = json.decode(results[1].body);
        return {
          'arabic': arabicData['data']['text'] as String,
          'translation': translationData['data']['text'] as String,
        };
      }
    } catch (_) {}
    return null;
  }

  /// Teste la connectivité à l'API Al-Quran Cloud.
  static Future<bool> testConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ayah/1:1/ar.alafasy'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Vide le cache en mémoire.
  static void clearCache() {
    _cachedReciters = null;
    _cachedTranslations = null;
    _editionCacheTime = null;
  }
}

// ─── Modèles de données ────────────────────────────────────────────────────────

class AlQuranReciter {
  final String identifier;
  final String name;
  final String nameAr;
  final String style;
  final String country;

  const AlQuranReciter({
    required this.identifier,
    required this.name,
    required this.nameAr,
    required this.style,
    required this.country,
  });

  /// Construit l'URL audio d'un verset pour ce récitateur.
  String ayahUrl(int surah, int ayah, {int bitrate = 128}) =>
      AlQuranCloudService.buildAyahAudioUrl(identifier, surah, ayah,
          bitrate: bitrate);

  /// Construit l'URL audio d'une sourate complète pour ce récitateur.
  String surahUrl(int surah, {int bitrate = 128}) =>
      AlQuranCloudService.buildSurahAudioUrl(identifier, surah, bitrate: bitrate);

  @override
  String toString() => name;
}

class AlQuranTranslation {
  final String identifier;
  final String name;
  final String language;
  final String languageCode;

  const AlQuranTranslation({
    required this.identifier,
    required this.name,
    required this.language,
    required this.languageCode,
  });

  @override
  String toString() => '$name ($language)';
}

class AlQuranAyah {
  final int number;
  final int numberInSurah;
  final String text;
  final int surahNumber;

  const AlQuranAyah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.surahNumber,
  });
}
