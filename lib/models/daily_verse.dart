class DailyVerse {
  final int surahNumber;
  final int ayahNumber;
  final String surahArabicName;
  final String surahEnglishName;
  final String surahEnglishTranslation;
  final String revelationType;
  final String arabicText;
  final String? translationText;
  final String translationEdition;
  final List<Map<String, dynamic>> ayahs;
  final Map<String, dynamic>? meta;
  final int ayahIndex;

  const DailyVerse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahArabicName,
    required this.surahEnglishName,
    required this.surahEnglishTranslation,
    required this.revelationType,
    required this.arabicText,
    required this.translationEdition,
    required this.ayahs,
    required this.ayahIndex,
    this.translationText,
    this.meta,
  });

  String get reference => '$surahNumber:$ayahNumber';

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahArabicName': surahArabicName,
      'surahEnglishName': surahEnglishName,
      'surahEnglishTranslation': surahEnglishTranslation,
      'revelationType': revelationType,
      'arabicText': arabicText,
      'translationText': translationText,
      'translationEdition': translationEdition,
      'ayahs': ayahs.map((ayah) => Map<String, dynamic>.from(ayah)).toList(growable: false),
      'meta': meta != null ? Map<String, dynamic>.from(meta!) : null,
      'ayahIndex': ayahIndex,
    };
  }

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    final rawAyahs = (json['ayahs'] as List?) ?? const [];
    return DailyVerse(
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      surahArabicName: json['surahArabicName']?.toString() ?? '',
      surahEnglishName: json['surahEnglishName']?.toString() ?? '',
      surahEnglishTranslation: json['surahEnglishTranslation']?.toString() ?? '',
      revelationType: json['revelationType']?.toString() ?? '',
      arabicText: json['arabicText']?.toString() ?? '',
      translationText: json['translationText']?.toString(),
      translationEdition: json['translationEdition']?.toString() ?? 'fr.hamidullah',
      ayahs: rawAyahs
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(growable: false),
      meta: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : (json['meta'] is Map
              ? Map<String, dynamic>.from((json['meta'] as Map).cast<String, dynamic>())
              : null),
      ayahIndex: json['ayahIndex'] as int? ?? 0,
    );
  }
}