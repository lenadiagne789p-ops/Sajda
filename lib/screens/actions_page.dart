import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/widgets/daily_actions_card.dart';
import 'package:sajda/screens/allah_names_page.dart';
import 'package:sajda/screens/quran_page.dart';
import 'package:sajda/screens/invocations_page.dart';
import 'package:sajda/theme.dart';

class ActionsPage extends StatefulWidget {
  final VoidCallback? onActionCompleted;

  const ActionsPage({super.key, this.onActionCompleted});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  List<IslamicAction> _actions = [];
  bool _isLoading = true;
  Map<ActionType, List<IslamicAction>> _groupedActions = {};
  Set<String> _pinnedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    try {
      final results = await Future.wait([
        StorageService.getAllActionsForToday(),
        StorageService.getPinnedActionIds(),
      ]);
      final actions = results[0] as List<IslamicAction>;
      final pinned = results[1] as Set<String>;
      
      if (mounted) {
        setState(() {
          _actions = actions;
          _groupedActions = _groupActionsByType(actions);
          _pinnedIds = pinned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<ActionType, List<IslamicAction>> _groupActionsByType(List<IslamicAction> actions) {
    final Map<ActionType, List<IslamicAction>> grouped = {};
    
    for (final action in actions) {
      if (!grouped.containsKey(action.type)) {
        grouped[action.type] = [];
      }
      grouped[action.type]!.add(action);
    }
    
    return grouped;
  }

  String _getTypeTitle(ActionType type) {
    switch (type) {
      case ActionType.prayer:
        return 'Prières (الصلوات)';
      case ActionType.dhikr:
        return 'Dhikr (الأذكار)';
      case ActionType.quranReading:
        return 'Lecture du Coran (قراءة القرآن)';
      case ActionType.charity:
        return 'Charité (الصدقة)';
      case ActionType.goodDeed:
        return 'Bonnes Actions (الأعمال الطيبة)';
      case ActionType.hadith:
        return 'Hadith (الأحاديث)';
      case ActionType.sunnah:
        return 'Sunnah (السنة)';
      case ActionType.socialService:
        return 'Service Communautaire (الخدمة المجتمعية)';
      case ActionType.family:
        return 'Famille (الأسرة)';
      case ActionType.worship:
        return 'Adorations (العبادات)';
      case ActionType.names99:
        return 'Les 99 Noms d\'Allah (الأسماء الحسنى)';
    }
  }

  IconData _getTypeIcon(ActionType type) {
    switch (type) {
      case ActionType.prayer:
        return Icons.mosque;
      case ActionType.dhikr:
        return Icons.favorite;
      case ActionType.quranReading:
        return Icons.menu_book;
      case ActionType.charity:
        return Icons.volunteer_activism;
      case ActionType.goodDeed:
        return Icons.thumb_up;
      case ActionType.hadith:
        return Icons.chrome_reader_mode;
      case ActionType.sunnah:
        return Icons.check_circle;
      case ActionType.socialService:
        return Icons.groups;
      case ActionType.family:
        return Icons.family_restroom;
      case ActionType.worship:
        return Icons.auto_awesome;
      case ActionType.names99:
        return Icons.star_border;
    }
  }

  Color _getTypeColor(ActionType type) {
    switch (type) {
      case ActionType.prayer:
        return IslamicColors.emeraldGreen;
      case ActionType.dhikr:
        return IslamicColors.roseGold;
      case ActionType.quranReading:
        return IslamicColors.mysticBlue;
      case ActionType.charity:
        return IslamicColors.dustyRose;
      case ActionType.goodDeed:
        return IslamicColors.softViolet;
      case ActionType.hadith:
        return const Color(0xFF8D6E63);
      case ActionType.sunnah:
        return const Color(0xFF66BB6A);
      case ActionType.socialService:
        return const Color(0xFF26C6DA);
      case ActionType.family:
        return const Color(0xFFBA68C8);
      case ActionType.worship:
        return const Color(0xFFFFB74D);
      case ActionType.names99:
        return IslamicColors.emeraldGreen;
    }
  }

  Future<void> _onActionCompleted(String actionId) async {
    await StorageService.completeAction(actionId);
    await _loadActions();
    widget.onActionCompleted?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Hassanat gagnés! BarakAllahu fik!'),
            ],
          ),
          backgroundColor: IslamicColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: CircularProgressIndicator(
              color: IslamicColors.emeraldGreen,
            ),
          ),
        ),
      );
    }

    final completedCount = _actions.where((action) => action.isCompleted).length;
    final totalPoints = _actions.fold<int>(
      0,
      (sum, action) => sum + (action.isCompleted ? action.hassanatReward : 0),
    );

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(completedCount, totalPoints),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatisticsCard(completedCount, totalPoints),
                    const SizedBox(height: 20),
                    _buildSpiritualToolsCard(),
                    const SizedBox(height: 20),
                    ..._buildActionGroups(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          IslamicColors.pearlWhite,
          IslamicColors.pearlWhite.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
        ],
      ),
    );
  }

  Widget _buildAppBar(int completedCount, int totalPoints) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Actions à faire',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildStatisticsCard(int completedCount, int totalPoints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Actions Terminées',
              '$completedCount/${_actions.length}',
              Icons.task_alt,
              IslamicColors.emeraldGreen,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              'Hassanat Gagnés',
              totalPoints.toString(),
              Icons.stars,
              IslamicColors.roseGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpiritualToolsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.mysticBlue.withValues(alpha: 0.1),
            IslamicColors.dustyRose.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.mysticBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                color: IslamicColors.mysticBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: IslamicColors.mysticBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Outils Spirituels',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.mysticBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  'القرآن الكريم',
                  'Lecture du Coran',
                  Icons.menu_book,
                  IslamicColors.dustyRose,
                  () {
                    // Redirige vers le sélecteur de sourates
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuranPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  'أسماء الله الحسنى',
                  'Noms d\'Allah',
                  Icons.star_border,
                  IslamicColors.roseGold,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllahNamesPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  'الأدعية',
                  'Invocations',
                  Icons.menu_book,
                  IslamicColors.emeraldGreen,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvocationsPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    String titleArabic,
    String titleFrench,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              titleArabic,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              titleFrench,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionGroups() {
    final List<Widget> widgets = [];
    
    for (final type in ActionType.values) {
      if (_groupedActions.containsKey(type) && _groupedActions[type]!.isNotEmpty) {
        widgets.add(_buildActionGroup(type, _groupedActions[type]!));
        widgets.add(const SizedBox(height: 20));
      }
    }
    
    return widgets;
  }

  Widget _buildActionGroup(ActionType type, List<IslamicAction> actions) {
    final color = _getTypeColor(type);
    final completedInGroup = actions.where((a) => a.isCompleted).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_getTypeIcon(type), color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTypeTitle(type),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedInGroup/${actions.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DailyActionsCard(
          actions: actions,
          onActionCompleted: _onActionCompleted,
          pinnedActionIds: _pinnedIds,
          onTogglePin: (actionId, willPin) async {
            await StorageService.togglePinnedAction(actionId);
            // Reload pin state only (fast)
            final pins = await StorageService.getPinnedActionIds();
            if (mounted) {
              setState(() => _pinnedIds = pins);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(willPin ? 'Action épinglée ✅' : 'Action désépinglée'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          onActionTap: (action) {
            if (action.type == ActionType.names99) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllahNamesPage(),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}