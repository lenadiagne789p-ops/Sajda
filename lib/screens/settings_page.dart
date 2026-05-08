import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/subscription_service.dart';
import 'package:sajda/screens/subscription_screen.dart';
import 'package:sajda/screens/saved_payment_methods_page.dart';
import 'package:sajda/screens/api_test_screen.dart';
import 'package:sajda/widgets/premium_badge.dart';
import 'package:sajda/services/backup_service.dart';
import 'package:flutter/services.dart';
import 'package:sajda/services/notification_service.dart';
import 'package:sajda/services/prayer_notification_service.dart';
import 'package:sajda/widgets/ui/modern_card.dart';
import 'package:sajda/widgets/ui/primary_button.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/utils/language_controller.dart';
import 'package:sajda/utils/theme_controller.dart';
import 'package:sajda/screens/presentation_page.dart';
import 'package:sajda/services/auth_service.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/widgets/auth/sign_in_sheet.dart';
import 'package:sajda/screens/splash_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isPremium = false;
  bool _isLifetime = false;
  bool _prayerRemindersEnabled = true;
  bool _encouragementsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isPremium = await SubscriptionService.isPremium();
    final isLifetime = await SubscriptionService.isLifetime();
    final prayerPopup = await PrayerNotificationService().isPopupEnabled();
    final encourEnabled = await NotificationService.areEncouragementsEnabled();

    setState(() {
      _isPremium = isPremium;
      _isLifetime = isLifetime;
      _prayerRemindersEnabled = prayerPopup;
      _encouragementsEnabled = encourEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Paramètres', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountSection(context),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Premium',
            [
              if (!_isPremium) ...[
                _buildPremiumUpgradeCard(theme),
              ] else ...[
                _buildPremiumStatusCard(theme),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Notifications',
            [
              _buildSwitchTile(
                'Rappels de prière',
                'Recevoir des notifications pour les heures de prière',
                Icons.access_time,
                _prayerRemindersEnabled,
                    (value) async {
                  setState(() => _prayerRemindersEnabled = value);
                  await PrayerNotificationService().setPopupEnabled(value);
                },
              ),
              _buildSwitchTile(
                'Encouragements quotidiens',
                'Messages de motivation (Dhikr, Coran, bilan du soir)',
                Icons.flag,
                _encouragementsEnabled,
                    (value) async {
                  setState(() => _encouragementsEnabled = value);
                  await NotificationService.setEncouragementsEnabled(value);
                },
              ),
              _buildActionTile(
                'Envoyer une notification de test',
                "Aperçu immédiat du style non transparent",
                Icons.notifications_active,
                    () async {
                  await NotificationService.showInstantNotification(
                    'Notification de test',
                    "Ceci est un aperçu instantané des notifications de Sajda.",
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Apparence',
            [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.mode,
                builder: (context, themeMode, _) {
                  return _buildSwitchTile(
                    'Mode sombre',
                    'Basculer entre le thème clair et sombre',
                    Icons.dark_mode_outlined,
                    themeMode == ThemeMode.dark,
                    (value) async {
                      await ThemeController.set(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Langue',
            [
              _buildLanguageRow(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Paiement',
            [
              _buildActionTile(
                'Moyens de paiement',
                'Gérer vos méthodes de paiement sauvegardées',
                Icons.payment,
                _openPaymentMethods,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Données',
            [
              _buildActionTile(
                'Sauvegarder les données',
                'Synchroniser avec le cloud (Premium)',
                Icons.cloud_upload,
                _backupData,
                isPremiumFeature: !_isPremium,
              ),
              _buildActionTile(
                'Restaurer les données',
                'Récupérer depuis le cloud',
                Icons.cloud_download,
                _restoreData,
                isPremiumFeature: !_isPremium,
              ),
              _buildActionTile(
                'Exporter les données (JSON)',
                'Copier toutes vos données au format JSON',
                Icons.file_download,
                _exportLocalJson,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final dynamic user = AuthService.currentUser;

    return ModernCard(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      tintColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Compte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (user == null) ...[
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_user, color: IslamicColors.mysticBlue),
              title: Text('Non connecté'),
              subtitle: Text('Sauvegardez votre progression en vous connectant'),
            ),
            PrimaryButton(
              label: 'Se connecter',
              icon: Icons.login,
              onPressed: () => SignInSheet.show(context),
            ),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user, color: IslamicColors.mysticBlue),
              title: Text((
                  (user.displayName != null && user.displayName.toString().trim().isNotEmpty)
                      ? user.displayName.toString().trim()
                      : (user.email != null ? user.email.toString().split('@').first : 'Utilisateur')
              )),
              subtitle: Text(user.email?.toString() ?? ''),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.signOut();
                  await StorageService.resetOnboardingFlag();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: IslamicColors.roseGold),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IslamicColors.roseGold,
                  side: const BorderSide(color: IslamicColors.roseGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(BuildContext context) {
    final theme = Theme.of(context);
    final current = LanguageController.locale.value.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Langue', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12, runSpacing: 8,
          children: [
            _chip(theme, label: 'Français', selected: current == 'fr', onTap: () => LanguageController.setLanguage('fr')),
            _chip(theme, label: 'العربية', selected: current == 'ar', onTap: () => LanguageController.setLanguage('ar')),
          ],
        ),
      ],
    );
  }

  Widget _chip(ThemeData theme, {required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return ModernCard(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      tintColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ...children.map((child) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child)),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.roseGold.withValues(alpha: 0.1), IslamicColors.emeraldGreen.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IslamicColors.roseGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.diamond, color: IslamicColors.roseGold, size: 28), const SizedBox(width: 12), Text('Passer à Premium', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Text('Débloquez toutes les fonctionnalités avancées.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Découvrir Premium', icon: Icons.diamond, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SubscriptionScreen()))),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.emeraldGreen.withValues(alpha: 0.1), IslamicColors.roseGold.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: IslamicColors.emeraldGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text('Statut Premium Actif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleSmall), Text(subtitle, style: theme.textTheme.bodySmall)])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: IslamicColors.emeraldGreen),
      ],
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback? onTap, {bool isPremiumFeature = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? (isPremiumFeature ? _showPremiumDialog : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleSmall), Text(subtitle, style: theme.textTheme.bodySmall)])),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog() { /* Logique du dialogue Premium */ }
  void _openPaymentMethods() { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedPaymentMethodsPage())); }
  void _backupData() { _showCloudSetupDialog(isRestore: false); }
  void _restoreData() { _showCloudSetupDialog(isRestore: true); }
  void _showCloudSetupDialog({required bool isRestore}) { /* Logique Cloud */ }
  void _openHelpCenter() { /* Logique Help */ }
  void _contactSupport() { /* Logique Contact */ }
  void _openApiTest() { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApiTestScreen())); }

  Future<void> _exportLocalJson() async {
    final json = await BackupService.exportAllToJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié !'), backgroundColor: IslamicColors.emeraldGreen));
  }

  void _restorePurchases() async {
    await SubscriptionService.restorePurchases();
    _loadSettings();
  }
}
