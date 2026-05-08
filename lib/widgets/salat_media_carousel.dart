import 'dart:async';

import 'package:flutter/material.dart';

class SalatMediaCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String title;
  final String subtitle;
  final Color accentColor;
  final double height;
  final bool autoPlay;

  const SalatMediaCarousel({super.key, required this.imageUrls, required this.title, required this.subtitle, required this.accentColor, this.height = 220, this.autoPlay = false});

  @override
  State<SalatMediaCarousel> createState() => _SalatMediaCarouselState();
}

class _SalatMediaCarouselState extends State<SalatMediaCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant SalatMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay) {
      if (widget.autoPlay) {
        _startAutoPlay();
      } else {
        _timer?.cancel();
      }
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || widget.imageUrls.isEmpty) return;
      final next = (_currentIndex + 1) % widget.imageUrls.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(title: widget.title, subtitle: widget.subtitle, accentColor: widget.accentColor, autoPlay: widget.autoPlay, onToggleAuto: () {
          setState(() {
            final newAuto = !widget.autoPlay;
            if (newAuto) {
              _startAutoPlay();
            } else {
              _timer?.cancel();
            }
          });
        }),
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => _MediaCard(url: widget.imageUrls[index], accent: widget.accentColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: i == _currentIndex ? widget.accentColor : Colors.grey[300], shape: BoxShape.circle),
              )),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool autoPlay;
  final VoidCallback onToggleAuto;

  const _Header({required this.title, required this.subtitle, required this.accentColor, required this.autoPlay, required this.onToggleAuto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 6, height: 28, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accentColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]), softWrap: true, overflow: TextOverflow.ellipsis),
            ]),
          ),
          TextButton.icon(onPressed: onToggleAuto, icon: Icon(autoPlay ? Icons.pause_circle_filled : Icons.play_circle_fill, color: accentColor), label: Text(autoPlay ? 'Pause' : 'Auto', style: TextStyle(color: accentColor)))
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String url;
  final Color accent;
  const _MediaCard({required this.url, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bool isLocalAsset = url.startsWith('assets/');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isLocalAsset)
            Image.asset(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[200], child: Center(child: Icon(Icons.image_not_supported, color: accent)));
            })
          else
            // Use Image.network with loading/error handling
            LayoutBuilder(builder: (context, constraints) {
              final dpr = MediaQuery.of(context).devicePixelRatio;
              final targetWidth = (constraints.maxWidth * dpr).clamp(320, 1920).round();
              return Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                cacheWidth: targetWidth,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: Colors.grey[100], child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent))));
                },
                errorBuilder: (context, error, stack) {
                  return Container(color: Colors.grey[200], child: Center(child: Icon(Icons.image_not_supported, color: accent)));
                },
              );
            }),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: 0.2))),
              child: Row(children: [Icon(Icons.camera_alt, size: 14, color: accent), const SizedBox(width: 6), Text('Référence visuelle', style: TextStyle(fontSize: 12, color: accent))]),
            ),
          ),
        ],
      ),
    );
  }
}
