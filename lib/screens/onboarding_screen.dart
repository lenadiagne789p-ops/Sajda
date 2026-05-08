import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/app_state.dart';
import 'package:sajda/screens/subscription_screen.dart';
import 'package:sajda/utils/language_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<OnboardingPage> _buildPages(Locale locale) {
    final lang = locale.languageCode;
    final isFr = lang == 'fr';
    String t(String fr, String en) => isFr ? fr : en;

    return [
      OnboardingPage(
        icon: Icons.mosque,
        title: t('Bienvenue dans Sajda', 'Welcome to Sajda'),
        description: t(
          'Votre compagnon spirituel pour développer votre relation avec Allah à travers des actions quotidiennes.',
          'Your spiritual companion to deepen your connection with Allah through meaningful daily actions.',
        ),
        color: IslamicColors.emeraldGreen,
        imageAsset: 'assets/images/mosque_dawn_fajr_prayer_blue_1761577546239.jpg',
      ),
      OnboardingPage(
        icon: Icons.star_border,
        title: t('Gagnez des Hassanates', 'Earn Hassanat'),
        description: t(
          'Accumulez des récompenses en priant, faisant du dhikr, lisant le Coran, et en accomplissant de bonnes actions.',
          'Gain rewards by praying, doing dhikr, reading the Qur’an, and performing good deeds.',
        ),
        color: IslamicColors.roseGold,
        imageAsset: 'assets/images/forest_with_sun_rays_green_1761819732703.jpg',
      ),
      OnboardingPage(
        icon: Icons.trending_up,
        title: t('Suivez vos Progrès', 'Track Your Progress'),
        description: t(
          'Visualisez votre évolution, maintenez vos séries et débloquez des badges de réussite.',
          'Visualize your growth, keep streaks alive, and unlock achievement badges.',
        ),
        color: IslamicColors.mysticBlue,
        imageAsset: 'assets/images/calm_lake_at_sunrise_blue_1761819728777.jpg',
      ),
      OnboardingPage(
        icon: Icons.people_outline,
        title: t('Rejoignez la Communauté', 'Join the Community'),
        description: t(
          'Partagez votre parcours avec d\'autres musulmans et encouragez-vous mutuellement.',
          'Share your journey with fellow Muslims and uplift one another.',
        ),
        color: IslamicColors.softViolet,
        imageAsset: 'assets/images/mosque_sunset_horizon_red_1761768824893.jpg',
      ),
      OnboardingPage(
        icon: Icons.help_outline,
        title: t('Pourquoi Sajda ?', 'Why Sajda?'),
        description: t(
          'Pour structurer une pratique simple, régulière et motivante. Sajda vous guide pas à pas, avec des rappels bienveillants et des contenus fiables.',
          'To build a simple, consistent, and motivating practice. Sajda guides you step by step with gentle reminders and trustworthy content.',
        ),
        color: IslamicColors.topaz,
        imageAsset: 'assets/images/desert_dunes_at_dusk_orange_1761819730184.jpg',
      ),
      OnboardingPage(
        icon: Icons.tips_and_updates_outlined,
        title: t('Comment ça marche ?', 'How does it work?'),
        description: t(
          'Choisissez vos objectifs, suivez les temps de prière, avancez dans la salat illustrée, lisez le Coran, et cumulez des hassanates au quotidien.',
          'Set your goals, track prayer times, learn salat with illustrations, read Qur’an, and accumulate hassanat day by day.',
        ),
        color: IslamicColors.mysticBlue,
        imageAsset: 'assets/images/ocean_waves_long_exposure_turquoise_1761819733406.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final pages = _buildPages(LanguageController.locale.value);
    if (_currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await AppState.markOnboardingComplete();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = LanguageController.locale.value;
    final isFr = locale.languageCode == 'fr';
    final pages = _buildPages(locale);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton Skip + sélecteur de langue
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        _LangChip(
                          label: 'FR',
                          selected: isFr,
                          onTap: () => LanguageController.setLanguage('fr'),
                        ),
                        const SizedBox(width: 6),
                        _LangChip(
                          label: 'EN',
                          selected: !isFr,
                          onTap: () => LanguageController.setLanguage('en'),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      isFr ? 'Passer' : 'Skip',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu des pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration image (rich, colorful)
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0.95, end: 1.0),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (page.imageAsset != null)
                                        Image.asset(
                                          page.imageAsset!,
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Container(color: page.color.withValues(alpha: 0.2)),
                                      // soft gradient overlay for contrast
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.0),
                                              Colors.black.withValues(alpha: 0.25),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // icon chip in the corner
                                      Positioned(
                                        right: 12,
                                        top: 12,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(page.icon, color: theme.colorScheme.primary, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        // Titre
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicateur de pages et boutons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicateur de pages
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: WormEffect(
                      dotColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      activeDotColor: theme.colorScheme.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton Suivant/Commencer
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex == pages.length - 1
                            ? (isFr ? 'Commencer' : 'Get started')
                            : (isFr ? 'Suivant' : 'Next'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String? imageAsset;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.imageAsset,
  });
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}