import 'package:flutter/material.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/utils/level_system.dart';
import 'package:sajda/theme.dart';

class TierCalloutCard extends StatelessWidget {
  final User user;
  final VoidCallback? onViewActions;

  const TierCalloutCard({super.key, required this.user, this.onViewActions});

  @override
  Widget build(BuildContext context) {
    final info = LevelSystem.fromHassanat(user.totalHassanat);
    final remaining = _remainingToNextLevel(user);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [info.gradient.first.withValues(alpha: 0.10), info.gradient.last.withValues(alpha: 0.06)]),
        border: Border.all(color: info.color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [info.gradient.first, info.gradient.last]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
            ),
            child: const Center(child: Icon(Icons.diamond, color: Colors.white, size: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${info.title} — ${info.gemstone}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: info.color, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: IslamicColors.quartz.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: IslamicColors.quartz.withValues(alpha: 0.3)),
                      ),
                      child: Text('L${info.level}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: IslamicColors.onyx)),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  remaining > 0 ? 'Encore $remaining ḥasanāt pour le prochain niveau' : 'Niveau maximum atteint',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.emeraldGreen),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    child: Stack(children: [
                      Container(color: Colors.grey.withValues(alpha: 0.2)),
                      FractionallySizedBox(
                        widthFactor: info.progress,
                        child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: info.gradient))),
                      )
                    ]),
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          )
        ],
      ),
    );
  }

  int _remainingToNextLevel(User user) {
    // user.nextLevelTarget est le palier de points requis. progressInCurrentLevel indique l'xp dans ce palier.
    final currentInto = user.progressInCurrentLevel;
    final target = user.nextLevelTarget;
    final remaining = target - (user.totalHassanat - currentInto);
    return remaining.clamp(0, 1 << 31);
  }
}
