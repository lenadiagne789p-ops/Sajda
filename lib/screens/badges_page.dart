import 'package:flutter/material.dart';
import 'package:sajda/models/badge.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/services/share_service.dart';
import 'package:sajda/theme.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<SpiritualBadge> _badges = [];
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await StorageService.getBadges();
      final user = await StorageService.getUser();
      
      if (mounted) {
        setState(() {
          _badges = badges;
          _user = user;
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

    final unlockedBadges = _badges.where((badge) => badge.isUnlocked).toList();
    final lockedBadges = _badges.where((badge) => !badge.isUnlocked).toList();
    
    // Group badges by category
    final Map<String, List<SpiritualBadge>> badgesByCategory = {};
    for (final badge in _badges) {
      if (!badgesByCategory.containsKey(badge.category)) {
        badgesByCategory[badge.category] = [];
      }
      badgesByCategory[badge.category]!.add(badge);
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(unlockedBadges.length),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatisticsCard(unlockedBadges.length, _badges.length),
                    const SizedBox(height: 30),
                    _buildCategoryFilter(),
                    const SizedBox(height: 20),
                    if (unlockedBadges.isNotEmpty) ...[
                      _buildSectionHeader('Badges Débloqués', Icons.emoji_events),
                      const SizedBox(height: 16),
                      _buildBadgesGrid(unlockedBadges, true),
                      const SizedBox(height: 30),
                    ],
                    if (lockedBadges.isNotEmpty) ...[
                      _buildSectionHeader('À Débloquer', Icons.lock_outline),
                      const SizedBox(height: 16),
                      _buildBadgesGrid(lockedBadges, false),
                      const SizedBox(height: 30),
                    ],
                    _buildCategoriesSection(badgesByCategory),
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

  Widget _buildAppBar(int unlockedCount) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Badges Spirituels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildStatisticsCard(int unlockedCount, int totalCount) {
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.roseGold.withValues(alpha: 0.1),
            IslamicColors.emeraldGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.roseGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: IslamicColors.roseGold,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '$unlockedCount/$totalCount',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Badges Débloqués',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.roseGold),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% terminé',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: IslamicColors.emeraldGreen, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid(List<SpiritualBadge> badges, bool isUnlocked) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return _buildBadgeCard(badges[index], isUnlocked);
      },
    );
  }

  Widget _buildBadgeCard(SpiritualBadge badge, bool isUnlocked) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? badge.color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? badge.color
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: isUnlocked ? [
                      BoxShadow(
                        color: badge.color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    badge.icon,
                    color: isUnlocked ? Colors.white : Colors.grey[600],
                    size: 32,
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (isUnlocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _shareBadge(badge),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: badge.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isUnlocked
                    ? IslamicColors.emeraldGreen
                    : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge.arabicName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isUnlocked
                    ? IslamicColors.roseGold
                    : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            if (isUnlocked && badge.unlockedDate != null)
              Text(
                _formatDate(badge.unlockedDate!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${badge.requiredHassanat} hassanat',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(SpiritualBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: badge.isUnlocked ? badge.color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.icon,
                color: badge.isUnlocked ? Colors.white : Colors.grey[600],
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.arabicName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: IslamicColors.roseGold,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (badge.isUnlocked && badge.unlockedDate != null)
              Text(
                'Débloqué le ${_formatDate(badge.unlockedDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Requis: ${badge.requiredHassanat} hassanat',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: IslamicColors.emeraldGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCategoryFilter() {
    final categories = ['Tous', 'Prières', 'Coran', 'Charité', 'Dhikr', 'Excellence'];
    
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == 0; // Default to 'Tous' for now
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                // Implement filter logic
              },
              selectedColor: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
              checkmarkColor: IslamicColors.emeraldGreen,
              labelStyle: TextStyle(
                color: isSelected ? IslamicColors.emeraldGreen : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection(Map<String, List<SpiritualBadge>> badgesByCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Par Catégories', Icons.category),
        const SizedBox(height: 16),
        ...badgesByCategory.entries.map((entry) {
          return _buildCategoryCard(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryCard(String category, List<SpiritualBadge> badges) {
    final unlockedCount = badges.where((b) => b.isUnlocked).length;
    final progress = badges.isNotEmpty ? unlockedCount / badges.length : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: IslamicColors.emeraldGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$unlockedCount/${badges.length} débloqués',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.roseGold),
                strokeWidth: 3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.roseGold),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% terminé',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Prières':
        return Icons.mosque;
      case 'Coran':
        return Icons.menu_book;
      case 'Charité':
        return Icons.volunteer_activism;
      case 'Dhikr':
        return Icons.favorite;
      case 'Jeûne':
        return Icons.dining_outlined;
      case 'Hajj':
        return Icons.home_outlined;
      case 'Excellence':
        return Icons.military_tech;
      case 'Famille':
        return Icons.family_restroom;
      case 'Étude':
        return Icons.school;
      default:
        return Icons.star;
    }
  }

  void _shareBadge(SpiritualBadge badge) {
    if (_user != null && badge.isUnlocked) {
      final achievementMessage = 'Badge "${badge.name}" (${badge.arabicName}) débloqué!';
      ShareService.shareAchievement(context, achievementMessage, _user!);
    }
  }
}