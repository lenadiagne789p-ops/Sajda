import 'package:flutter/material.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/theme.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool isRecommended;
  final List<String> supportedCountries;
  final String? processingTime;
  final String? fees;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isAvailable = true,
    this.isRecommended = false,
    this.supportedCountries = const [],
    this.processingTime,
    this.fees,
  });
}

class PaymentMethodsPage extends StatefulWidget {
  final String planId;
  final String planTitle;
  final String planPrice;

  const PaymentMethodsPage({
    super.key,
    required this.planId,
    required this.planTitle,
    required this.planPrice,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  final List<PaymentMethod> _paymentMethods = [
    // Moyens de paiement islamiques
    PaymentMethod(
      id: 'islamic_bank',
      name: 'Banque Islamique',
      description: 'Paiement conforme à la Sharia via banques islamiques partenaires',
      icon: Icons.account_balance,
      color: IslamicColors.emeraldGreen,
      isRecommended: true,
      supportedCountries: ['SA', 'AE', 'QA', 'KW', 'BH', 'OM', 'MY', 'ID'],
      processingTime: '1-2 jours ouvrables',
      fees: 'Gratuit',
    ),
    
    PaymentMethod(
      id: 'sadaqah_wallet',
      name: 'Portefeuille Sadaqah',
      description: 'Système de paiement basé sur la charité islamique',
      icon: Icons.volunteer_activism,
      color: IslamicColors.roseGold,
      isRecommended: true,
      supportedCountries: ['Mondial'],
      processingTime: 'Instantané',
      fees: '2.5% (reversé en sadaqah)',
    ),

    // Moyens de paiement mobiles populaires dans les pays musulmans
    PaymentMethod(
      id: 'jazzcash',
      name: 'JazzCash',
      description: 'Paiement mobile populaire au Pakistan',
      icon: Icons.phone_android,
      color: Color(0xFF6B46C1),
      supportedCountries: ['PK'],
      processingTime: 'Instantané',
      fees: '1.5%',
    ),

    PaymentMethod(
      id: 'easypaisa',
      name: 'Easypaisa',
      description: 'Solution de paiement mobile au Pakistan',
      icon: Icons.payment,
      color: Color(0xFF059669),
      supportedCountries: ['PK'],
      processingTime: 'Instantané',
      fees: '1.2%',
    ),

    PaymentMethod(
      id: 'bkash',
      name: 'bKash',
      description: 'Portefeuille mobile populaire au Bangladesh',
      icon: Icons.account_balance_wallet,
      color: Color(0xFFE91E63),
      supportedCountries: ['BD'],
      processingTime: 'Instantané',
      fees: '1.8%',
    ),

    PaymentMethod(
      id: 'fawry',
      name: 'Fawry',
      description: 'Plateforme de paiement électronique en Égypte',
      icon: Icons.store,
      color: Color(0xFFFF6B35),
      supportedCountries: ['EG'],
      processingTime: '2-4 heures',
      fees: '2%',
    ),

    // Moyens de paiement internationaux
    PaymentMethod(
      id: 'google_pay',
      name: 'Google Pay',
      description: 'Paiement rapide et sécurisé avec Google',
      icon: Icons.g_mobiledata,
      color: Color(0xFF4285F4),
      supportedCountries: ['Mondial'],
      processingTime: 'Instantané',
      fees: 'Gratuit',
    ),

    PaymentMethod(
      id: 'apple_pay',
      name: 'Apple Pay',
      description: 'Paiement sécurisé avec Touch ID / Face ID',
      icon: Icons.apple,
      color: Color(0xFF000000),
      supportedCountries: ['Mondial'],
      processingTime: 'Instantané',
      fees: 'Gratuit',
    ),

    PaymentMethod(
      id: 'paypal',
      name: 'PayPal',
      description: 'Paiement en ligne sécurisé mondial',
      icon: Icons.payment,
      color: Color(0xFF0070BA),
      supportedCountries: ['Mondial'],
      processingTime: 'Instantané',
      fees: '2.9% + 0.30€',
    ),

    PaymentMethod(
      id: 'visa_mastercard',
      name: 'Carte Bancaire',
      description: 'Visa, Mastercard et autres cartes acceptées',
      icon: Icons.credit_card,
      color: Color(0xFF1A1F71),
      supportedCountries: ['Mondial'],
      processingTime: 'Instantané',
      fees: '2.4%',
    ),

    // Cryptomonnaies halal
    PaymentMethod(
      id: 'halal_crypto',
      name: 'Crypto Halal',
      description: 'Cryptomonnaies conformes aux principes islamiques',
      icon: Icons.currency_bitcoin,
      color: Color(0xFFF7931A),
      supportedCountries: ['Mondial'],
      processingTime: '10-30 minutes',
      fees: 'Variable (réseau)',
    ),

    // Virements bancaires
    PaymentMethod(
      id: 'bank_transfer',
      name: 'Virement Bancaire',
      description: 'Virement SEPA et international',
      icon: Icons.account_balance,
      color: Color(0xFF6B7280),
      supportedCountries: ['Mondial'],
      processingTime: '1-3 jours ouvrables',
      fees: 'Selon banque',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<PaymentMethod> get _availableMethods {
    return _paymentMethods.where((method) => method.isAvailable).toList();
  }

  List<PaymentMethod> get _recommendedMethods {
    return _availableMethods.where((method) => method.isRecommended).toList();
  }

  List<PaymentMethod> get _otherMethods {
    return _availableMethods.where((method) => !method.isRecommended).toList();
  }

  Future<void> _processPayment(PaymentMethod method) async {
    setState(() => _isProcessing = true);

    try {
      // Simuler le traitement du paiement
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showPaymentDialog(method);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur lors du traitement du paiement: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentDialog(PaymentMethod method) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              method.icon,
              color: method.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Paiement via ${method.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan: ${widget.planTitle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prix: ${widget.planPrice}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (method.fees != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frais de transaction:'),
                  Text(
                    method.fees!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (method.processingTime != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Temps de traitement:'),
                  Text(
                    method.processingTime!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: IslamicColors.emeraldGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé et crypté',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: IslamicColors.emeraldGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ici, rediriger vers le processus de paiement spécifique
              _redirectToPayment(method);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: method.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _redirectToPayment(PaymentMethod method) {
    // Ici, implémenter la redirection vers chaque système de paiement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirection vers ${method.name}...'),
        backgroundColor: method.color,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Moyens de paiement', showBack: true),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header avec informations du plan
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                      IslamicColors.roseGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.diamond,
                          color: IslamicColors.emeraldGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.planTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.planPrice,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des moyens de paiement
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Moyens recommandés
                    if (_recommendedMethods.isNotEmpty) ...[
                      Text(
                        'Recommandés',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: IslamicColors.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._recommendedMethods.map((method) => 
                        _buildPaymentMethodCard(method, theme, isRecommended: true)),
                      const SizedBox(height: 24),
                    ],

                    // Autres moyens
                    Text(
                      'Autres moyens de paiement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._otherMethods.map((method) => 
                      _buildPaymentMethodCard(method, theme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, ThemeData theme, {bool isRecommended = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended 
              ? IslamicColors.roseGold.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isRecommended ? 2 : 1,
        ),
        gradient: isRecommended
            ? LinearGradient(
                colors: [
                  IslamicColors.roseGold.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isProcessing ? null : () {
            setState(() => _selectedMethod = method);
            _processPayment(method);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: method.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        method.icon,
                        color: method.color,
                        size: 24,
                      ),
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
                                  method.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: IslamicColors.roseGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'RECOMMANDÉ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                             color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isProcessing && _selectedMethod?.id == method.id)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                  ],
                ),

                if (method.fees != null || method.processingTime != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (method.fees != null) ...[
                        Icon(
                          Icons.payment,
                          size: 16,
                           color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          method.fees!,
                           style: theme.textTheme.bodySmall?.copyWith(
                             color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                           ),
                        ),
                        if (method.processingTime != null) ...[
                          const SizedBox(width: 16),
                        ],
                      ],
                      if (method.processingTime != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                         color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          method.processingTime!,
                           style: theme.textTheme.bodySmall?.copyWith(
                             color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                           ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}