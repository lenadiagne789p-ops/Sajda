import 'package:flutter/material.dart';
import 'package:sajda/models/news_article.dart';
import 'package:sajda/services/news_service.dart';
import 'package:sajda/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';

class MuslimNewsPage extends StatefulWidget {
  const MuslimNewsPage({super.key});

  @override
  State<MuslimNewsPage> createState() => _MuslimNewsPageState();
}

class _MuslimNewsPageState extends State<MuslimNewsPage> {
  late Future<List<NewsArticle>> _future;

  @override
  void initState() {
    super.initState();
    _future = NewsService.fetchMuslimNews();
  }

  Future<void> _refresh() async => setState(() => _future = NewsService.fetchMuslimNews());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.pearlWhite,
      appBar: const GradientAppBar(title: 'Actualités du monde musulman', showBack: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.pearlWhite,
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: RefreshIndicator(
          color: IslamicColors.emeraldGreen,
          onRefresh: _refresh,
          child: FutureBuilder<List<NewsArticle>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _NewsLoadingList();
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    _EmptyState(),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, i) => _NewsCard(article: items[i]),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: items.length,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLink(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: IslamicColors.roseGold.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public, color: IslamicColors.emeraldGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(article.source, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_relativeTime(article.publishedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                article.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.open_in_new, color: IslamicColors.roseGold, size: 18),
                  const SizedBox(width: 6),
                  Text('Lire sur ${article.source}', style: const TextStyle(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ignore: unused_element
class _NewsImage extends StatelessWidget {
  final String url;
  const _NewsImage({required this.url});

  @override
  Widget build(BuildContext context) {
    String _sanitize(String u) {
      final t = u.trim();
      if (t.startsWith('http://')) return t.replaceFirst('http://', 'https://');
      return t;
    }

    final safeUrl = _sanitize(url);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dpr = MediaQuery.of(context).devicePixelRatio;
            final targetWidth = (constraints.maxWidth * dpr).clamp(320, 1920).round();
            return Image.network(
              safeUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              cacheWidth: targetWidth,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))),
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.emeraldGreen))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ignore: unused_element
class _NewsImagePlaceholder extends StatelessWidget {
  const _NewsImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [IslamicColors.emeraldGreen, IslamicColors.mysticBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.newspaper, color: Colors.white.withValues(alpha: 0.85), size: 36),
              const SizedBox(height: 8),
              Text(
                'Image en cours de chargement',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsLoadingList extends StatelessWidget {
  const _NewsLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) => _ShimmerCard(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 6,
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.roseGold.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(height: 140, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _skeleton(height: 18, width: double.infinity),
              const SizedBox(height: 8),
              _skeleton(height: 14, width: double.infinity),
              const SizedBox(height: 8),
              _skeleton(height: 14, width: double.infinity),
            ]),
          )
        ],
      ),
    );
  }

  Widget _skeleton({required double height, required double width}) => Container(height: height, width: width, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.wifi_tethering_off, color: Colors.grey[500], size: 48),
        const SizedBox(height: 12),
        Text('Aucune actualité disponible', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Tirez pour actualiser ou réessayez plus tard.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}
