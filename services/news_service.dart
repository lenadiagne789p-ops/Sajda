import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sajda/models/news_article.dart';

class NewsService {
  static const String _oummaRss = 'https://oumma.com/feed/';
  static const String _oummaJson = 'https://oumma.com/wp-json/wp/v2/posts?_embed&per_page=20';
  static const String _orientRss = 'https://orientxxi.info/spip.php?page=backend';
  // Common RSS endpoints used by Saphirnews
  static const List<String> _saphirCandidates = [
    'https://www.saphirnews.com/xml/syndication.rss',
    'https://www.saphirnews.com/xml/syndication.rss?t=actu',
    'https://www.saphirnews.com/rss.xml',
    'https://www.saphirnews.com/feeds/rss',
  ];

  static const Duration _htmlFetchTimeout = Duration(seconds: 8);
  static const int _maxImageFetchAttempts = 8;

  static Future<List<NewsArticle>> fetchMuslimNews() async {
    try {
      final results = await Future.wait<List<NewsArticle>>([
        fetchOummaFeed(),
        fetchOrientFeed(),
        fetchSaphirnewsFeed(),
      ]);
      final merged = _dedupAndSort(results.expand((e) => e).toList());
      return await _enrichImages(merged);
    } catch (_) {
      try {
        final only = await fetchOummaFeed();
        return await _enrichImages(only);
      } catch (_) {
        return [];
      }
    }
  }

  static Future<List<NewsArticle>> fetchOrientFeed() async {
    try {
      final uri = Uri.parse(_orientRss);
      final res = await http.get(uri, headers: {
        'Accept': 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
      });
      if (res.statusCode != 200) return [];
      final items = _parseRss(res.body, source: 'Orient XXI', siteBase: 'https://orientxxi.info');
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<List<NewsArticle>> fetchOummaFeed() async {
    try {
      final uri = Uri.parse(_oummaRss);
      final res = await http.get(uri, headers: {
        'Accept': 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
      });
      if (res.statusCode == 200) {
        final items = _parseRss(res.body, source: 'Oumma', siteBase: 'https://oumma.com');
        if (items.isNotEmpty) return items;
      }
      final alt = await _fetchOummaJson();
      return alt;
    } catch (_) {
      try {
        return await _fetchOummaJson();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<List<NewsArticle>> fetchSaphirnewsFeed() async {
    for (final url in _saphirCandidates) {
      try {
        final uri = Uri.parse(url);
        final res = await http.get(uri, headers: {
          'Accept': 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
        });
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final items = _parseRss(res.body, source: 'Saphirnews', siteBase: 'https://www.saphirnews.com');
          if (items.isNotEmpty) return items;
        }
      } catch (_) {
        // try next candidate
      }
    }
    return [];
  }

  static Future<List<NewsArticle>> _fetchOummaJson() async {
    final uri = Uri.parse(_oummaJson);
    final res = await http.get(uri, headers: {
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
    });
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];

    final List<NewsArticle> items = [];
    for (final raw in data) {
      try {
        final String title = _decodeHtml((raw['title']?['rendered'] ?? '').toString());
        final String link = (raw['link'] ?? '').toString();
        final String excerptHtml = (raw['excerpt']?['rendered'] ?? '').toString();
        final String contentHtml = (raw['content']?['rendered'] ?? '').toString();
        final String desc = _decodeHtml(_stripHtml(excerptHtml).trim().isNotEmpty ? _stripHtml(excerptHtml) : _stripHtml(contentHtml));
        final String? image = _normalizeUrl(
          _extractEmbeddedImage(raw) ?? _extractFirstImageSrc(contentHtml) ?? _extractFirstImageSrc(excerptHtml),
          'https://oumma.com',
        );
        final DateTime? publishedAt = _parseWpDate((raw['date'] ?? '').toString());
        if (title.isEmpty || link.isEmpty) continue;
        items.add(NewsArticle(title: title, link: link, publishedAt: publishedAt, description: desc, imageUrl: image, source: 'Oumma'));
      } catch (_) {}
    }
    return items;
  }

  static DateTime? _parseWpDate(String v) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  static String? _extractEmbeddedImage(dynamic raw) {
    try {
      final embedded = raw['_embedded'];
      if (embedded is Map && embedded['wp:featuredmedia'] is List && embedded['wp:featuredmedia'].isNotEmpty) {
        final fm = embedded['wp:featuredmedia'][0];
        final url = (fm['source_url'] ??
                fm['media_details']?['sizes']?['large']?['source_url'] ??
                fm['media_details']?['sizes']?['medium_large']?['source_url'] ??
                fm['media_details']?['sizes']?['medium']?['source_url'])
            ?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
      final yoast = raw['yoast_head_json'];
      if (yoast is Map && yoast['og_image'] is List && yoast['og_image'].isNotEmpty) {
        final oi = yoast['og_image'][0];
        final url = (oi['url'] ?? '').toString();
        if (url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  static List<NewsArticle> _parseRss(String xml, {required String source, String? siteBase}) {
    final items = <NewsArticle>[];
    final itemRegex = RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false);
    final matches = itemRegex.allMatches(xml);
    for (final m in matches) {
      final raw = m.group(1) ?? '';
      final title = _extractTag(raw, 'title');
      final link = _extractTag(raw, 'link');
      final pubDateStr = _extractTag(raw, 'pubDate');
      final descriptionRaw = _extractTag(raw, 'description');
      final contentEncoded = _extractTag(raw, 'content:encoded');
      final imageFromMedia = _extractAttr(raw, 'media:content', 'url') ??
          _extractAttr(raw, 'media:thumbnail', 'url') ??
          _extractAttr(raw, 'enclosure', 'url');
      final imageFromDesc = _extractFirstImageSrc(descriptionRaw) ?? _extractFirstImageSrc(contentEncoded);

      final description = _stripHtml(descriptionRaw).trim();
      DateTime? publishedAt;
      try {
        if (pubDateStr.isNotEmpty) {
          publishedAt = DateTime.tryParse(pubDateStr) ?? _tryRfc822(pubDateStr);
        }
      } catch (_) {}

      if (title.isEmpty || link.isEmpty) continue;
      items.add(NewsArticle(
        title: _decodeHtml(title),
        link: link.trim(),
        publishedAt: publishedAt,
        description: _decodeHtml(description),
        imageUrl: _normalizeUrl((imageFromMedia ?? imageFromDesc)?.trim(), siteBase),
        source: source,
      ));
    }
    return items;
  }

  static String _extractTag(String source, String tag) {
    final regex = RegExp('<$tag>([\\s\\S]*?)</$tag>', caseSensitive: false);
    final m = regex.firstMatch(source);
    if (m == null) return '';
    final content = m.group(1) ?? '';
    return content
        .replaceAll(RegExp(r'^<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>$'), '')
        .trim();
  }

  static String? _extractAttr(String source, String tag, String attr) {
    final regex = RegExp("<$tag[^>]*$attr\\s*=\\s*(['\"])([^'\"]+?)\\1[^>]*>", caseSensitive: false);
    final match = regex.firstMatch(source);
    return match == null ? null : match.group(2)?.trim();
  }

  static String? _extractFirstImageSrc(String html) {
    if (html.isEmpty) return null;
    final imgRegex = RegExp('<img[^>]*src=["\']([^"\']+)["\']', caseSensitive: false);
    final m1 = imgRegex.firstMatch(html);
    if (m1 != null) return m1.group(1);
    final dataRegex = RegExp('<img[^>]*data-src=["\']([^"\']+)["\']', caseSensitive: false);
    final m2 = dataRegex.firstMatch(html);
    if (m2 != null) return m2.group(1);
    final srcsetRegex = RegExp('<img[^>]*srcset=["\']([^"\']+)["\']', caseSensitive: false);
    final m3 = srcsetRegex.firstMatch(html);
    if (m3 != null) return _firstFromSrcset(m3.group(1) ?? '');
    return null;
  }

  static String _firstFromSrcset(String srcset) {
    final parts = srcset.split(',');
    if (parts.isEmpty) return srcset.trim();
    final first = parts.first.trim();
    final url = first.split(' ').first.trim();
    return url;
  }

  static String _stripHtml(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _decodeHtml(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'')
        .replaceAll('&#8217;', '’')
        .replaceAll('&#8220;', '“')
        .replaceAll('&#8221;', '”')
        .replaceAll('&#8230;', '…');
  }

  static DateTime? _tryRfc822(String value) {
    try {
      return DateTime.parse(_toIsoIfPossible(value));
    } catch (_) {
      return null;
    }
  }

  static String _toIsoIfPossible(String rfc) {
    final parts = rfc.split(',');
    final rest = parts.length > 1 ? parts[1].trim() : rfc.trim();
    final normalized = rest.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  static String? _extractOgImage(String html) {
    final ogRegex = RegExp('<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']', caseSensitive: false);
    final m = ogRegex.firstMatch(html);
    return m?.group(1);
  }

  static String? _normalizeUrl(String? url, String? base) {
    if (url == null || url.isEmpty) return null;
    var u = url.trim();
    if (u.startsWith('data:')) return null;
    if (u.startsWith('//')) {
      u = 'https:$u';
    } else if (base != null && u.startsWith('/')) {
      u = base + u;
    }
    if (u.startsWith('http://')) {
      u = u.replaceFirst('http://', 'https://');
    }
    return u;
  }

  static Future<List<NewsArticle>> _enrichImages(List<NewsArticle> items) async {
    final List<NewsArticle> out = [];
    int fetched = 0;
    for (final it in items) {
      final normalized = _normalizeUrl(it.imageUrl, null);
      if (normalized != null && normalized.isNotEmpty) {
        out.add(_copyWithImage(it, normalized));
        continue;
      }
      if (fetched >= _maxImageFetchAttempts) {
        out.add(it);
        continue;
      }
      try {
        final resolved = await _resolveArticleImage(it.link);
        out.add(_copyWithImage(it, resolved ?? it.imageUrl));
      } catch (_) {
        out.add(it);
      }
      fetched++;
    }
    return out;
  }

  static NewsArticle _copyWithImage(NewsArticle it, String? imageUrl) {
    return NewsArticle(
      title: it.title,
      link: it.link,
      publishedAt: it.publishedAt,
      description: it.description,
      imageUrl: imageUrl,
      source: it.source,
    );
  }

  static Future<String?> _resolveArticleImage(String link) async {
    final html = await _fetchArticleHtml(link);
    if (html == null || html.isEmpty) return null;
    final ogImage = _normalizeUrl(_extractOgImage(html), null);
    if (ogImage != null && ogImage.isNotEmpty) return ogImage;
    final fallback = _normalizeUrl(_extractFirstImageSrc(html), null);
    return fallback;
  }

  static Future<String?> _fetchArticleHtml(String link) async {
    try {
      final uri = Uri.parse(link);
      final res = await http.get(uri, headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
      }).timeout(_htmlFetchTimeout);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return res.body;
      }
      return await _fetchArticleHtmlViaProxy(uri);
    } catch (_) {
      try {
        return await _fetchArticleHtmlViaProxy(Uri.parse(link));
      } catch (_) {
        return null;
      }
    }
  }

  static Future<String?> _fetchArticleHtmlViaProxy(Uri original) async {
    final proxy = _buildProxyUri(original);
    if (proxy == null) return null;
    final res = await http.get(proxy, headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36'
    }).timeout(_htmlFetchTimeout);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return res.body;
    }
    return null;
  }

  static Uri? _buildProxyUri(Uri original) {
    if (!original.hasAuthority || original.host.isEmpty) return null;
    final scheme = original.scheme.isEmpty ? 'https' : original.scheme;
    final buffer = StringBuffer()..write('/$scheme://${original.authority}');
    if (original.path.isNotEmpty) {
      buffer.write(original.path.startsWith('/') ? original.path : '/${original.path}');
    }
    return Uri(
      scheme: 'https',
      host: 'r.jina.ai',
      path: buffer.toString(),
      query: original.hasQuery ? original.query : null,
      fragment: original.fragment,
    );
  }

  static List<NewsArticle> _dedupAndSort(List<NewsArticle> items) {
    final Map<String, NewsArticle> byLink = {};
    for (final it in items) {
      final key = it.link.trim();
      byLink.putIfAbsent(key, () => it);
    }
    final list = byLink.values.toList();
    list.sort((a, b) {
      final ad = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return list;
  }
}