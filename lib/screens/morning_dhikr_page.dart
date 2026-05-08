import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/models/morning_evening_dhikr.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/invocation_video_section.dart';

class MorningDhikrPage extends StatefulWidget {
  const MorningDhikrPage({super.key});

  @override
  State<MorningDhikrPage> createState() => _MorningDhikrPageState();
}

class _MorningDhikrPageState extends State<MorningDhikrPage> with TickerProviderStateMixin {
  List<DhikrItem> _morningDhikr = [];
  int _currentIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  

  @override
  void initState() {
    super.initState();
    _morningDhikr = MorningEveningDhikr.getMorningDhikr();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();

  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _nextDhikr() {
    if (_currentIndex < _morningDhikr.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _slideController.reset();
      _slideController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _previousDhikr() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _slideController.reset();
      _slideController.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTimeIndicator(),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildVideoSection(),
                        const SizedBox(height: 20),
                        _buildProgressIndicator(),
                        const SizedBox(height: 20),
                        _buildDhikrCard(),
                        const SizedBox(height: 20),
                        _buildBenefitsCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return InvocationVideoSection(
      title: 'Invocations du matin en vidéo',
      accentColor: IslamicColors.emeraldGreen,
      youtubeVideoId: 'jhSfWdr1Kzk',
      youtubeUrl: 'https://www.youtube.com/watch?v=jhSfWdr1Kzk',
      // If you upload an MP4 in Assets, set the path below to the filename
      // e.g., 'assets/videos/invocations_matin.mp4'. If the asset isn't found,
      // the widget will fall back to YouTube automatically.
      assetVideoPath: null,
      networkVideoUrl: null,
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFEB3B).withValues(alpha: 0.1),
          IslamicColors.pearlWhite.withValues(alpha: 0.8),
          Colors.white,
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: IslamicColors.emeraldGreen),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '🌅 أذكار الصباح',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: IslamicColors.emeraldGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Dhikr ajouté aux favoris'),
                  backgroundColor: IslamicColors.emeraldGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFEB3B).withValues(alpha: 0.2),
            const Color(0xFFFFEB3B).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFEB3B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_sunny,
            color: Color(0xFFFF8F00),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invocations du matin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFF8F00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'À réciter après la prière du Fajr jusqu\'au lever du soleil',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dhikr ${_currentIndex + 1}/${_morningDhikr.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_currentIndex + 1) / _morningDhikr.length * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _morningDhikr.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(IslamicColors.emeraldGreen),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCard() {
    final dhikr = _morningDhikr[_currentIndex];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dhikr.color.withValues(alpha: 0.15),
            dhikr.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dhikr.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dhikr.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  dhikr.icon,
                  color: dhikr.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invocation ${_currentIndex + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: dhikr.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'À répéter ${dhikr.repetitions} fois',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (dhikr.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: dhikr.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  dhikr.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            dhikr.color.withValues(alpha: 0.2),
                            dhikr.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: dhikr.color,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chargement de l\'image sacrée...',
                              style: TextStyle(
                                color: dhikr.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            dhikr.color.withValues(alpha: 0.2),
                            dhikr.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: dhikr.color.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image de consécration',
                              style: TextStyle(
                                color: dhikr.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  dhikr.arabicText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                Text(
                  dhikr.transliteration,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: IslamicColors.mysticBlue,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  dhikr.meaning,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    final dhikr = _morningDhikr[_currentIndex];
    
    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: IslamicColors.roseGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Bienfaits et récompenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                  IslamicColors.emeraldGreen.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: IslamicColors.emeraldGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bienfait spirituel',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dhikr.benefit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  IslamicColors.roseGold.withValues(alpha: 0.1),
                  IslamicColors.roseGold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: IslamicColors.roseGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Récompense divine',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: IslamicColors.roseGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dhikr.reward,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: _currentIndex > 0 ? _previousDhikr : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 4),
                  Text('Précédent'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: _currentIndex < _morningDhikr.length - 1 
                  ? _nextDhikr 
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle, color: IslamicColors.emeraldGreen),
                              SizedBox(width: 8),
                              Text('Barakallahu fik!'),
                            ],
                          ),
                          content: const Text(
                            'Vous avez terminé vos invocations du matin. '
                            'Qu\'Allah accepte vos adorations et vous bénisse.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('Terminer'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _currentIndex = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: IslamicColors.emeraldGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Recommencer'),
                            ),
                          ],
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: IslamicColors.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_currentIndex < _morningDhikr.length - 1 
                      ? 'Suivant' 
                      : 'Terminer'),
                  const SizedBox(width: 4),
                  Icon(_currentIndex < _morningDhikr.length - 1 
                      ? Icons.arrow_forward 
                      : Icons.check),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}