import 'package:flutter/material.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/utils/level_system.dart';
import 'package:sajda/theme.dart';

class ProfileLevelCard extends StatefulWidget {
  final User user;
  const ProfileLevelCard({super.key, required this.user});

  @override
  State<ProfileLevelCard> createState() => _ProfileLevelCardState();
}

class _ProfileLevelCardState extends State<ProfileLevelCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = LevelSystem.fromHassanat(widget.user.totalHassanat);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [info.gradient.first.withValues(alpha: 0.18), info.gradient.last.withValues(alpha: 0.10)]),
        border: Border.all(color: info.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Floating diamond (static fallback for web stability)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: info.color.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Icon(Icons.diamond, size: 40, color: info.color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'as salamu alaykum',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.workspace_premium, size: 18, color: info.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${info.title} — ${info.gemstone}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: info.color, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 10,
                    child: Stack(children: [
                      Container(color: Colors.grey.withValues(alpha: 0.2)),
                      FractionallySizedBox(
                        widthFactor: info.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: info.gradient),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Niveau ${info.level}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                    Text('${(info.progress * 100).round()}%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: info.color, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
