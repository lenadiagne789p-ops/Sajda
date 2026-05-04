import 'package:flutter/material.dart';
import 'package:sajda/models/streak.dart';
import 'package:sajda/theme.dart';

enum GrowthChallengeStatus { locked, inProgress, completed }

class GrowthChallenge {
  final String id;
  final StreakLevel stage;
  final String title;
  final String headline;
  final String description;
  final int completionThreshold;
  final List<String> focusAreas;
  final IconData icon;
  final Color startColor;
  final Color endColor;

  const GrowthChallenge({
    required this.id,
    required this.stage,
    required this.title,
    required this.headline,
    required this.description,
    required this.completionThreshold,
    required this.focusAreas,
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  static List<GrowthChallenge> catalog() {
    return const [
      GrowthChallenge(
        id: 'challenge_beginner',
        stage: StreakLevel.beginner,
        title: 'Niveau 1 · Routine',
        headline: '7 jours pour lancer ta routine spirituelle',
        description:
            'Active tes premières habitudes quotidiennes et prends confiance en toi.',
        completionThreshold: 7,
        focusAreas: [
          'Prières à l’heure',
          'Première lecture quotidienne',
          'Invocations matin/soir',
        ],
        icon: Icons.auto_awesome,
        startColor: IslamicColors.emeraldGreen,
        endColor: IslamicColors.emeraldGreen,
      ),
      GrowthChallenge(
        id: 'challenge_intermediate',
        stage: StreakLevel.intermediate,
        title: 'Niveau 2 · Momentum',
        headline: '14 jours pour consolider tes bonnes actions',
        description:
            'Élargis ton cercle d’habitudes et transforme ton élan en discipline.',
        completionThreshold: 14,
        focusAreas: [
          'Sunnah et Duha régulières',
          'Dhikr et istighfar constants',
          'Actes de bienfaisance hebdomadaires',
        ],
        icon: Icons.spa,
        startColor: IslamicColors.roseGold,
        endColor: IslamicColors.roseGold,
      ),
      GrowthChallenge(
        id: 'challenge_advanced',
        stage: StreakLevel.advanced,
        title: 'Niveau 3 · Endurance',
        headline: '21 jours pour élever ta constance',
        description:
            'Tu passes du rythme à la régularité: structure tes journées autour de l’adoration.',
        completionThreshold: 21,
        focusAreas: [
          'Mémorisation quotidienne',
          'Lecture ciblée du Coran',
          'Engagement communautaire',
        ],
        icon: Icons.local_fire_department,
        startColor: IslamicColors.mysticBlue,
        endColor: IslamicColors.mysticBlue,
      ),
      GrowthChallenge(
        id: 'challenge_expert',
        stage: StreakLevel.expert,
        title: 'Niveau 4 · Transformation',
        headline: '30 jours pour devenir la meilleure version de toi-même',
        description:
            'Ancre des habitudes profondes et aligne chaque journée avec ton intention.',
        completionThreshold: 30,
        focusAreas: [
          'Suivi complet des prières',
          'Révision du Coran avec tajwid',
          'Service et soutien des proches',
        ],
        icon: Icons.diamond,
        startColor: const Color(0xFF6236FF),
        endColor: const Color(0xFFB620E0),
      ),
      GrowthChallenge(
        id: 'challenge_master',
        stage: StreakLevel.master,
        title: 'Niveau 5 · Maîtrise',
        headline: '60 jours de discipline inspirante',
        description:
            'Tu inspires les autres: maintiens un rythme d’excellence stable et serein.',
        completionThreshold: 60,
        focusAreas: [
          'Mentorat et partage de connaissances',
          'Cycles de révision du Coran',
          'Aumônes planifiées',
        ],
        icon: Icons.workspace_premium,
        startColor: const Color(0xFFF57C00),
        endColor: const Color(0xFFFFB300),
      ),
      GrowthChallenge(
        id: 'challenge_legendary',
        stage: StreakLevel.legendary,
        title: 'Niveau 6 · Héritage',
        headline: '90 jours pour laisser une empreinte spirituelle durable',
        description:
            'Ta constance devient un héritage: structure une vie entière tournée vers Allah.',
        completionThreshold: 90,
        focusAreas: [
          'Projets de sadaqa jariyah',
          'Parrainage et transmission',
          'Retraites spirituelles régulières',
        ],
        icon: Icons.auto_fix_high,
        startColor: const Color(0xFFFFD700),
        endColor: const Color(0xFFFFF59D),
      ),
    ];
  }

  double progress(int bestStreak) {
    if (completionThreshold == 0) return 0;
    return (bestStreak / completionThreshold).clamp(0.0, 1.0);
  }

  static GrowthChallengeStatus statusFor({
    required int bestStreak,
    required int index,
    required List<GrowthChallenge> orderedChallenges,
  }) {
    final challenge = orderedChallenges[index];
    if (bestStreak >= challenge.completionThreshold) {
      return GrowthChallengeStatus.completed;
    }

    final previousCompleted = index == 0
        ? true
        : bestStreak >= orderedChallenges[index - 1].completionThreshold;

    return previousCompleted
        ? GrowthChallengeStatus.inProgress
        : GrowthChallengeStatus.locked;
  }
}