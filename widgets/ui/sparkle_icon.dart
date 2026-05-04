import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A modern, subtle "scintillant" icon with a soft pulsing halo and a
/// shimmering gleam sweep. Designed to be lightweight and reusable.
class SparkleIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color haloColor;
  final Duration shimmerDuration;
  final Duration pulseDuration;

  const SparkleIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = Colors.white,
    this.haloColor = Colors.white,
    this.shimmerDuration = const Duration(milliseconds: 1600),
    this.pulseDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<SparkleIcon> createState() => _SparkleIconState();
}

class _SparkleIconState extends State<SparkleIcon>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final haloBase = math.max(0.0, math.min(1.0, 0.35 + 0.25 * _pulseCtrl.value));

    return SizedBox(
      height: s + 16,
      width: s + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft pulsing halo
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                return Container(
                  height: s + 12 + 3 * _pulseCtrl.value,
                  width: s + 12 + 3 * _pulseCtrl.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Use a radial gradient for a subtle glow without heavy shadows
                    gradient: RadialGradient(
                      colors: [
                        widget.haloColor.withValues(alpha: haloBase),
                        widget.haloColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                       tileMode: TileMode.clamp,
                    ),
                  ),
                );
              },
            ),
          ),

          // Icon with subtle scale pulse (shimmer disabled to avoid CanvasKit gradient issue)
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = 1.0 + 0.03 * _pulseCtrl.value;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Icon(
              widget.icon,
              size: s,
              color: widget.color,
              semanticLabel: 'sparkle-icon',
            ),
          ),
        ],
      ),
    );
  }
}
