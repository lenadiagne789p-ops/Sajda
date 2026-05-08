import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sajda/models/npm_salat_media.dart';

class NpmSalatMediaService {
  static const String _pageUrl = 'https://www.nospetitsmusulmans.com/pages/islam/premiere_salet.php';
  static const String _cacheKey = 'npm_salat_media_cache_v1';
  static const Duration _cacheTtl = Duration(hours: 24);

  static Future<NpmSalatMedia> fetch({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        try {
          final parsed = NpmSalatMedia.decode(cached);
          if (DateTime.now().difference(parsed.fetchedAt) < _cacheTtl) {
            return parsed;
          }
        } catch (_) {
          // ignore corrupted cache
        }
      }
    }

    final response = await http.get(Uri.parse(_pageUrl), headers: {
      'User-Agent': 'Mozilla/5.0 (Flutter; Dreamflow)'
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      // If network fails, return cache if exists
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        try {
          return NpmSalatMedia.decode(cached);
        } catch (_) {}
      }
      throw Exception('HTTP ${response.statusCode} while loading NPM page');
    }

    final doc = html_parser.parse(utf8.decode(response.bodyBytes));

    // Collect images
    final baseUri = Uri.parse(_pageUrl);
    final imageUrls = <String>{};
    for (final img in doc.querySelectorAll('img')) {
      final src = img.attributes['src']?.trim();
      if (src == null || src.isEmpty) continue;
      final resolved = _resolveUrl(baseUri, src);
      // Filter likely decorative assets
      if (_isLikelyContentImage(resolved)) imageUrls.add(resolved);
    }

    // Collect audio: <audio><source src>, or <a href="*.mp3">
    final audioItems = <NpmAudioItem>[];
    for (final audio in doc.querySelectorAll('audio')) {
      String? src = audio.attributes['src']?.trim();
      if (src == null || src.isEmpty) {
        final source = audio.querySelector('source');
        src = source?.attributes['src']?.trim();
      }
      if (src != null && src.isNotEmpty) {
        final resolved = _resolveUrl(baseUri, src);
        audioItems.add(NpmAudioItem(url: resolved, title: _guessAudioTitle(audio, resolved)));
      }
    }
    for (final a in doc.querySelectorAll('a')) {
      final href = a.attributes['href']?.trim();
      if (href == null || href.isEmpty) continue;
      final lower = href.toLowerCase();
      if (lower.endsWith('.mp3') || lower.endsWith('.ogg') || lower.contains('audio')) {
        final resolved = _resolveUrl(baseUri, href);
        final title = a.text.trim().isNotEmpty ? a.text.trim() : _fileName(resolved);
        // Avoid duplicates
        if (!audioItems.any((it) => it.url == resolved)) {
          audioItems.add(NpmAudioItem(url: resolved, title: title));
        }
      }
    }

    final data = NpmSalatMedia(
      imageUrls: imageUrls.toList(),
      audios: audioItems,
      fetchedAt: DateTime.now(),
    );

    // Cache
    try {
      await prefs.setString(_cacheKey, NpmSalatMedia.encode(data));
    } catch (_) {}

    return data;
  }

  static String _resolveUrl(Uri base, String maybeRelative) {
    // Handle protocol-relative URLs and relative paths
    if (maybeRelative.startsWith('//')) {
      return '${base.scheme}:$maybeRelative';
    }
    return base.resolve(maybeRelative).toString();
  }

  static bool _isLikelyContentImage(String url) {
    final lower = url.toLowerCase();
    if (!(lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp') || lower.endsWith('.gif'))) {
      return false;
    }
    // likely UI sprites to ignore
    if (lower.contains('logo') || lower.contains('icon') || lower.contains('sprite') || lower.contains('banner') || lower.contains('favicon')) return false;
    return true;
  }

  static String _guessAudioTitle(dom.Element audioEl, String url) {
    // Use aria-label/title if present, otherwise filename
    final label = audioEl.attributes['aria-label']?.trim();
    if (label != null && label.isNotEmpty) return label;
    final title = audioEl.attributes['title']?.trim();
    if (title != null && title.isNotEmpty) return title;
    return _fileName(url);
  }

  static String _fileName(String url) {
    try {
      final uri = Uri.parse(url);
      final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
      return last;
    } catch (_) {
      return url;
    }
  }
}
