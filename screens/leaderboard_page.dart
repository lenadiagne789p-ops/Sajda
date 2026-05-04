import 'package:flutter/material.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/theme.dart';
import 'dart:math' as math;

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with TickerProviderStateMixin {
  List<User> _topUsers = [];
  User? _currentUser;
  int _currentUserRank = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final currentUser = await StorageService.getUser();
      // Simuler des utilisateurs pour le classement (en réalité, cela viendrait d'un serveur)
      final topUsers = await _generateMockLeaderboard(currentUser);
      
      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _topUsers = topUsers;
          _currentUserRank = _calculateUserRank(currentUser, topUsers);
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<User>> _generateMockLeaderboard(User currentUser) async {
    // En production, ceci viendrait d'une API
    final random = math.Random();
    final mockUsers = <User>[];
    
    // Ajouter l'utilisateur actuel
    mockUsers.add(currentUser);
    
    // Générer des utilisateurs factices
    final names = [
      'Ahmed Al-Mansouri', 'Fatima Benali', 'Omar Ibn Khaldoun',
      'Aisha Al-Zahra', 'Ali Ibn Sina', 'Maryam Al-Kindi',
      'Yusuf Al-Battani', 'Zeinab Rumi', 'Hassan Al-Jazari',
      'Leila Al-Farabi', 'Mohammad Al-Biruni', 'Safiya Ibn Rushd'
    ];
    
    for (int i = 0; i < names.length; i++) {
      if (names[i] != currentUser.name) {
        final hassanat = random.nextInt(8000) + 100;
        mockUsers.add(User(
          id: 'mock_$i',
          name: names[i],
          totalHassanat: hassanat,
          currentLevel: _calculateCurrentLevel(hassanat),
          streak: random.nextInt(100),
          lastActivityDate: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        ));
      }
    }
    
    // Trier par hassanat
    mockUsers.sort((a, b) => b.totalHassanat.compareTo(a.totalHassanat));
    
    return mockUsers.take(10).toList();
  }

  int _calculateCurrentLevel(int hassanat) {
    if (hassanat >= 5000) return 4;
    if (hassanat >= 1500) return 3;
    if (hassanat >= 500) return 2;
    if (hassanat >= 100) return 1;
    return 0;
  }

  int _calculateUserRank(User currentUser, List<User> topUsers) {
    for (int i = 0; i < topUsers.length; i++) {
      if (topUsers[i].id == currentUser.id) {
        return i + 1;
      }
    }
    return topUsers.length + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: IslamicColors.emeraldGreen),
                SizedBox(height: 16),
                Text('Chargement du classement...'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCurrentUserCard(),
                    const SizedBox(height: 24),
                    _buildTopThreeUsers(),
                    const SizedBox(height: 24),
                    _buildLeaderboardList(),
                    const SizedBox(height: 16),
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
            const Icon(
              Icons.leaderboard,
              color: IslamicColors.emeraldGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Classement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ),
      ),
      child: Container(
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
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$_currentUserRank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.name ?? 'Vous',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser?.totalHassanat ?? 0} hassanat',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: IslamicColors.roseGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentUserRank <= 3)
              Icon(
                Icons.workspace_premium,
                color: _getRankColor(_currentUserRank),
                size: 32,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThreeUsers() {
    if (_topUsers.length < 3) return const SizedBox.shrink();
    
    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 3 des Champions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPodiumUser(_topUsers[1], 2), // 2ème place
                _buildPodiumUser(_topUsers[0], 1), // 1ère place (plus haut)
                _buildPodiumUser(_topUsers[2], 3), // 3ème place
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumUser(User user, int rank) {
    final isFirst = rank == 1;
    return Column(
      children: [
        Container(
          width: isFirst ? 80 : 70,
          height: isFirst ? 80 : 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getRankGradient(rank),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getRankColor(rank).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isFirst ? 40 : 35,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 90,
          child: Text(
            user.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: IslamicColors.emeraldGreen,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${user.totalHassanat}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _getRankColor(rank),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ),
      ),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Classement Complet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._topUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final rank = index + 1;
              final isCurrentUser = user.id == _currentUser?.id;
              
              return _buildLeaderboardItem(user, rank, isCurrentUser);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(User user, int rank, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? IslamicColors.emeraldGreen.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? _getRankColor(rank)
                  : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name + (isCurrentUser ? ' (Vous)' : ''),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isCurrentUser
                        ? IslamicColors.emeraldGreen
                        : Colors.black87,
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                Text(
                  user.spiritualLevel,
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
              Text(
                '${user.totalHassanat}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'hassanat',
                style: TextStyle(
                  color: IslamicColors.roseGold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
      default:
        return [Colors.grey, Colors.grey[600]!];
    }
  }
}