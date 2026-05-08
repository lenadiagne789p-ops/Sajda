import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/models/salat_course.dart';
import 'package:sajda/widgets/salat_media_carousel.dart';

class TakbirDetailPage extends StatefulWidget {
  final SalatStep takbirStep;

  const TakbirDetailPage({
    super.key,
    required this.takbirStep,
  });

  @override
  State<TakbirDetailPage> createState() => _TakbirDetailPageState();
}

class _TakbirDetailPageState extends State<TakbirDetailPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _handsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _handsAnimation;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _handsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _handsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _handsAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _handsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.emeraldGreen.withValues(alpha: 0.1),
              IslamicColors.pearlWhite.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildMainImage(),
                  _buildArabicSection(),
                  _buildMeaningSection(),
                  _buildInstructionsSection(),
                  _buildSpiritualSignificanceSection(),
                  _buildInteractiveDemo(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
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
              '🤲 ${widget.takbirStep.title}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
              color: IslamicColors.emeraldGreen,
            ),
            onPressed: _toggleAudio,
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SalatMediaCarousel(
            imageUrls: widget.takbirStep.imageAssets,
            title: 'Position de Takbîr',
            subtitle: 'Références visuelles',
            accentColor: IslamicColors.emeraldGreen,
            height: 260,
            autoPlay: true,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: IslamicColors.emeraldGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.takbirStep.duration}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.roseGold.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.roseGold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: IslamicColors.roseGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Texte sacré',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.takbirStep.arabicText,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
              fontSize: 36,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: IslamicColors.roseGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.takbirStep.transliteration,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: IslamicColors.roseGold,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        children: [
          Row(
            children: [
              Icon(
                Icons.translate,
                color: IslamicColors.mysticBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Signification',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.mysticBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.takbirStep.meaning,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final instructions = [
      '🤲 Levez les deux mains à hauteur des oreilles',
      '👐 Les paumes doivent être tournées vers la Qibla',
      '🎯 Gardez les doigts joints et détendus',
      '📢 Prononcez clairement "Allāhu akbar"',
      '💭 Concentrez votre intention sur Allah',
      '⏰ Maintenez cette position pendant quelques secondes'
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.mysticBlue.withValues(alpha: 0.1),
            IslamicColors.mysticBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.mysticBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
                color: IslamicColors.mysticBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions détaillées',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.mysticBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: IslamicColors.mysticBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: IslamicColors.mysticBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSpiritualSignificanceSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.dustyRose.withValues(alpha: 0.1),
            IslamicColors.dustyRose.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.dustyRose.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: IslamicColors.dustyRose,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Sagesse spirituelle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.dustyRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Le Takbîr de consécration marque l\'entrée solennelle dans la prière. En levant les mains et en proclamant la grandeur d\'Allah, le fidèle se sépare symboliquement du monde matériel pour entrer dans un état de communication directe avec son Créateur. Ce geste représente l\'abandon de tous les soucis terrestres et l\'élévation de l\'âme vers Allah.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: IslamicColors.dustyRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: IslamicColors.dustyRose,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ce geste purifie l\'intention et prépare le cœur à la rencontre avec Allah',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: IslamicColors.dustyRose,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDemo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.emeraldGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                color: IslamicColors.emeraldGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Démonstration interactive',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!_handsAnimationController.isAnimating) {
                _handsAnimationController.reset();
                _handsAnimationController.forward();
              }
            },
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
                ),
              ),
              child: AnimatedBuilder(
                animation: _handsAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main gauche
                      Transform.translate(
                        offset: Offset(-20 * _handsAnimation.value, -10 * _handsAnimation.value),
                        child: Transform.rotate(
                          angle: -0.2 * _handsAnimation.value,
                          child: Icon(
                            Icons.back_hand,
                            size: 40,
                            color: IslamicColors.emeraldGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Corps
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: IslamicColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 40,
                            decoration: BoxDecoration(
                              color: IslamicColors.emeraldGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      // Main droite
                      Transform.translate(
                        offset: Offset(20 * _handsAnimation.value, -10 * _handsAnimation.value),
                        child: Transform.rotate(
                          angle: 0.2 * _handsAnimation.value,
                          child: Icon(
                            Icons.front_hand,
                            size: 40,
                            color: IslamicColors.emeraldGreen,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Touchez pour voir l\'animation du Takbir',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleAudio() {
    setState(() {
      _isAudioPlaying = !_isAudioPlaying;
    });
    
    // Simuler la lecture audio
    if (_isAudioPlaying) {
      Future.delayed(Duration(seconds: widget.takbirStep.duration), () {
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
          });
        }
      });
    }
  }
}