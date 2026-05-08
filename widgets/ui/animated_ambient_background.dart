import 'dart:async';
import 'package:flutter/material.dart';

/// Animated ambient background with subtle Ken Burns effect and soft crossfades.
///
/// - Cycles through calming landscape photos.
/// - Very light on rebuilds: only swaps image every [switchInterval].
/// - Includes top/bottom scrims for legibility of foreground content.
class AnimatedAmbientBackground extends StatefulWidget {
  final Duration switchInterval;
  final Duration fadeDuration;
  final double maxScale; // e.g., 1.12 for a gentle zoom
  final double maxPan; // e.g., 0.03 for subtle pan on both axis
  final double dim; // 0 to 1, additional dim overlay

  const AnimatedAmbientBackground({
    super.key,
    this.switchInterval = const Duration(seconds: 22),
    this.fadeDuration = const Duration(milliseconds: 1200),
    this.maxScale = 1.12,
    this.maxPan = 0.03,
    this.dim = 0.08,
  });

  @override
  State<AnimatedAmbientBackground> createState() => _AnimatedAmbientBackgroundState();
}

class _AnimatedAmbientBackgroundState extends State<AnimatedAmbientBackground> {
  // Very light, near-white landscapes (registered under assets/images/)
  static const _images = <String>[
    'assets/images/Snowy_white_mountain_peak_minimal_sky_white_1761821240328.jpg',
    'assets/images/White_sand_dunes_minimal_desert_white_1761821241104.jpg',
    'assets/images/Foggy_seashore_bright_white_mist_white_1761821241977.jpg',
    'assets/images/Icy_tundra_flat_white_landscape_white_1761821242772.jpg',
    'assets/images/Overcast_white_clouds_soft_sky_white_1761821243432.jpg',
    'assets/images/Misty_white_forest_minimal_trees_white_1761821244228.jpg',
    'assets/images/Snow_field_plain_white_horizon_white_1761821244977.jpg',
    'assets/images/Minimal_glacier_abstract_white_blue_white_1761821245646.jpg',
  ];

  late Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.switchInterval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _images.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache for smooth transitions
    for (final path in _images) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Ensure a minimum dim level for readability depending on theme brightness.
    // In light mode we keep images bright (requested: very light/white), so dim less.
    final bool isDark = theme.brightness == Brightness.dark;
    final double minDim = isDark ? 0.28 : 0.10; // lighter in light mode
    final double effectiveDim = widget.dim < minDim ? minDim : widget.dim;

    final Color scrimBase = cs.shadow; // centralized in theme for both modes

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: widget.fadeDuration,
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _KenBurns(
                key: ValueKey(_index),
                imagePath: _images[_index],
                maxScale: widget.maxScale,
                maxPan: widget.maxPan,
                interval: widget.switchInterval,
              ),
            ),

            // Global dim for readability (theme-aware)
            Container(color: scrimBase.withValues(alpha: effectiveDim)),

            // Top scrim (supports AppBar icons/labels). Slightly softer in light mode.
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scrimBase.withValues(alpha: isDark ? 0.26 : 0.20),
                      scrimBase.withValues(alpha: 0.0),
                    ],
                    tileMode: TileMode.clamp,
                  ),
                ),
              ),
            ),

            // Bottom scrim (for nav bars and bottom sheets). Softer in light mode.
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      scrimBase.withValues(alpha: isDark ? 0.36 : 0.28),
                      scrimBase.withValues(alpha: 0.0),
                    ],
                    tileMode: TileMode.clamp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KenBurns extends StatelessWidget {
  final String imagePath;
  final double maxScale;
  final double maxPan;
  final Duration interval;

  const _KenBurns({
    super.key,
    required this.imagePath,
    required this.maxScale,
    required this.maxPan,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    // Pan alternates direction each build via key uniqueness from parent
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: interval,
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final scale = 1 + (maxScale - 1) * t;
        // Move from top-left to bottom-right subtly
        final dx = (maxPan) * t;
        final dy = (maxPan) * t;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(dx * MediaQuery.of(context).size.width, dy * MediaQuery.of(context).size.height)
            ..scale(scale, scale),
          child: child,
        );
      },
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
      ),
    );
  }
}
