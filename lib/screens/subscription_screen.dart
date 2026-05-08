import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/home_page.dart';
import 'package:sajda/screens/payment_methods_page.dart';
import 'package:sajda/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sajda/utils/language_controller.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoadingProducts = true;
  Map<String, ProductDetails> _products = {};

  // Trial state

  List<SubscriptionPlan> _plans = [];

  // Fallback plans used if products cannot be loaded (web/preview or error)
  List<SubscriptionPlan> _fallbackPlans() {
    return [
      SubscriptionPlan(
        id: 'premium_annual',
        title: 'Tout déverrouiller',
        price: '34,99 €/an',
        originalPrice: null,
        description: '7 jours gratuits, puis 34,99 € / an',
        features: [
          'Supprime toutes les pubs',
          'Récitateurs & cours du Coran',
          'Widgets de prière Premium',
        ],
        isPopular: true,
        hasTrial: true,
      ),
      SubscriptionPlan(
        id: 'no_ads_annual',
        title: 'Sans pub',
        price: '17,99 €/an',
        originalPrice: null,
        description: 'Seulement 0,05 €/ jour',
        features: [
          'Supprime toutes les pubs',
        ],
        isPopular: false,
        hasTrial: false,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    // Always show a meaningful UI instantly to avoid any white/blank screen
    // while IAP initializes in background.
    _plans = _fallbackPlans();
    _initializePurchases();
    _refreshTrialInfo();
    _animationController.forward();
  }

  Future<void> _refreshTrialInfo() async {
    await SubscriptionService.trialDaysRemaining();
    if (mounted) {
      setState(() {
      });
    }
  }

  Future<void> _initializePurchases() async {
    setState(() => _isLoadingProducts = true);
    try {
      final bool isAvailable = await SubscriptionService.initializePurchases();
      if (isAvailable) {
        final productsMap = await SubscriptionService.getProductsMap();
        setState(() {
          _products = productsMap;
          _plans = _buildPlansFromProducts();
          if (_plans.length < 2) {
            // Ensure we always have the two-card layout
            _setDefaultPlans();
          }
        });
      } else {
        _setDefaultPlans();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de l\'initialisation des achats: $e');
      _setDefaultPlans();
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _setDefaultPlans() {
    setState(() {
      _plans = [
        // Offre principale: Tout déverrouiller (annuel) avec essai 7 jours
        SubscriptionPlan(
          id: 'premium_annual',
          title: 'Tout déverrouiller',
          price: '34,99 €/an',
          originalPrice: null,
          description: '7 jours gratuits, puis 34,99 € / an',
          features: [
            'Supprime toutes les pubs',
            'Récitateurs & cours du Coran',
            'Widgets de prière Premium',
          ],
          isPopular: true,
          hasTrial: true,
        ),
        // Seconde offre: Sans pub (annuel)
        SubscriptionPlan(
          id: 'no_ads_annual',
          title: 'Sans pub',
          price: '17,99 €/an',
          originalPrice: null,
          description: 'Seulement 0,05 €/ jour',
          features: [
            'Supprime toutes les pubs',
          ],
          isPopular: false,
          hasTrial: false,
        ),
      ];
    });
  }

  List<SubscriptionPlan> _buildPlansFromProducts() {
    final List<SubscriptionPlan> plans = [];
    if (_products.containsKey('premium_annual')) {
      final p = _products['premium_annual']!;
      plans.add(SubscriptionPlan(
        id: p.id,
        title: 'Tout déverrouiller',
        price: p.price,
        originalPrice: null,
        description: '7 jours gratuits, puis ${p.price} / an',
        features: [
          'Supprime toutes les pubs',
          'Récitateurs & cours du Coran',
          'Widgets de prière Premium',
        ],
        isPopular: true,
        hasTrial: true,
      ));
    }
    if (_products.containsKey('no_ads_annual')) {
      final p = _products['no_ads_annual']!;
      plans.add(SubscriptionPlan(
        id: p.id,
        title: 'Sans pub',
        price: p.price,
        originalPrice: null,
        description: 'Seulement env. 0,05 €/ jour',
        features: [
          'Supprime toutes les pubs',
        ],
        isPopular: false,
        hasTrial: false,
      ));
    }
    return plans;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _restorePurchases() async {
    try {
      await SubscriptionService.restorePurchases();
      await Future.delayed(const Duration(seconds: 2));
      final isPremium = await SubscriptionService.isPremium();
      if (isPremium && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showInfoDialog('Aucun achat trouvé', 'Aucun achat précédent n\'a été trouvé sur ce compte.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur lors de la restauration: ${e.toString()}');
      }
    }
  }

  Future<void> _startTrial() async {
    await SubscriptionService.startFreeTrial();
    await _refreshTrialInfo();
    if (mounted) _navigateToHome();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.check_circle, color: IslamicColors.emeraldGreen),
          const SizedBox(width: 12),
          const Text('Félicitations !'),
        ]),
        content: const Text('Votre abonnement premium a été activé avec succès. Profitez de toutes les fonctionnalités avancées !'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            style: ElevatedButton.styleFrom(backgroundColor: IslamicColors.emeraldGreen, foregroundColor: Colors.white),
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          const Text('Erreur'),
        ]),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }


  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(title),
        ]),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }


  void _navigateToHome() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
  }

  void _navigateToPaymentMethods(SubscriptionPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentMethodsPage(planId: plan.id, planTitle: plan.title, planPrice: plan.price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = LanguageController.locale.value.languageCode == 'ar';
    // Defensive: always have at least two plans to render
    final displayedPlans = _plans.length >= 2 ? _plans : _fallbackPlans();

    return Scaffold(
      appBar: const GradientAppBar(title: 'Sajda Premium', showBack: true),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Slim progress indicator to show background loading (non-blocking)
                      if (_isLoadingProducts)
                        const LinearProgressIndicator(minHeight: 2),
                      // Hero with Mecca pilgrims image + gradient overlay and trial badge
                      SizedBox(
                        height: 240,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.zero,
                              child: Image.asset(
                                'assets/images/pilgrims_walking_in_Mecca_crowd_Kaaba_white_1762182021275.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16,
                              top: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: IslamicColors.emeraldGreen, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      LanguageController.locale.value.languageCode == 'ar'
                                          ? '7 أيام مجانًا'
                                          : 'Essai gratuit 7 jours',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: IslamicColors.emeraldGreen,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'ركّز على إيمانك' : 'Concentrez-vous sur votre foi',
                                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.block, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(isAr ? 'احذف جميع الإعلانات' : 'Supprimez toutes les pubs', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.menu_book_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(isAr ? 'افتح القرّاء ودورات القرآن' : 'Débloquez les récitateurs & cours du Coran', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(isAr ? 'افتح عناصر الصلاة المميزة' : 'Débloquez les widgets de prière Premium', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _buildOfferCard(context, displayedPlans[0], highlight: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildOfferCard(context, displayedPlans[1])),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _startTrial,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: IslamicColors.emeraldGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text((isAr ? 'جرّب الآن!' : 'Essayez maintenant!').toUpperCase(), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(isAr ? 'يمكنك الإلغاء في أي وقت دون رسوم.' : 'Annulez à tout moment, sans pénalités ni frais.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(onPressed: () {}, child: Text(isAr ? 'الشروط العامة' : 'Conditions générales')),
                                const SizedBox(width: 12),
                                TextButton(onPressed: _restorePurchases, child: Text(isAr ? 'استعادة المشتريات' : 'Restaurer les achats')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, SubscriptionPlan plan, {bool highlight = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? IslamicColors.emeraldGreen : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: highlight ? 2 : 1,
        ),
      ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: IslamicColors.topaz, borderRadius: BorderRadius.circular(8)),
              child: Text(LanguageController.locale.value.languageCode == 'ar' ? 'أفضل سعر' : 'Meilleur prix', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          if (highlight) const SizedBox(height: 8),
          Text(plan.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(plan.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const Spacer(),
          Text(plan.price, style: theme.textTheme.titleLarge?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => _navigateToPaymentMethods(plan),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: highlight ? IslamicColors.emeraldGreen : theme.colorScheme.outline)),
              child: Text('Choisir', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }


}

class SubscriptionPlan {
  final String id;
  final String title;
  final String price;
  final String? originalPrice;
  final String description;
  final List<String> features;
  final bool isPopular;
  final bool isLifetime;
  final bool hasTrial;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.features,
    this.isPopular = false,
    this.isLifetime = false,
    this.hasTrial = false,
  });
}