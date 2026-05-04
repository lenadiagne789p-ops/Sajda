import 'dart:async';

import 'package:sajda/models/daily_verse.dart';
import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/services/tanzil_api_service.dart';

class DailyVerseService {
  static const String _cachePrefix = 'cache:quran:daily_verse:v1';
  static final DateTime _anchorDate = DateTime.utc(2024, 1, 1);

  static Future<DailyVerse?> getVerseForToday({String translationEdition = 'fr.hamidullah'}) async {
    return getVerseForDate(DateTime.now(), translationEdition: translationEdition);
  }

  static Future<DailyVerse?> getVerseForDate(
    DateTime date, {
    String translationEdition = 'fr.hamidullah',
  }) async {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final cacheKey = _buildCacheKey(normalized, translationEdition);

    final cached = await StorageService.getCachedJson(cacheKey, ttl: const Duration(days: 3));
    if (cached != null && cached.isNotEmpty) {
      try {
        return DailyVerse.fromJson(cached);
      } catch (_) {
        // If cached payload is corrupted, ignore and fetch again
      }
    }

    final globalIndex = _computeGlobalIndex(normalized);
    final ref = TanzilApiService.resolveFromGlobalIndex(globalIndex);
    if (ref == null) return null;

    final surahNumber = ref['surah'] ?? 1;
    final ayahNumber = ref['ayah'] ?? 1;

    final surahPayload = await QuranApiService.getSurahForReading(
      surahNumber,
      translationEdition: translationEdition,
      includeTranslation: true,
    );

    final meta = _safeMap(surahPayload['meta']);
    final ayahsRaw = <Map<String, dynamic>>[];
    final rawAyahs = surahPayload['ayahs'];
    if (rawAyahs is List) {
      for (final entry in rawAyahs) {
        final candidate = _safeMap(entry);
        if (candidate.isNotEmpty) {
          ayahsRaw.add(candidate);
        }
      }
    }

    if (ayahsRaw.isEmpty) return null;

    final normalizedAyahs = ayahsRaw.map<Map<String, dynamic>>(_normalizeAyah).toList(growable: false);

    final ayahIndex = normalizedAyahs.indexWhere((e) {
      final number = e['number'] ?? e['numberInSurah'];
      if (number is int) return number == ayahNumber;
      if (number is String) return int.tryParse(number) == ayahNumber;
      return false;
    });

    if (ayahIndex < 0) return null;

    final ayah = normalizedAyahs[ayahIndex];
    final arabic = (ayah['arabic'] ?? ayah['text'] ?? '').toString();
    String? translation = ayah['translation']?.toString();

    if ((translation == null || translation.trim().isEmpty) && translationEdition.isNotEmpty) {
      translation = await TanzilApiService.getAyah(surahNumber, ayahNumber, code: translationEdition);
    }

    final verse = DailyVerse(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahArabicName: meta['name']?.toString() ?? '',
      surahEnglishName: meta['englishName']?.toString() ?? '',
      surahEnglishTranslation: meta['englishNameTranslation']?.toString() ?? '',
      revelationType: meta['revelationType']?.toString() ?? '',
      arabicText: arabic,
      translationText: translation,
      translationEdition: translationEdition,
      ayahs: normalizedAyahs,
      meta: meta.isEmpty ? null : meta,
      ayahIndex: ayahIndex,
    );

    unawaited(StorageService.setCachedJson(cacheKey, verse.toJson()));
    return verse;
  }

  static String _buildCacheKey(DateTime date, String edition) {
    final dateKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_cachePrefix:$edition:$dateKey';
  }

  static int _computeGlobalIndex(DateTime normalizedDate) {
    final total = TanzilApiService.totalAyahs;
    if (total <= 0) return 0;

    final days = normalizedDate.difference(_anchorDate).inDays;
    final positive = days % total;
    final normalized = positive < 0 ? positive + total : positive;
    return normalized;
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        result[key.toString()] = val;
      });
      return result;
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _normalizeAyah(Map<String, dynamic> ayah) {
    final map = Map<String, dynamic>.from(ayah);
    int? number = _parseInt(map['number']);
    int? numberInSurah = _parseInt(map['numberInSurah']);
    if (numberInSurah == null && number != null) numberInSurah = number;
    if (number == null && numberInSurah != null) number = numberInSurah;

    final normalized = <String, dynamic>{
      'number': number ?? numberInSurah ?? 0,
      'numberInSurah': numberInSurah ?? number ?? 0,
      'arabic': map['arabic']?.toString() ?? map['text']?.toString() ?? '',
    };

    if (map['translation'] != null && map['translation'].toString().trim().isNotEmpty) {
      normalized['translation'] = map['translation'].toString().trim();
    }
    if (map['audio'] != null) {
      normalized['audio'] = map['audio'];
    }
    if (map['audioSecondary'] is List) {
      normalized['audioSecondary'] = List<dynamic>.from(map['audioSecondary'] as List);
    }

    return normalized;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}