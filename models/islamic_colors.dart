import 'action_type.dart';

class IslamicAction {
  final String id;
  final ActionType type;
  final String title;
  final int hassanatReward;
  final bool isCompleted;
  final bool isPinned;

  IslamicAction({
    required this.id,
    required this.type,
    required this.title,
    required this.hassanatReward,
    this.isCompleted = false,
    this.isPinned = false,
  });
}
