import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';

class PremiumBadge extends StatefulWidget {
  final bool isPremium;
  final bool showText;
  final double size;
  final bool floating;

  const PremiumBadge({
    super.key,
    this.isPremium = false,
    this.showText = true,
    this.size = 24,
    this.floating = true,
  });

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPremium) return const SizedBox.shrink();

    final theme = Theme.of(context);

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.showText ? 10 : 6,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            IslamicColors.roseGold,
            Color(0xFFE6C76A), // lighter rose tint for contrast
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: IslamicColors.roseGold.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF1B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
            blendMode: BlendMode.srcATop,
            child: Icon(
              Icons.diamond,
              size: widget.size,
              color: Colors.white,
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(width: 6),
            Text(
              'PREMIUM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: widget.size * 0.5,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );

    if (!widget.floating) return badge;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = (widget.size * 0.10) * (2 * _controller.value - 1);
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: badge,
    );
  }
}