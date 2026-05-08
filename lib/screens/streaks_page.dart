import 'package:flutter/material.dart';
import 'package:sajda/models/growth_challenge.dart';
import 'package:sajda/models/streak.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/theme.dart';
// ActionsPage removed

class StreaksPage extends StatefulWidget {
  const StreaksPage({super.key});

  @override
  State<StreaksPage> createState() => _StreaksPageState();
}

class _StreaksPageState extends State<StreaksPage>
    with TickerProviderStateMixin {
  List<Streak> _streaks = [];
  late AnimationController _fireController;
  late AnimationController _progressController;

  int get _bestStreak {
    if (_streaks.isEmpty) return 0;
    return _streaks.map((s) => s.bestStreak).reduce((a, b) => a > b ? a : b);
  }

  @override
  void initState() {
    super.initState();
    _streaks = Streak.getDefaultStreaks();
    
    _fireController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController.forward();
  }

  @override
  void dispose() {
    _fireController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _incrementStreak(int index) async {
    setState(() {
      _streaks[index] = _streaks[index].incrementStreak();
    });

    // When user marks a streak, reflect it in Daily Actions so it appears on Home
    try {
      final actionId = _mapStreakToActionId(_streaks[index].id);
      if (actionId != null) {
        await StorageService.completeAction(actionId);
      }
    } catch (_) {}

    if (_streaks[index].isTargetReached) {
      _showStreakCompletionDialog(_streaks[index]);
    }
  }

  String? _mapStreakToActionId(String streakId) {
    switch (streakId) {
      case 'prayer_streak':
        return 'prayer_on_time';
      case 'quran_daily':
        return 'quran_reading';
      case 'morning_dhikr':
        return 'dhikr_morning';
      case 'evening_dhikr':
        return 'dhikr_evening';
      case 'charity_weekly':
        return 'charity';
      case 'sunnah_prayers':
        return 'prayer_sunnah_general';
      case 'good_deed_daily':
        return 'good_deed';
      case 'family_time':
        return 'family_prayer';
      case 'memorize_surah':
        return 'quran_memorization';
      case 'istighfar_100':
        return 'istighfar';
      case 'salawat_100':
        return 'salawat';
      default:
        return null;
    }
  }

  void _showStreakCompletionDialog(Streak streak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.local_fire_department, color: streak.color),
            const SizedBox(width: 8),
            const Text('🔥 Objectif atteint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    streak.color.withValues(alpha: 0.2),
                    streak.color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(streak.icon, color: streak.color, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    streak.titleArabic,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: streak.color,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Objectif de ${streak.targetDays} jours atteint!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: IslamicColors.emeraldGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${streak.hassanatReward} Hassanat',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: streak.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('ماشاء الله!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildOverviewCard(),
                    const SizedBox(height: 20),
                    _buildChallengesSection(),
                    const SizedBox(height: 20),
                    _buildActiveStreaksSection(),
                    const SizedBox(height: 20),
                    _buildAllStreaksSection(),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: IslamicColors.roseGold, size: 24),
            const SizedBox(width: 8),
            Text(
              'العادات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      // No actions
    );
  }

  Widget _buildOverviewCard() {
    final activeStreaks = _streaks.where((s) => s.isActive).length;
    final totalCurrentDays = _streaks.fold<int>(0, (sum, s) => sum + s.currentStreak);
    final bestStreak = _bestStreak;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _fireController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_fireController.value * 0.1),
                    child: Icon(
                      Icons.local_fire_department,
                      color: IslamicColors.roseGold,
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Aperçu des habitudes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Actifs',
                  activeStreaks.toString(),
                  Icons.trending_up,
                  IslamicColors.emeraldGreen,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Total Jours',
                  totalCurrentDays.toString(),
                  Icons.calendar_today,
                  IslamicColors.roseGold,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Meilleur',
                  bestStreak.toString(),
                  Icons.emoji_events,
                  IslamicColors.mysticBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    final challenges = GrowthChallenge.catalog();
    final bestStreak = _bestStreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Défis évolutifs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final status = GrowthChallenge.statusFor(
                bestStreak: bestStreak,
                index: index,
                orderedChallenges: challenges,
              );
              return Padding(
                padding: EdgeInsets.only(right: index == challenges.length - 1 ? 0 : 12),
                child: _buildChallengeCard(challenge, status, bestStreak),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    GrowthChallenge challenge,
    GrowthChallengeStatus status,
    int bestStreak,
  ) {
    final progress = challenge.progress(bestStreak);
    final theme = Theme.of(context);
    final isLocked = status == GrowthChallengeStatus.locked;
    final isCompleted = status == GrowthChallengeStatus.completed;

    Color foregroundColor = Colors.white;
    if (isLocked) {
      foregroundColor = Colors.white.withValues(alpha: 0.6);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            challenge.startColor,
            challenge.endColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: challenge.startColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(challenge.icon, color: foregroundColor),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      challenge.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildChallengeStatusChip(status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                challenge.headline,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: challenge.focusAreas
                    .map(
                      (item) => Chip(
                        label: Text(
                          item,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: challenge.startColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}% de ton objectif de ${challenge.completionThreshold} jours',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Débloque en validant l’étape précédente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isCompleted)
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: challenge.startColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Terminé',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: challenge.startColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeStatusChip(GrowthChallengeStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case GrowthChallengeStatus.locked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Verrouillé',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case GrowthChallengeStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_fix_high, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'En cours',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case GrowthChallengeStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Gagné',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildActiveStreaksSection() {
    final activeStreaks = _streaks.where((s) => s.isActive).toList();
    
    if (activeStreaks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.trending_down,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune action en cours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Commencez une nouvelle habitude aujourd\'hui!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔥 Actions en cours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activeStreaks.length,
            itemBuilder: (context, index) {
              return _buildActiveStreakCard(activeStreaks[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStreakCard(Streak streak, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            streak.color.withValues(alpha: 0.2),
            streak.color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak.color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(streak.icon, color: streak.color, size: 24),
              AnimatedBuilder(
                animation: _fireController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_fireController.value * 0.2),
                    child: Text(
                      '🔥',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${streak.currentStreak}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: streak.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'jours',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            streak.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: streak.color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: streak.progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: streak.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStreaksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toutes les habitudes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _streaks.length,
          itemBuilder: (context, index) {
            return _buildStreakCard(_streaks[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildStreakCard(Streak streak, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak.isActive 
              ? streak.color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: streak.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: streak.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(streak.icon, color: streak.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            streak.titleArabic,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: streak.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (streak.isActive)
                          AnimatedBuilder(
                            animation: _fireController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_fireController.value * 0.1),
                                child: const Text('🔥', style: TextStyle(fontSize: 16)),
                              );
                            },
                          ),
                      ],
                    ),
                    Text(
                      streak.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      streak.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: streak.level.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(streak.level.icon, color: streak.level.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          streak.level.title,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: streak.level.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actuel: ${streak.currentStreak}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: streak.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Meilleur: ${streak.bestStreak}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: streak.color,
                          ),
                        ),
                        Text(
                          '${streak.currentStreak}/${streak.targetDays}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: streak.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: streak.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                streak.color,
                                streak.color.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: streak.isCompletedToday 
                    ? null 
                    : () async {
                        await _incrementStreak(index);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: const [Icon(Icons.task_alt, color: Colors.white), SizedBox(width: 8), Text('Action marquée comme faite')]),
                              backgroundColor: streak.color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: streak.isCompletedToday 
                      ? Colors.grey[300] 
                      : streak.color,
                  foregroundColor: streak.isCompletedToday 
                      ? Colors.grey[600] 
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  streak.isCompletedToday ? 'Fait' : 'Fait',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}