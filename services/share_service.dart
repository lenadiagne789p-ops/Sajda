import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/models/user.dart';
import 'package:sajda/theme.dart';

class ShareService {
  static const String appName = 'Sajda - Votre Parcours Spirituel';
  static const String appDescription = 'Gagnez des hassanat par des actions islamiques : dons, récitations du Coran, dhikr et bien plus encore!';
  static const String appUrl = 'https://play.google.com/store/apps/details?id=com.sajda.app'; // URL fictive
  
  /// Partage l'application avec un message personnalisé
  static Future<void> shareApp(BuildContext context, {User? user}) async {
    try {
      final message = _buildShareMessage(user);
      
      // Simuler le partage (en production, utilisez share_plus)
      await Clipboard.setData(ClipboardData(text: message));
      
      if (context.mounted) {
        _showShareDialog(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  /// Partage les statistiques de l'utilisateur
  static Future<void> shareProgress(BuildContext context, User user) async {
    try {
      final message = _buildProgressMessage(user);
      
      // Simuler le partage
      await Clipboard.setData(ClipboardData(text: message));
      
      if (context.mounted) {
        _showShareDialog(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  /// Partage un accomplissement spécifique
  static Future<void> shareAchievement(
    BuildContext context, 
    String achievement, 
    User user,
  ) async {
    try {
      final message = _buildAchievementMessage(achievement, user);
      
      // Simuler le partage
      await Clipboard.setData(ClipboardData(text: message));
      
      if (context.mounted) {
        _showShareDialog(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  static String _buildShareMessage(User? user) {
    String userPart = '';
    if (user != null) {
      userPart = 'Je progresse dans mon parcours spirituel avec ${user.totalHassanat} hassanat gagnées!\n\n';
    }
    
    return '''🌟 $userPart$appDescription

📱 Téléchargez $appName et rejoignez-moi dans ce parcours spirituel enrichissant!

$appUrl

#Sajda #Islam #SpiritualGrowth #Hassanat''';
  }

  static String _buildProgressMessage(User user) {
    return '''🌟 Mes progrès spirituels sur Sajda:

✨ ${user.totalHassanat} hassanat gagnées
🔥 ${user.streak} jours de série
🏆 Niveau: ${user.spiritualLevel}

Rejoignez-moi dans ce parcours spirituel enrichissant!

📱 $appName
$appUrl

#Sajda #Islam #Progress #Hassanat''';
  }

  static String _buildAchievementMessage(String achievement, User user) {
    return '''🏆 Nouvel accomplissement débloqué!

$achievement

Mon parcours spirituel:
✨ ${user.totalHassanat} hassanat
🏆 ${user.spiritualLevel}

Rejoignez-moi sur Sajda!

📱 $appName
$appUrl

#Sajda #Achievement #Islam #Hassanat''';
  }

  static void _showShareDialog(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(message: message),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String message;

  const _ShareBottomSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec bouton de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              // Indicateur de glissement
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Bouton fermer
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text(
            'Partager avec',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Options de partage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareButton(
                icon: Icons.message,
                label: 'SMS',
                color: Colors.green,
                onTap: () => _shareViaSMS(context),
              ),
              _ShareButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.blue,
                onTap: () => _shareViaEmail(context),
              ),
              _ShareButton(
                icon: Icons.copy,
                label: 'Copier',
                color: IslamicColors.emeraldGreen,
                onTap: () => _copyToClipboard(context),
              ),
              _ShareButton(
                icon: Icons.more_horiz,
                label: 'Plus',
                color: Colors.orange,
                onTap: () => _shareViaOther(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Aperçu du message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: IslamicColors.pearlWhite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _shareViaSMS(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié! Ouvrez votre app SMS pour partager.'),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
  }

  void _shareViaEmail(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié! Ouvrez votre app Email pour partager.'),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié dans le presse-papiers!'),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
  }

  void _shareViaOther(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié! Utilisez votre app de partage préférée.'),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}