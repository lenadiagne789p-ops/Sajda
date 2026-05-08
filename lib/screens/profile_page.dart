import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/services/share_service.dart';
import 'package:sajda/screens/leaderboard_page.dart';
import 'package:sajda/screens/reminders_page.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/level_system.dart';
import 'package:sajda/screens/prayer_settings_page.dart';
import 'package:sajda/widgets/prayer_stats_widget.dart';
import 'package:sajda/screens/settings_page.dart';
import 'package:sajda/screens/subscription_screen.dart';
import 'package:sajda/services/backup_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
// import 'package:sajda/services/auth_service.dart';
// import 'package:sajda/widgets/auth/sign_in_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  StreamSubscription<void>? _userChangedSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _userChangedSub = StorageService.userChanged.listen((_) {
      if (mounted) _loadUserData();
    });
    // Account/Login UI removed from Profile → no need to watch auth state here
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userChangedSub?.cancel();
    // No auth listener registered
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await StorageService.getUser();
      
      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserName() async {
    if (_nameController.text.trim().isNotEmpty) {
      await StorageService.updateUserName(_nameController.text.trim());
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nom mis à jour avec succès'),
            backgroundColor: IslamicColors.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showNameEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Modifier votre nom',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nom',
            labelStyle: TextStyle(color: IslamicColors.emeraldGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: IslamicColors.emeraldGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: IslamicColors.emeraldGreen, width: 2),
            ),
          ),
          cursorColor: IslamicColors.emeraldGreen,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateUserName();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sauvegarder',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Suppressed avatar edit dialog — profile photos are disabled

  void _showThemeDialog() {
    Future<String> _getMode() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('theme_mode') ?? 'system';
    }

    Future<void> _setMode(String mode) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thème: ${mode == 'light' ? 'Clair' : mode == 'dark' ? 'Sombre' : 'Automatique'} — Redémarrez pour appliquer'),
            backgroundColor: IslamicColors.emeraldGreen,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _getMode(),
        builder: (context, snapshot) {
          final groupValue = snapshot.data ?? 'system';
          return AlertDialog(
            title: Text(
              'Thème de l\'interface',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.light_mode, color: Colors.orange),
                  title: const Text('Mode Clair'),
                  trailing: Radio<String>(
                    value: 'light',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setMode(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode, color: Colors.indigo),
                  title: const Text('Mode Sombre'),
                  trailing: Radio<String>(
                    value: 'dark',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setMode(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_mode, color: Colors.grey),
                  title: const Text('Automatique'),
                  trailing: Radio<String>(
                    value: 'system',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setMode(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                  icon: const Icon(Icons.tune, color: IslamicColors.emeraldGreen),
                  label: const Text('Plus d\'options'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer', style: TextStyle(color: IslamicColors.emeraldGreen)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog() {
    Future<String> _getLang() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_language') ?? 'fr';
    }

    Future<void> _setLang(String lang) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Langue: ${lang.toUpperCase()} — Redémarrez pour appliquer'),
            backgroundColor: IslamicColors.emeraldGreen,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _getLang(),
        builder: (context, snapshot) {
          final groupValue = snapshot.data ?? 'fr';
          return AlertDialog(
            title: Text(
              'Langue de l\'interface',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                  title: const Text('Français'),
                  trailing: Radio<String>(
                    value: 'fr',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setLang(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: const Text('English'),
                  trailing: Radio<String>(
                    value: 'en',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setLang(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
                ListTile(
                  leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                  title: const Text('العربية'),
                  trailing: Radio<String>(
                    value: 'ar',
                    groupValue: groupValue,
                    onChanged: (value) async {
                      if (value != null) {
                        await _setLang(value);
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
                    activeColor: IslamicColors.emeraldGreen,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer', style: TextStyle(color: IslamicColors.emeraldGreen)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLocationDialog() {
    // Rediriger vers l'écran complet des paramètres de prière (localisation + notifications)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrayerSettingsPage()),
    );
  }

  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Objectifs spirituels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGoalTile('Prières quotidiennes', '5/5', Icons.mosque),
              _buildGoalTile('Lecture Coran', '1 page/jour', Icons.menu_book),
              _buildGoalTile('Dhikr quotidien', '100/jour', Icons.favorite),
              _buildGoalTile('Charité hebdomadaire', '1/semaine', Icons.volunteer_activism),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open goals configuration
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Personnaliser', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IslamicColors.emeraldGreen,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: IslamicColors.emeraldGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(String title, String target, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: IslamicColors.emeraldGreen),
      title: Text(title),
      subtitle: Text('Objectif: $target'),
      trailing: Switch(
        value: true,
        onChanged: (value) {},
        activeColor: IslamicColors.emeraldGreen,
      ),
    );
  }

  void _showBackupDialog() {
    Future<bool> _getAutoBackup() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_backup_enabled') ?? true;
    }

    Future<void> _setAutoBackup(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_backup_enabled', value);
    }

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<bool>(
        future: _getAutoBackup(),
        builder: (context, snap) {
          final auto = snap.data ?? true;
          return AlertDialog(
            title: Text(
              'Sauvegarde des données',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: IslamicColors.emeraldGreen),
                  title: const Text('Sauvegarder maintenant'),
                  subtitle: const Text('Créer un point de restauration local'),
                  onTap: () async {
                    try {
                      await BackupService.createAutoBackup();
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sauvegarde locale créée'),
                            backgroundColor: IslamicColors.emeraldGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.sync, color: IslamicColors.emeraldGreen),
                  title: const Text('Sauvegarde automatique'),
                  subtitle: const Text('Sauvegarder quotidiennement'),
                  value: auto,
                  onChanged: (value) async {
                    await _setAutoBackup(value);
                    if (mounted) setState(() {});
                  },
                  activeColor: IslamicColors.emeraldGreen,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer', style: TextStyle(color: IslamicColors.emeraldGreen)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportExportDialog() {
    Future<void> _exportJson() async {
      try {
        final json = await BackupService.exportAllToJson();
        await Clipboard.setData(ClipboardData(text: json));
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Données copiées (JSON)'),
              backgroundColor: IslamicColors.emeraldGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur export: $e')),
          );
        }
      }
    }

    Future<void> _importJsonPrompt() async {
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importer des données (JSON)'),
          content: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '{ "version": 1, "data": { ... } }',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await BackupService.importAllFromJson(controller.text, overwrite: true);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Import terminé'),
                        backgroundColor: IslamicColors.emeraldGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur import: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: IslamicColors.emeraldGreen, foregroundColor: Colors.white),
              child: const Text('Importer'),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Importer/Exporter',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download, color: IslamicColors.emeraldGreen),
              title: const Text('Exporter mes données'),
              subtitle: const Text('Copier au format JSON'),
              onTap: _exportJson,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_upload, color: IslamicColors.mysticBlue),
              title: const Text('Importer des données'),
              subtitle: const Text('Coller un JSON précédemment exporté'),
              onTap: () async {
                Navigator.of(context).pop();
                await _importJsonPrompt();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: TextStyle(color: IslamicColors.emeraldGreen)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Réinitialiser les données',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser toutes vos données ? '
          'Cette action est irréversible et supprimera tous vos hassanat, '
          'badges et progrès.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await StorageService.resetAllData();
              await _loadUserData();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Données réinitialisées avec succès'),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: CircularProgressIndicator(
              color: IslamicColors.emeraldGreen,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                // Account section removed from Spiritual Profile per request
                    _buildProfileHeader(),
                    const SizedBox(height: 30),
                    // Encadré de niveau (ProfileLevelCard) retiré car redondant
                    _buildStatisticsSection(),
                    const SizedBox(height: 30),
                    _buildPersonalizationSection(),
                    const SizedBox(height: 30),
                    _buildActionsSection(),
                    const SizedBox(height: 30),
                    _buildLevelsSection(),
                    const SizedBox(height: 30),
                    _buildSettingsSection(),
                    const SizedBox(height: 30),
                    _buildMotivationalSection(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Account section intentionally removed from Spiritual Profile per product decision

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          IslamicColors.pearlWhite,
          IslamicColors.pearlWhite.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profil Spirituel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ((_user?.name.trim().isNotEmpty == true)
                        ? _user!.name.trim()
                        : (fb_auth.FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
                            ? fb_auth.FirebaseAuth.instance.currentUser!.displayName!.trim()
                            : (fb_auth.FirebaseAuth.instance.currentUser?.email?.split('@').first ?? ''))),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showNameEditDialog,
                icon: const Icon(Icons.edit, size: 20),
                color: IslamicColors.roseGold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: IslamicColors.roseGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _user?.spiritualLevel ?? 'Serviteur dévoué',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: IslamicColors.roseGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // No avatar fallback — photos de profil désactivées

  Widget _buildStatisticsSection() {
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
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hassanat Total',
                  '${_user?.totalHassanat ?? 0}',
                  Icons.stars,
                  IslamicColors.roseGold,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'Série Actuelle',
                  '${_user?.streak ?? 0} jours',
                  Icons.local_fire_department,
                  IslamicColors.emeraldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const PrayerStatsWidget(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelsSection() {
    // Construire une vue synthétique sur le prochain palier via LevelSystem
    final hassanat = _user?.totalHassanat ?? 0;
    final info = LevelSystem.fromHassanat(hassanat);
    final nextLevel = (info.level < LevelSystem.maxLevel) ? info.level + 1 : info.level;
    final nextTarget = (info.level < LevelSystem.maxLevel)
        ? info.level * LevelSystem.xpPerLevel
        : hassanat;

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
          Text(
            'Progression des Niveaux',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.workspace_premium, color: info.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Niveau ${info.level} • ${info.title} (${info.gemstone})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: info.color, fontWeight: FontWeight.w600),
                ),
              ),
              Text('${(info.progress * 100).round()}%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: info.color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: Colors.grey.withValues(alpha: 0.2)),
                  FractionallySizedBox(
                    widthFactor: info.progress,
                    child: Container(
                      decoration: BoxDecoration(gradient: LinearGradient(colors: info.gradient)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prochain: Niveau $nextLevel', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              Text('Objectif: $nextTarget hassanat', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Liste compacte de 5 prochains paliers (aperçu)
          ...List.generate(5, (i) {
            final lvl = (info.level + i).clamp(1, LevelSystem.maxLevel);
            final req = (lvl - 1) * LevelSystem.xpPerLevel;
            final unlocked = hassanat >= req;
            final isCurrent = lvl == info.level;
            return _buildLevelItem('Niveau $lvl', req, unlocked, isCurrent, i == 4);
          }),
        ],
      ),
    );
  }

  Widget _buildLevelItem(String level, int requirement, bool isUnlocked, bool isCurrent, bool isLast) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? (isCurrent ? IslamicColors.roseGold : IslamicColors.emeraldGreen)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? Icons.check_circle : Icons.lock,
                color: isUnlocked ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isUnlocked
                          ? (isCurrent ? IslamicColors.roseGold : IslamicColors.emeraldGreen)
                          : Colors.grey[600],
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    requirement == 0 ? 'Point de départ' : '$requirement hassanat requis',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: IslamicColors.roseGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Actuel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: IslamicColors.roseGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 20),
            width: 2,
            height: 20,
            color: isUnlocked ? IslamicColors.emeraldGreen : Colors.grey[300],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildActionsSection() {
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
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(
              Icons.leaderboard,
              color: IslamicColors.roseGold,
            ),
            title: const Text('Voir le classement'),
            subtitle: const Text('Comparez vos progrès avec d\'autres utilisateurs'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.notifications_active,
              color: IslamicColors.emeraldGreen,
            ),
            title: const Text('Configurer les rappels'),
            subtitle: const Text('Gérez vos rappels spirituels quotidiens'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemindersPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.emoji_events,
              color: IslamicColors.mysticBlue,
            ),
            title: const Text('Mes badges'),
            subtitle: const Text('Consultez tous vos accomplissements'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/badges');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.share,
              color: IslamicColors.emeraldGreen,
            ),
            title: const Text('Partager l\'application'),
            subtitle: const Text('Invitez vos proches à rejoindre Sajda'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => ShareService.shareApp(context, user: _user),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.trending_up,
              color: IslamicColors.mysticBlue,
            ),
            title: const Text('Partager mes progrès'),
            subtitle: const Text('Montrez vos accomplissements spirituels'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _user != null 
                ? () => ShareService.shareProgress(context, _user!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationSection() {
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
          Text(
            'Personnalisation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(
              Icons.palette,
              color: IslamicColors.roseGold,
            ),
            title: const Text('Thème de l\'interface'),
            subtitle: const Text('Personnalisez l\'apparence de l\'app'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showThemeDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.language,
              color: IslamicColors.emeraldGreen,
            ),
            title: const Text('Langue de l\'interface'),
            subtitle: const Text('Français (par défaut)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.location_on,
              color: IslamicColors.mysticBlue,
            ),
            title: const Text('Ma localisation'),
            subtitle: const Text('Pour les heures de prière précises'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLocationDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.schedule,
              color: IslamicColors.dustyRose,
            ),
            title: const Text('Objectifs personnels'),
            subtitle: const Text('Définissez vos objectifs spirituels'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showGoalsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
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
          Text(
            'Paramètres',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Accès direct à l'offre Premium / Abonnement
          ListTile(
            leading: const Icon(
              Icons.diamond,
              color: IslamicColors.roseGold,
            ),
            title: const Text('Sajda Premium'),
            subtitle: const Text('Abonnement, Accès à vie, Essai gratuit 7 jours'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.backup,
              color: IslamicColors.emeraldGreen,
            ),
            title: const Text('Sauvegarde des données'),
            subtitle: const Text('Sauvegardez vos progrès dans le cloud'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showBackupDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.import_export,
              color: IslamicColors.mysticBlue,
            ),
            title: const Text('Importer/Exporter'),
            subtitle: const Text('Gérez vos données personnelles'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showImportExportDialog,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.refresh, color: Colors.red[700]),
            title: Text(
              'Réinitialiser les données',
              style: TextStyle(color: Colors.red[700]),
            ),
            subtitle: const Text('Supprimer tous les progrès et recommencer'),
            onTap: _showResetConfirmDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalSection() {
    final motivationalMessages = [
      'Continuez sur cette voie, chaque action compte dans votre parcours spirituel.',
      'Vos efforts sont vus par Allah. Persévérez dans vos bonnes actions.',
      'Le chemin vers Allah est parsemé de bonnes actions. Vous êtes sur la bonne voie.',
      'Chaque hassanat est une lumière qui éclaire votre chemin vers l\'au-delà.',
    ];

    final message = motivationalMessages[(_user?.totalHassanat ?? 0) % motivationalMessages.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.dustyRose.withValues(alpha: 0.3),
            IslamicColors.softViolet.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: IslamicColors.mysticBlue,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: IslamicColors.mysticBlue,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'BarakAllahu fik!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}