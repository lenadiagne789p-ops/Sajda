import 'dart:collection';
import 'package:flutter/material.dart';

import 'package:sajda/theme.dart';

/// Very lightweight Tajweed highlighter.
/// Note: This is an approximation that uses common patterns present in Uthmani text.
/// It is not a scholarly-accurate tajweed engine, but provides helpful visual cues.
class TajweedHighlighter {
  const TajweedHighlighter._();

  /// Build RichText spans for Arabic with optional Tajweed coloring and scaling.
  /// When [enableTajweed] is false, returns a single [TextSpan] with baseStyle.
  static InlineSpan build({
    required String text,
    required TextStyle baseStyle,
    bool enableTajweed = false,
  }) {
    if (!enableTajweed) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final runes = text.runes.toList();

    Color colorForIndex(int i) {
      // Access next and previous runes where available
      int? prev = i > 0 ? runes[i - 1] : null;
      int curr = runes[i];
      int? next = i < runes.length - 1 ? runes[i + 1] : null;

      final String sPrev = prev != null ? String.fromCharCode(prev) : '';
      final String s = String.fromCharCode(curr);
      final String sNext = next != null ? String.fromCharCode(next) : '';

      // Common Arabic diacritics (tashkil)
      const fatha = 'َ';
      const kasra = 'ِ';
      const damma = 'ُ';
      const sukun = 'ْ';
      const shadda = 'ّ';
      const tanween = ['ً', 'ٌ', 'ٍ'];

      // Color diacritics explicitly for better readability
      if (s == fatha) return IslamicColors.vowelFatha;
      if (s == kasra) return IslamicColors.vowelKasra;
      if (s == damma) return IslamicColors.vowelDamma;
      if (s == sukun) return IslamicColors.vowelSukun;
      if (s == shadda) return IslamicColors.vowelShadda;
      if (tanween.contains(s)) return IslamicColors.vowelTanween;

      // Rule: Ghunnah on Meem/Nun with shadda
      if ((s == 'ن' || s == 'م') && sNext == shadda) {
        return IslamicColors.tajweedGhunnah;
      }

      // Rule: Qalqalah letters with sukun (ق ط ب ج د)
      const qalqalah = ['ق', 'ط', 'ب', 'ج', 'د'];
      if (qalqalah.contains(s) && sNext == sukun) {
        return IslamicColors.tajweedQalqalah;
      }

      // Rule: Idgham (no ghunnah/with ghunnah simplified): noon sakinah or tanween before يرملون
      const idghamLetters = ['ي', 'ر', 'م', 'ل', 'و', 'ن'];
      if ((sPrev == 'ن' && s == sukun) || tanween.contains(sPrev)) {
        if (idghamLetters.contains(sNext)) {
          return IslamicColors.tajweedIdgham;
        }
      }

      // Rule: Ikhfa: noon sakinah or tanween before certain letters
      const ikhfaLetters = ['ت', 'ث', 'ج', 'د', 'ذ', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ف', 'ق', 'ك'];
      if ((sPrev == 'ن' && s == sukun) || tanween.contains(sPrev)) {
        if (ikhfaLetters.contains(sNext)) {
          return IslamicColors.tajweedIkhfa;
        }
      }

      // Rule: Iqlab: noon sakinah or tanween before ب -> convert to meem sound
      if ((sPrev == 'ن' && s == sukun) || tanween.contains(sPrev)) {
        if (sNext == 'ب') {
          return IslamicColors.tajweedIqlab;
        }
      }

      return baseStyle.color ?? Colors.black;
    }

    // Build spans one char at a time with chosen colors
    for (int i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      final c = colorForIndex(i);
      spans.add(TextSpan(text: ch, style: baseStyle.copyWith(color: c)));
    }

    return TextSpan(children: spans);
  }

  // ----------
  // Simple LRU cache to avoid rebuilding spans repeatedly for the same ayah
  // Keyed by text + font size + tajweed flag
  // ----------
  static final LinkedHashMap<String, InlineSpan> _lru = LinkedHashMap();
  static const int _maxEntries = 1000; // keep memory bounded

  static String _keyFor(String text, TextStyle style, bool enableTajweed) {
    final fs = (style.fontSize ?? 0).toStringAsFixed(2);
    final fw = (style.fontWeight?.toString() ?? 'w');
    return '${enableTajweed ? 'T1' : 'T0'}|fs=$fs|fw=$fw|$text';
  }

  static InlineSpan buildCached({
    required String text,
    required TextStyle baseStyle,
    bool enableTajweed = false,
  }) {
    final key = _keyFor(text, baseStyle, enableTajweed);
    final existing = _lru.remove(key);
    if (existing != null) {
      // Re-insert to mark as most recently used
      _lru[key] = existing;
      return existing;
    }
    final span = build(text: text, baseStyle: baseStyle, enableTajweed: enableTajweed);
    _lru[key] = span;
    if (_lru.length > _maxEntries) {
      // Remove oldest entry
      _lru.remove(_lru.keys.first);
    }
    return span;
  }
}
