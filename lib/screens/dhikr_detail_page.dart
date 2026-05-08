import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/screens/morning_dhikr_page.dart';
import 'package:sajda/screens/evening_dhikr_page.dart';
import 'package:sajda/theme.dart';

class DhikrDetailPage extends StatefulWidget {
  final IslamicAction dhikr;
  final Function(String) onActionCompleted;

  const DhikrDetailPage({
    super.key,
    required this.dhikr,
    required this.onActionCompleted,
  });

  @override
  State<DhikrDetailPage> createState() => _DhikrDetailPageState();
}

class _DhikrDetailPageState extends State<DhikrDetailPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  int _counter = 0;
  int _targetCount = 33; // Par défaut, peut être personnalisé
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _isCompleted = widget.dhikr.isCompleted;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    if (_counter < _targetCount) {
      setState(() {
        _counter++;
      });
      
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });

      if (_counter >= _targetCount) {
        _completeAction();
      }
    }
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  void _completeAction() {
    setState(() {
      _isCompleted = true;
    });
    
    widget.onActionCompleted(widget.dhikr.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.star, color: IslamicColors.roseGold),
            const SizedBox(width: 8),
            const Text('Barakallahu fik!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous avez terminé ${widget.dhikr.title}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '+${widget.dhikr.hassanatReward} Hassanat gagnés!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Redirection spéciale pour les dhikr du matin et du soir
    if (widget.dhikr.id == 'morning_adhkar') {
      return const MorningDhikrPage();
    }
    if (widget.dhikr.id == 'evening_adhkar') {
      return const EveningDhikrPage();
    }
    
    final progress = _targetCount > 0 ? _counter / _targetCount : 0.0;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.roseGold.withValues(alpha: 0.1),
              IslamicColors.pearlWhite,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                // Use SliverToBoxAdapter to allow natural height + scrolling, avoiding RenderFlex overflow
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDhikrCard(),
                        const SizedBox(height: 20),
                        _buildCounterSection(progress),
                        const SizedBox(height: 20),
                        _buildControlButtons(),
                        const SizedBox(height: 20),
                        if (widget.dhikr.hadiths != null && widget.dhikr.hadiths!.isNotEmpty)
                          _buildHadithCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: IslamicColors.roseGold.withValues(alpha: 0.1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: IslamicColors.roseGold),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Dhikr',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.roseGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildDhikrCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: IslamicColors.roseGold.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.dhikr.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: IslamicColors.roseGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: IslamicColors.roseGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: IslamicColors.roseGold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              widget.dhikr.arabicTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: IslamicColors.roseGold,
                fontWeight: FontWeight.bold,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCounterSection(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Progression',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? Colors.green : IslamicColors.emeraldGreen,
                  ),
                ),
              ),
              Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '/ $_targetCount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        if (!_isCompleted) ...[
          GestureDetector(
            onTap: _incrementCounter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    IslamicColors.emeraldGreen,
                    IslamicColors.emeraldGreen.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: IslamicColors.emeraldGreen.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallButton('33', () => setState(() => _targetCount = 33)),
              _buildSmallButton('99', () => setState(() => _targetCount = 99)),
              _buildSmallButton('100', () => setState(() => _targetCount = 100)),
              _buildSmallButton('Reset', _resetCounter),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Dhikr Terminé - ${widget.dhikr.hassanatReward} Hassanat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHadithCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.menu_book, color: IslamicColors.roseGold),
              const SizedBox(width: 8),
              Text(
                'Hadith',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.roseGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.dhikr.hadiths!.first,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}