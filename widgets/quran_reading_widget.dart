import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/screens/quran_page.dart';
import 'package:sajda/models/islamic_action.dart';

class QuranReadingWidget extends StatefulWidget {
  final Function(String actionId, int hassanats) onActionCompleted;

  const QuranReadingWidget({
    super.key,
    required this.onActionCompleted,
  });

  @override
  State<QuranReadingWidget> createState() => _QuranReadingWidgetState();
}

class _QuranReadingWidgetState extends State<QuranReadingWidget> {
  bool _isReadingToday = false;
  int _dailyReadingStreak = 0;
  DateTime? _lastReadingDate;

  @override
  void initState() {
    super.initState();
    _loadReadingData();
  }

  Future<void> _loadReadingData() async {
    // Charger les données de lecture du Coran depuis le stockage local
    final readingData = await StorageService.getQuranReadingData();
    setState(() {
      _isReadingToday = readingData['isReadingToday'] ?? false;
      _dailyReadingStreak = readingData['dailyReadingStreak'] ?? 0;
      final lastReading = readingData['lastReadingDate'];
      if (lastReading != null) {
        _lastReadingDate = DateTime.parse(lastReading);
      }
    });
  }

  Future<void> _markQuranRead() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Vérifier si c'est déjà fait aujourd'hui
    if (_isReadingToday) return;

    // Calculer le streak
    int newStreak = 1;
    if (_lastReadingDate != null) {
      final lastDate = DateTime(_lastReadingDate!.year, _lastReadingDate!.month, _lastReadingDate!.day);
      final daysDifference = today.difference(lastDate).inDays;
      
      if (daysDifference == 1) {
        // Streak continue
        newStreak = _dailyReadingStreak + 1;
      } else if (daysDifference > 1) {
        // Streak brisé, recommence
        newStreak = 1;
      }
    }

    // Sauvegarder les données
    await StorageService.setQuranReadingData({
      'isReadingToday': true,
      'dailyReadingStreak': newStreak,
      'lastReadingDate': now.toIso8601String(),
    });

    // Marquer l'action comme complétée et donner les hassanats
    final action = IslamicAction(
      id: 'quran_daily_reading',
      title: 'Lecture quotidienne du Coran',
      arabicTitle: 'قراءة القرآن اليومية',
      description: 'Lire une partie du Saint Coran aujourd\'hui',
      hassanatReward: 20 + (newStreak * 2), // Bonus pour le streak
      type: ActionType.quranReading,
      icon: Icons.menu_book,
    );

    await StorageService.completeAction(action.id);
    widget.onActionCompleted(action.id, action.hassanatReward);

    setState(() {
      _isReadingToday = true;
      _dailyReadingStreak = newStreak;
      _lastReadingDate = now;
    });

    // Montrer un message de félicitations
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mabrouk! +${action.hassanatReward} Hassanats${newStreak > 1 ? ' (Streak: $newStreak jours)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: IslamicColors.emeraldGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book, color: cs.onPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📖 Lecture du Coran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'قراءة القرآن الكريم',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Statistiques de lecture
          if (_dailyReadingStreak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: IslamicColors.roseGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: IslamicColors.roseGold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Streak: $_dailyReadingStreak jour${_dailyReadingStreak > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: IslamicColors.roseGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Description et récompense
          Text(
            'Lisez une partie du Saint Coran aujourd\'hui et gagnez des hassanats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface, height: 1.4),
          ),
          
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Récompense en hassanats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: IslamicColors.emeraldGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${20 + (_dailyReadingStreak * 2)} Hassanats',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statut
              if (_isReadingToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: IslamicColors.emeraldGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Complété',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuranPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.book_outlined),
                  label: const Text('Lire le Coran'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              if (!_isReadingToday)
                ElevatedButton.icon(
                  onPressed: _markQuranRead,
                  icon: const Icon(Icons.check),
                  label: const Text('Marquer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}