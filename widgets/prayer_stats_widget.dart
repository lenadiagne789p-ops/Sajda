import 'package:flutter/material.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/theme.dart';

/// Widget affichant les statistiques de prières sur les 7 derniers jours.
/// En l'absence de données réelles, des données de démonstration sont utilisées.
class PrayerStatsWidget extends StatefulWidget {
  const PrayerStatsWidget({super.key});

  @override
  State<PrayerStatsWidget> createState() => _PrayerStatsWidgetState();
}

class _PrayerStatsWidgetState extends State<PrayerStatsWidget>
    with SingleTickerProviderStateMixin {
  static const List<String> _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const List<String> _prayerLabels = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const List<String> _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  /// Données de démonstration réalistes sur 7 jours
  static final List<Map<String, bool>> _demoData = [
    // J-6 : Lundi — 4/5 prières
    {'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': false},
    // J-5 : Mardi — 5/5
    {'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true},
    // J-4 : Mercredi — 3/5
    {'fajr': false, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': false},
    // J-3 : Jeudi — 5/5
    {'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true},
    // J-2 : Vendredi — 5/5
    {'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true},
    // J-1 : Samedi — 2/5
    {'fajr': false, 'dhuhr': false, 'asr': true, 'maghrib': true, 'isha': false},
    // Aujourd'hui : Dimanche — 3/5 (en cours)
    {'fajr': true, 'dhuhr': true, 'asr': false, 'maghrib': true, 'isha': false},
  ];

  List<Map<String, bool>> _weekData = [];
  bool _isLoading = true;
  bool _isDemo = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadWeekData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadWeekData() async {
    final today = DateTime.now();
    final List<Map<String, bool>> data = [];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final prayerMap = await StorageService.getPrayerDoneForDate(day);
      data.add(prayerMap);
    }

    // Vérifier si les données réelles sont vides → utiliser la démo
    final hasRealData = data.any((d) => d.values.any((v) => v));

    if (mounted) {
      setState(() {
        if (hasRealData) {
          _weekData = data;
          _isDemo = false;
        } else {
          _weekData = _demoData;
          _isDemo = true;
        }
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  int get _totalDone {
    int count = 0;
    for (final day in _weekData) {
      for (final p in _prayers) {
        if (day[p] == true) count++;
      }
    }
    return count;
  }

  double get _percentage => _weekData.isEmpty ? 0 : _totalDone / (7 * 5);

  String get _motivationText {
    final pct = _percentage;
    if (pct >= 0.95) return 'Exceptionnel ! Continuez sur cette lancée !';
    if (pct >= 0.8) return 'Très bien ! Vous êtes sur la bonne voie.';
    if (pct >= 0.6) return 'Bon effort ! Essayez de ne manquer aucune prière.';
    if (pct >= 0.4) return 'Courage ! Chaque prière compte.';
    return 'Commencez dès maintenant, Allah est Miséricordieux.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec badge démo
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: IslamicColors.emeraldGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assiduité des prières — 7 jours',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: IslamicColors.emeraldGreen,
                  ),
                ),
              ),
              if (_isDemo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Démo',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_percentage * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (_isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                'Données de démonstration — priez pour voir vos vraies statistiques',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Graphique en barres verticales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (dayIndex) {
              final dayData = _weekData[dayIndex];
              final doneCount =
                  _prayers.where((p) => dayData[p] == true).length;
              final isToday = dayIndex == 6;
              return _buildDayColumn(
                theme: theme,
                dayLabel: _getDayLabel(dayIndex),
                doneCount: doneCount,
                isToday: isToday,
                dayData: dayData,
              );
            }),
          ),

          const SizedBox(height: 18),

          // Légende des prières avec couleurs
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: List.generate(_prayers.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _prayerColor(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _prayerLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // Barre de progression globale animée
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _percentage),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 0.8
                      ? IslamicColors.emeraldGreen
                      : value >= 0.5
                          ? IslamicColors.roseGold
                          : Colors.redAccent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalDone / ${7 * 5} prières cette semaine',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              Text(
                _motivationText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tableau récapitulatif par prière
          _buildPrayerSummaryTable(theme),
        ],
      ),
    );
  }

  Widget _buildDayColumn({
    required ThemeData theme,
    required String dayLabel,
    required int doneCount,
    required bool isToday,
    required Map<String, bool> dayData,
  }) {
    const double maxBarHeight = 90;
    final barHeight = (doneCount / 5) * maxBarHeight;

    return Column(
      children: [
        // Score du jour
        Text(
          '$doneCount/5',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday
                ? IslamicColors.emeraldGreen
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        // Barre verticale avec points de prière
        SizedBox(
          height: maxBarHeight,
          width: 30,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Fond
              Container(
                width: 12,
                height: maxBarHeight,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Remplissage animé
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: barHeight),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, h, _) => Container(
                  width: 12,
                  height: h.clamp(0.0, maxBarHeight),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        IslamicColors.emeraldGreen,
                        IslamicColors.emeraldGreen.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Points colorés par prière
              ...List.generate(_prayers.length, (i) {
                final done = dayData[_prayers[i]] == true;
                final spacing = maxBarHeight / (_prayers.length + 1);
                final dotBottom = spacing * (i + 1) - 4;
                return Positioned(
                  bottom: dotBottom,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: done
                          ? _prayerColor(i)
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? _prayerColor(i).withValues(alpha: 0.6)
                            : theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: done
                          ? [
                              BoxShadow(
                                color: _prayerColor(i).withValues(alpha: 0.4),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Label du jour (cercle pour aujourd'hui)
        Container(
          width: 24,
          height: 24,
          decoration: isToday
              ? BoxDecoration(
                  color: IslamicColors.emeraldGreen,
                  shape: BoxShape.circle,
                )
              : null,
          child: Center(
            child: Text(
              dayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isToday
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tableau récapitulatif : pour chaque prière, combien de jours accomplie sur 7
  Widget _buildPrayerSummaryTable(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif par prière',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_prayers.length, (i) {
            final prayerKey = _prayers[i];
            final doneCount =
                _weekData.where((d) => d[prayerKey] == true).length;
            final ratio = doneCount / 7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _prayerColor(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      _prayerLabels[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _prayerColor(i)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$doneCount/7',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _prayerColor(i),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getDayLabel(int dayIndex) {
    final today = DateTime.now();
    final day = today.subtract(Duration(days: 6 - dayIndex));
    return _dayLabels[day.weekday - 1];
  }

  Color _prayerColor(int index) {
    const colors = [
      Color(0xFF6C63FF), // Fajr — violet
      Color(0xFF4CAF50), // Dhuhr — vert
      Color(0xFFFF9800), // Asr — orange
      Color(0xFFE91E63), // Maghrib — rose
      Color(0xFF2196F3), // Isha — bleu
    ];
    return colors[index % colors.length];
  }
}
