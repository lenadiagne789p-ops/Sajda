import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/action_detail_page.dart';
import 'package:sajda/screens/dhikr_detail_page.dart';
import 'package:sajda/screens/hadith_detail_page.dart';

class DailyActionsCard extends StatelessWidget {
  final List<IslamicAction> actions;
  final Function(String) onActionCompleted;
  final Function(IslamicAction)? onActionTap;
  final Set<String>? pinnedActionIds;
  final Future<void> Function(String actionId, bool willPin)? onTogglePin;
  final Map<String, int>? actionStreaks;

  const DailyActionsCard({
    super.key,
    required this.actions,
    required this.onActionCompleted,
    this.onActionTap,
    this.pinnedActionIds,
    this.onTogglePin,
    this.actionStreaks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: actions.map((action) {
          final isLast = actions.indexOf(action) == actions.length - 1;
          return _buildActionItem(context, action, !isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IslamicAction action, bool showDivider) {
    final isPinned = (pinnedActionIds ?? const <String>{}).contains(action.id);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (action.type == ActionType.names99 && onActionTap != null) {
                onActionTap!(action);
              } else if (action.type == ActionType.dhikr) {
                // Naviguer vers la page dhikr spécialisée
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DhikrDetailPage(
                      dhikr: action,
                      onActionCompleted: onActionCompleted,
                    ),
                  ),
                );
              } else if (action.type == ActionType.hadith) {
                // Naviguer vers la page hadith spécialisée
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HadithDetailPage(
                      hadithAction: action,
                      onActionCompleted: onActionCompleted,
                    ),
                  ),
                );
              } else {
                // Naviguer vers la page de détails générale
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActionDetailPage(
                      action: action,
                      onActionCompleted: onActionCompleted,
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: action.isCompleted
                          ? IslamicColors.emeraldGreen
                          : IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.isCompleted ? Icons.check_circle : action.icon,
                      color: action.isCompleted
                          ? Colors.white
                          : IslamicColors.emeraldGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: action.isCompleted
                                ? Colors.grey[600]
                                : IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.w600,
                            decoration: action.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.arabicTitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: action.isCompleted
                                ? Colors.grey[500]
                                : IslamicColors.roseGold,
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (onTogglePin != null)
                        IconButton(
                          tooltip: isPinned ? 'Désépingler' : 'Épingler',
                          onPressed: () async {
                            await onTogglePin!.call(action.id, !isPinned);
                          },
                          icon: Icon(
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: isPinned ? IslamicColors.mysticBlue : Colors.grey[400],
                            size: 18,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: action.isCompleted
                              ? Colors.grey[300]
                              : IslamicColors.roseGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              size: 16,
                              color: action.isCompleted
                                  ? Colors.grey[600]
                                  : IslamicColors.roseGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${action.hassanatReward}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: action.isCompleted
                                    ? Colors.grey[600]
                                    : IslamicColors.roseGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (action.isCompleted) 
                        Text(
                          'Terminé',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        )
                      else
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      const SizedBox(height: 4),
                      if (actionStreaks != null && (actionStreaks![action.id] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: IslamicColors.emeraldGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 14, color: IslamicColors.emeraldGreen),
                              const SizedBox(width: 3),
                              Text(
                                '${actionStreaks![action.id]}j',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: IslamicColors.emeraldGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.grey[200],
            height: 1,
            indent: 80,
          ),
      ],
    );
  }
}