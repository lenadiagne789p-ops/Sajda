import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RawDhikr {
  final String id;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final int? repetitions;
  final String? source;
  final String? reference;
  final String? benefit;
  final String? reward;
  final String? audioUrl;

  RawDhikr({
    required this.id,
    required this.arabic,
    this.transliteration,
    this.translation,
    this.repetitions,
    this.source,
    this.reference,
    this.benefit,
    this.reward,
    this.audioUrl,
  });

  factory RawDhikr.fromJson(Map<String, dynamic> j) => RawDhikr(
        id: j['id'] as String,
        arabic: j['arabic'] as String,
        transliteration: j['transliteration'] as String?,
        translation: j['translation'] as String?,
        repetitions: (j['repetitions'] is int) ? j['repetitions'] as int : int.tryParse('${j['repetitions']}'),
        source: j['source'] as String?,
        reference: j['reference'] as String?,
        benefit: j['benefit'] as String?,
        reward: j['reward'] as String?,
        audioUrl: j['audioUrl'] as String?,
      );
}

class RawInvocationCategory {
  final String id;
  final String title;
  final String? subtitle;
  final List<RawDhikr> items;

  RawInvocationCategory({
    required this.id,
    required this.title,
    this.subtitle,
    required this.items,
  });

  factory RawInvocationCategory.fromJson(Map<String, dynamic> j) => RawInvocationCategory(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String?,
        items: (j['items'] as List<dynamic>).map((e) => RawDhikr.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class InvocationsRepository {
  static const String assetPath = 'assets/data/hisn_al_musulman.json';

  static Future<List<RawInvocationCategory>> loadFromAssets() async {
    final raw = await rootBundle.loadString(assetPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    final cats = data['categories'] as List<dynamic>?;
    if (cats == null) return [];
    return cats.map((e) => RawInvocationCategory.fromJson(e as Map<String, dynamic>)).toList();
  }
}
