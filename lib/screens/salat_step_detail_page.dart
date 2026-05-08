import 'package:flutter/material.dart';
import 'package:sajda/models/salat_course.dart';
import 'package:sajda/theme.dart';
// import 'package:sajda/screens/takbir_detail_page.dart';
// Illustrations et carrousels désactivés sur ce flux

class SalatStepDetailPage extends StatefulWidget {
  final SalatCourse course;

  const SalatStepDetailPage({super.key, required this.course});

  @override
  State<SalatStepDetailPage> createState() => _SalatStepDetailPageState();
}

class _SalatStepDetailPageState extends State<SalatStepDetailPage> with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  int _currentImageIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  void _nextStep() {
    if (_currentStepIndex < widget.course.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _currentImageIndex = 0;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.course.steps[_currentStepIndex];
    
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStepCard(currentStep),
                        const SizedBox(height: 20),
                        _buildInstructionsCard(currentStep),
                        const SizedBox(height: 16),
                        if (currentStep.explanations.isNotEmpty)
                          _buildBulletSection(
                            title: 'Explications essentielles',
                            icon: Icons.menu_book,
                            color: IslamicColors.emeraldGreen,
                            items: currentStep.explanations,
                          ),
                        if (currentStep.explanations.isNotEmpty) const SizedBox(height: 12),
                        if (currentStep.mistakes.isNotEmpty)
                          _buildBulletSection(
                            title: 'Erreurs fréquentes',
                            icon: Icons.error_outline,
                            color: IslamicColors.roseGold,
                            items: currentStep.mistakes,
                          ),
                        if (currentStep.mistakes.isNotEmpty) const SizedBox(height: 12),
                        if (currentStep.tips.isNotEmpty)
                          _buildBulletSection(
                            title: 'Conseils & sunan',
                            icon: Icons.lightbulb_outline,
                            color: IslamicColors.mysticBlue,
                            items: currentStep.tips,
                          ),
                        const SizedBox(height: 12),
                        _buildSourceNote(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildNavigationControls(),
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
          _getStepTypeColor(widget.course.steps[_currentStepIndex].type).withValues(alpha: 0.1),
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
              widget.course.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  content: const Text('Étape sauvegardée dans vos favoris'),
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

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentStepIndex + 1}/${widget.course.steps.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_currentStepIndex + 1) / widget.course.steps.length * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStepIndex + 1) / widget.course.steps.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.emeraldGreen),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(SalatStep step) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStepTypeColor(step.type).withValues(alpha: 0.15),
            _getStepTypeColor(step.type).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStepTypeColor(step.type).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStepTypeColor(step.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStepTypeIcon(step.type),
                  color: _getStepTypeColor(step.type),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _getStepTypeColor(step.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStepTypeName(step.type),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Illustrations: réactivées uniquement pour "Apprendre la Salat - Bases"
          if (widget.course.id == 'basic_salat' && step.imageAssets.isNotEmpty)
            _buildIllustrations(step.imageAssets, _getStepTypeColor(step.type)),
          const SizedBox(height: 8),
          
          // Texte arabe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  step.arabicText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Text(
                  step.transliteration,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: IslamicColors.mysticBlue,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  step.meaning,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
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

  Widget _buildIllustrations(List<String> assets, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.collections, color: accent),
            const SizedBox(width: 8),
            Text(
              'Illustrations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: assets.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.04),
                      child: Image.asset(
                        assets[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey[500],
                              size: 40,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Indicateurs
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < assets.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentImageIndex == i ? 18 : 6,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i
                                ? accent
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  

  Widget _buildInstructionsCard(SalatStep step) {
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
              Icon(
                Icons.info_outline,
                color: IslamicColors.emeraldGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions détaillées',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[800],
                            height: 1.6,
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

  Widget _buildSourceNote() {
    return Opacity(
      opacity: 0.7,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            widget.course.id == 'advanced_salat'
                ? 'Source: La Citadelle du Musulman'
                : 'Source d\'explications: al-dirassa.com',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
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
              onPressed: _currentStepIndex > 0 ? _previousStep : null,
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
                  SizedBox(width: 8),
                  Text('Précédent'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: _currentStepIndex < widget.course.steps.length - 1 
                  ? _nextStep 
                  : () {
                      // Cours terminé
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.emoji_events, color: IslamicColors.roseGold),
                              const SizedBox(width: 8),
                              const Text('Félicitations!'),
                            ],
                          ),
                          content: const Text(
                            'Vous avez terminé ce cours sur la Salat. '
                            'Continuez à pratiquer pour perfectionner votre prière.',
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
                                  _currentStepIndex = 0;
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
                  Text(_currentStepIndex < widget.course.steps.length - 1 
                      ? 'Suivant' 
                      : 'Terminer'),
                  const SizedBox(width: 8),
                  Icon(_currentStepIndex < widget.course.steps.length - 1 
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

  Color _getStepTypeColor(SalatStepType type) {
    switch (type) {
      case SalatStepType.standing:
        return IslamicColors.emeraldGreen;
      case SalatStepType.bowing:
        return IslamicColors.mysticBlue;
      case SalatStepType.prostration:
        return IslamicColors.roseGold;
      case SalatStepType.sitting:
        return IslamicColors.dustyRose;
      case SalatStepType.transition:
        return Colors.grey;
    }
  }

  IconData _getStepTypeIcon(SalatStepType type) {
    switch (type) {
      case SalatStepType.standing:
        return Icons.accessibility_new;
      case SalatStepType.bowing:
        return Icons.keyboard_arrow_down;
      case SalatStepType.prostration:
        return Icons.keyboard_double_arrow_down;
      case SalatStepType.sitting:
        return Icons.event_seat;
      case SalatStepType.transition:
        return Icons.sync_alt;
    }
  }

  String _getStepTypeName(SalatStepType type) {
    switch (type) {
      case SalatStepType.standing:
        return 'Position debout';
      case SalatStepType.bowing:
        return 'Inclinaison';
      case SalatStepType.prostration:
        return 'Prosternation';
      case SalatStepType.sitting:
        return 'Position assise';
      case SalatStepType.transition:
        return 'Transition';
    }
  }
}