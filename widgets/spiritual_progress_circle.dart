import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/theme.dart';

class SpiritualProgressCircle extends StatefulWidget {
  final User? user;
  final List<IslamicAction>? dailyActions;

  const SpiritualProgressCircle({super.key, this.user, this.dailyActions});

  @override
  State<SpiritualProgressCircle> createState() => _SpiritualProgressCircleState();
}

class _SpiritualProgressCircleState extends State<SpiritualProgressCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  double _computeCompositeProgress(User user, List<IslamicAction>? actions) {
    // Base: progression de niveau via hassanat courant
    final hassanatProgress = user.levelProgress.clamp(0.0, 1.0);
    // Pondération par la valeur (hassanat) des actions complétées aujourd'hui
    double dailyActionsProgress = 0.0;
    if (actions != null && actions.isNotEmpty) {
      final int totalReward = actions.fold(0, (sum, a) => sum + a.hassanatReward);
      final int earnedToday = actions.where((a) => a.isCompleted).fold(0, (sum, a) => sum + a.hassanatReward);
      if (totalReward > 0) {
        dailyActionsProgress = (earnedToday / totalReward).clamp(0.0, 1.0);
      }
    }
    // Série sur 30 jours max
    final streakNormalized = (user.streak / 30.0).clamp(0.0, 1.0);
    // Nouveau mix: on valorise davantage les actions (pondérées) pour ressentir l'impact
    final composite = (0.5 * hassanatProgress) + (0.4 * dailyActionsProgress) + (0.1 * streakNormalized);
    return composite.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    final endProgress = widget.user != null ? _computeCompositeProgress(widget.user!, widget.dailyActions) : 0.0;
    _progressAnimation = Tween<double>(begin: 0.0, end: endProgress).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SpiritualProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProgress = (oldWidget.user != null) ? _computeCompositeProgress(oldWidget.user!, oldWidget.dailyActions) : 0.0;
    final newProgress = (widget.user != null) ? _computeCompositeProgress(widget.user!, widget.dailyActions) : 0.0;
    if (newProgress != oldProgress) {
      _progressAnimation = Tween<double>(begin: oldProgress, end: newProgress).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    final user = widget.user!;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: SpiritualCirclePainter(progress: _progressAnimation.value, user: user),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('بسم الله', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                        const SizedBox(height: 8),
                        Text('${user.totalHassanat}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.bold)),
                        Text('Hassanat', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.emeraldGreen)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildLevelInfo(user),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(User user) {
    final hassanatProgress = user.levelProgress;
    final actions = widget.dailyActions;
    final completedToday = actions?.where((a) => a.isCompleted).length ?? 0;
    final totalToday = actions?.length ?? 0;
    final totalReward = actions?.fold<int>(0, (sum, a) => sum + a.hassanatReward) ?? 0;
    final earnedToday = actions?.where((a) => a.isCompleted).fold<int>(0, (sum, a) => sum + a.hassanatReward) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(user.spiritualLevel, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (user.levelProgress < 1.0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${user.progressInCurrentLevel}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
                Text('${user.nextLevelTarget - (user.totalHassanat - user.progressInCurrentLevel)} restant', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                Text('${user.nextLevelTarget}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: hassanatProgress, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(IslamicColors.roseGold), borderRadius: BorderRadius.circular(4)),
          ] else ...[
            Text('Niveau maximum atteint! 🌟', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.fact_check, color: IslamicColors.emeraldGreen, size: 18),
                const SizedBox(width: 6),
                Text(
                  totalToday > 0
                      ? '$completedToday/$totalToday actions · +$earnedToday/${totalReward} ḥasanāt'
                      : 'Aucune action aujourd\'hui',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.emeraldGreen),
                )
              ]),
              Row(children: [const Icon(Icons.local_fire_department, color: IslamicColors.roseGold, size: 18), const SizedBox(width: 6), Text('${user.streak} jours', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.roseGold))]),
            ],
          ),
        ],
      ),
    );
  }
}

class SpiritualCirclePainter extends CustomPainter {
  final double progress;
  final User user;

  SpiritualCirclePainter({required this.progress, required this.user});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold, IslamicColors.emeraldGreen], stops: const [0.0, 0.5, 1.0]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, progressPaint);

    if (progress > 0) {
      _drawStars(canvas, center, radius + 15, progress);
    }
  }

  void _drawStars(Canvas canvas, Offset center, double radius, double progress) {
    final starPaint = Paint()..color = IslamicColors.roseGold.withValues(alpha: 0.8)..style = PaintingStyle.fill;

    final numStars = (progress * 8).round();
    for (int i = 0; i < numStars; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final starCenter = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      _drawStar(canvas, starCenter, 6, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const numPoints = 8;
    final path = Path();
    for (int i = 0; i < numPoints * 2; i++) {
      final angle = i * math.pi / numPoints;
      final radius = (i % 2 == 0) ? size : size * 0.5;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
