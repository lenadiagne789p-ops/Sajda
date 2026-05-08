import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/share_service.dart';
import 'package:sajda/models/user.dart';

class HassanatCounter extends StatefulWidget {
  final int hassanat;
  final bool showAnimation;
  final User? user;

  const HassanatCounter({
    super.key,
    required this.hassanat,
    this.showAnimation = false,
    this.user,
  });

  @override
  State<HassanatCounter> createState() => _HassanatCounterState();
}

class _HassanatCounterState extends State<HassanatCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.showAnimation) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void didUpdateWidget(HassanatCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hassanat > oldWidget.hassanat && widget.showAnimation) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    IslamicColors.roseGold,
                    IslamicColors.roseGold.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: IslamicColors.roseGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatHassanat(widget.hassanat),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'حسنات',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.user != null && widget.hassanat > 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ShareService.shareProgress(context, widget.user!),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatHassanat(int hassanat) {
    if (hassanat >= 1000000) {
      return '${(hassanat / 1000000).toStringAsFixed(1)}M';
    } else if (hassanat >= 1000) {
      return '${(hassanat / 1000).toStringAsFixed(1)}K';
    }
    return hassanat.toString();
  }
}