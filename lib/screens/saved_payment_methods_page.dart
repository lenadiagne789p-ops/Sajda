import 'package:flutter/material.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/payment_methods_page.dart';

class SavedPaymentMethod {
  final String id;
  final String name;
  final String maskedDetails;
  final IconData icon;
  final Color color;
  final bool isDefault;
  final DateTime addedDate;
  final String type; // 'card', 'wallet', 'bank', etc.

  SavedPaymentMethod({
    required this.id,
    required this.name,
    required this.maskedDetails,
    required this.icon,
    required this.color,
    this.isDefault = false,
    required this.addedDate,
    required this.type,
  });
}

class SavedPaymentMethodsPage extends StatefulWidget {
  const SavedPaymentMethodsPage({super.key});

  @override
  State<SavedPaymentMethodsPage> createState() => _SavedPaymentMethodsPageState();
}

class _SavedPaymentMethodsPageState extends State<SavedPaymentMethodsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<SavedPaymentMethod> _savedMethods = [
    SavedPaymentMethod(
      id: '1',
      name: 'Banque Al Rajhi',
      maskedDetails: '****1234',
      icon: Icons.account_balance,
      color: IslamicColors.emeraldGreen,
      isDefault: true,
      addedDate: DateTime.now().subtract(const Duration(days: 30)),
      type: 'bank',
    ),
    SavedPaymentMethod(
      id: '2',
      name: 'JazzCash',
      maskedDetails: '+92 301 *******89',
      icon: Icons.phone_android,
      color: Color(0xFF6B46C1),
      addedDate: DateTime.now().subtract(const Duration(days: 15)),
      type: 'wallet',
    ),
    SavedPaymentMethod(
      id: '3',
      name: 'Visa',
      maskedDetails: '**** **** **** 5678',
      icon: Icons.credit_card,
      color: Color(0xFF1A1F71),
      addedDate: DateTime.now().subtract(const Duration(days: 7)),
      type: 'card',
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

  void _setDefaultMethod(String methodId) {
    setState(() {
      for (var method in _savedMethods) {
        if (method.id == methodId) {
          // Créer une nouvelle instance avec isDefault modifié
          final index = _savedMethods.indexOf(method);
          _savedMethods[index] = SavedPaymentMethod(
            id: method.id,
            name: method.name,
            maskedDetails: method.maskedDetails,
            icon: method.icon,
            color: method.color,
            isDefault: true,
            addedDate: method.addedDate,
            type: method.type,
          );
        } else {
          // Retirer le statut par défaut des autres
          final index = _savedMethods.indexOf(method);
          _savedMethods[index] = SavedPaymentMethod(
            id: method.id,
            name: method.name,
            maskedDetails: method.maskedDetails,
            icon: method.icon,
            color: method.color,
            isDefault: false,
            addedDate: method.addedDate,
            type: method.type,
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moyen de paiement par défaut modifié'),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
  }

  void _removeMethod(SavedPaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Supprimer le moyen de paiement'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${method.name}" de vos moyens de paiement sauvegardés ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _savedMethods.remove(method);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${method.name} supprimé'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _addNewPaymentMethod() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsPage(
          planId: 'add_method',
          planTitle: 'Ajouter un moyen de paiement',
          planPrice: '',
        ),
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
              // Header avec statistiques
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
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: IslamicColors.emeraldGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Moyens sauvegardés',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_savedMethods.length} méthodes enregistrées',
                            style: theme.textTheme.bodyMedium?.copyWith(
                             color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.security,
                        color: IslamicColors.emeraldGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des moyens de paiement sauvegardés
              Expanded(
                child: _savedMethods.isEmpty 
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _savedMethods.length,
                        itemBuilder: (context, index) {
                          final method = _savedMethods[index];
                          return _buildSavedMethodCard(method, theme);
                        },
                      ),
              ),

              // Bouton pour ajouter un nouveau moyen de paiement
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _addNewPaymentMethod,
                    icon: Icon(
                      Icons.add,
                      color: IslamicColors.emeraldGreen,
                    ),
                    label: Text(
                      'Ajouter un moyen de paiement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: IslamicColors.emeraldGreen,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
             color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun moyen de paiement',
            style: theme.textTheme.titleLarge?.copyWith(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos moyens de paiement préférés\npour des achats plus rapides',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMethodCard(SavedPaymentMethod method, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
           color: method.isDefault 
               ? IslamicColors.emeraldGreen.withValues(alpha: 0.3)
               : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: method.isDefault ? 2 : 1,
        ),
        gradient: method.isDefault
            ? LinearGradient(
                 colors: [
                   IslamicColors.emeraldGreen.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              )
            : null,
      ),
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
                          if (method.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: IslamicColors.emeraldGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PAR DÉFAUT',
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
                        method.maskedDetails,
                        style: theme.textTheme.bodyMedium?.copyWith(
                           color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                     Icons.more_vert,
                     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'default':
                        if (!method.isDefault) {
                          _setDefaultMethod(method.id);
                        }
                        break;
                      case 'remove':
                        _removeMethod(method);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!method.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 20,
                              color: IslamicColors.emeraldGreen,
                            ),
                            const SizedBox(width: 8),
                            const Text('Définir par défaut'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          const Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                   Icons.schedule,
                   size: 16,
                   color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Ajouté le ${_formatDate(method.addedDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeLabel(method.type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: method.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Banque';
      case 'wallet':
        return 'Portefeuille';
      case 'card':
        return 'Carte';
      default:
        return 'Autre';
    }
  }
}