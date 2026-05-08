import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/app_state.dart';
import 'package:sajda/screens/home_page.dart';
import 'package:sajda/widgets/sajda_logo.dart';
import 'package:sajda/screens/presentation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late final bool _useAnimations;

  @override
  void initState() {
    super.initState();
    _useAnimations = !kIsWeb;
    if (_useAnimations) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _scaleAnimation = Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));

      _animationController.forward();
    }
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Réduction du délai d'attente
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Vérifier si c'est la première utilisation
    final bool isFirstTime = await AppState.shouldShowOnboarding();
    
    if (isFirstTime) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PresentationPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    if (_useAnimations) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // debug
    // ignore: avoid_print
    print('[DEBUG] Building SplashScreen');
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: _useAnimations
              ? AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _SplashContent(theme: theme),
                      ),
                    );
                  },
                )
              : _SplashContent(theme: theme),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  final ThemeData theme;
  const _SplashContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo Sajda personnalisé
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SajdaLogo(
              size: 120,
              primaryColor: IslamicColors.emeraldGreen,
              accentColor: IslamicColors.roseGold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Nom de l'application
        Text(
          'SAJDA',
          style: theme.textTheme.displaySmall?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 16),
        // Slogan
        Text(
          'Votre Parcours Spirituel',
          style: theme.textTheme.titleMedium?.copyWith(
            color: IslamicColors.emeraldGreen.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 48),
        // Indicateur de chargement
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              IslamicColors.emeraldGreen.withValues(alpha: 0.7),
            ),
            strokeWidth: 3,
            backgroundColor: IslamicColors.roseGold.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}