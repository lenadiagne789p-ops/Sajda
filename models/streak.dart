import 'package:flutter/material.dart';

class Streak {
  final String id;
  final String title;
  final String titleArabic;
  final String description;
  final StreakType type;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCompletionDate;
  final List<DateTime> completionHistory;
  final int targetDays;
  final int hassanatReward;
  final IconData icon;
  final Color color;

  Streak({
    required this.id,
    required this.title,
    required this.titleArabic,
    required this.description,
    required this.type,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletionDate,
    this.completionHistory = const [],
    this.targetDays = 7,
    this.hassanatReward = 100,
    required this.icon,
    required this.color,
  });

  Streak copyWith({
    String? id,
    String? title,
    String? titleArabic,
    String? description,
    StreakType? type,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompletionDate,
    List<DateTime>? completionHistory,
    int? targetDays,
    int? hassanatReward,
    IconData? icon,
    Color? color,
  }) {
    return Streak(
      id: id ?? this.id,
      title: title ?? this.title,
      titleArabic: titleArabic ?? this.titleArabic,
      description: description ?? this.description,
      type: type ?? this.type,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      completionHistory: completionHistory ?? this.completionHistory,
      targetDays: targetDays ?? this.targetDays,
      hassanatReward: hassanatReward ?? this.hassanatReward,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  bool get isActive {
    if (lastCompletionDate == null) return false;
    final now = DateTime.now();
    final daysDifference = now.difference(lastCompletionDate!).inDays;
    return daysDifference <= 1; // Allow for timezone differences
  }

  bool get isCompletedToday {
    if (lastCompletionDate == null) return false;
    final today = DateTime.now();
    final lastCompletion = lastCompletionDate!;
    return today.day == lastCompletion.day &&
        today.month == lastCompletion.month &&
        today.year == lastCompletion.year;
  }

  double get progress => targetDays > 0 ? (currentStreak / targetDays).clamp(0.0, 1.0) : 0.0;

  bool get isTargetReached => currentStreak >= targetDays;

  int get daysUntilTarget => (targetDays - currentStreak).clamp(0, targetDays);

  StreakLevel get level {
    if (bestStreak >= 365) return StreakLevel.legendary;
    if (bestStreak >= 180) return StreakLevel.master;
    if (bestStreak >= 90) return StreakLevel.expert;
    if (bestStreak >= 30) return StreakLevel.advanced;
    if (bestStreak >= 7) return StreakLevel.intermediate;
    return StreakLevel.beginner;
  }

  static List<Streak> getDefaultStreaks() {
    return [
      Streak(
        id: 'prayer_streak',
        title: 'Prières à l\'heure',
        titleArabic: 'الصلوات في وقتها',
        description: 'Accomplir les 5 prières quotidiennes à l\'heure',
        type: StreakType.prayer,
        targetDays: 40,
        hassanatReward: 500,
        icon: Icons.schedule,
        color: const Color(0xFF1B5E20),
      ),
      Streak(
        id: 'quran_daily',
        title: 'Lecture quotidienne du Coran',
        titleArabic: 'قراءة القرآن اليومية',
        description: 'Lire au moins une page du Coran chaque jour',
        type: StreakType.quranReading,
        targetDays: 30,
        hassanatReward: 300,
        icon: Icons.menu_book,
        color: const Color(0xFF1A237E),
      ),
      Streak(
        id: 'morning_dhikr',
        title: 'Dhikr matinal',
        titleArabic: 'أذكار الصباح',
        description: 'Réciter les invocations du matin chaque jour',
        type: StreakType.dhikr,
        targetDays: 21,
        hassanatReward: 200,
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB74D),
      ),
      Streak(
        id: 'evening_dhikr',
        title: 'Dhikr du soir',
        titleArabic: 'أذكار المساء',
        description: 'Réciter les invocations du soir chaque jour',
        type: StreakType.dhikr,
        targetDays: 21,
        hassanatReward: 200,
        icon: Icons.nights_stay,
        color: const Color(0xFF3F51B5),
      ),
      Streak(
        id: 'charity_weekly',
        title: 'Aumône hebdomadaire',
        titleArabic: 'الصدقة الأسبوعية',
        description: 'Faire l\'aumône au moins une fois par semaine',
        type: StreakType.charity,
        targetDays: 4,
        hassanatReward: 400,
        icon: Icons.volunteer_activism,
        color: const Color(0xFFE91E63),
      ),
      Streak(
        id: 'sunnah_prayers',
        title: 'Prières surérogatoires',
        titleArabic: 'النوافل',
        description: 'Accomplir les prières surérogatoires quotidiennes',
        type: StreakType.sunnah,
        targetDays: 14,
        hassanatReward: 250,
        icon: Icons.favorite,
        color: const Color(0xFF4CAF50),
      ),
      Streak(
        id: 'good_deed_daily',
        title: 'Bonne action quotidienne',
        titleArabic: 'العمل الطيب اليومي',
        description: 'Accomplir une bonne action chaque jour',
        type: StreakType.goodDeed,
        targetDays: 7,
        hassanatReward: 150,
        icon: Icons.thumb_up,
        color: const Color(0xFF9C27B0),
      ),
      Streak(
        id: 'family_time',
        title: 'Temps en famille',
        titleArabic: 'وقت العائلة',
        description: 'Passer du temps de qualité avec sa famille',
        type: StreakType.family,
        targetDays: 7,
        hassanatReward: 180,
        icon: Icons.family_restroom,
        color: const Color(0xFF795548),
      ),
      // Added more actionable streaks
      Streak(
        id: 'memorize_surah',
        title: 'Mémoriser une sourate',
        titleArabic: 'حفظ سورة',
        description: 'Apprendre par cœur quelques versets chaque jour',
        type: StreakType.quranReading,
        targetDays: 21,
        hassanatReward: 350,
        icon: Icons.psychology,
        color: const Color(0xFF00695C),
      ),
      Streak(
        id: 'istighfar_100',
        title: '100x Istighfar',
        titleArabic: '١٠٠ مرة استغفار',
        description: 'Dire Astaghfirullah 100 fois par jour',
        type: StreakType.worship,
        targetDays: 14,
        hassanatReward: 220,
        icon: Icons.refresh,
        color: const Color(0xFF455A64),
      ),
      Streak(
        id: 'salawat_100',
        title: '100x Salawat',
        titleArabic: '١٠٠ مرة الصلاة على النبي',
        description: 'Envoyer des prières sur le Prophète ﷺ 100 fois',
        type: StreakType.worship,
        targetDays: 14,
        hassanatReward: 240,
        icon: Icons.star,
        color: const Color(0xFFF57F17),
      ),
      Streak(
        id: 'duha_prayer',
        title: 'Prière Duha',
        titleArabic: 'صلاة الضحى',
        description: 'Prier Duha au moins 2 unités',
        type: StreakType.sunnah,
        targetDays: 10,
        hassanatReward: 200,
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF8F00),
      ),
      Streak(
        id: 'visit_sick_weekly',
        title: 'Visiter un malade (hebdo)',
        titleArabic: 'عيادة مريض (أسبوعيًا)',
        description: 'Rendre visite à un malade une fois par semaine',
        type: StreakType.goodDeed,
        targetDays: 4,
        hassanatReward: 420,
        icon: Icons.local_hospital,
        color: const Color(0xFFAD1457),
      ),
      Streak(
        id: 'reconcile_people_weekly',
        title: 'Réconcilier des personnes',
        titleArabic: 'الإصلاح بين الناس',
        description: 'Tenter de réconcilier des gens en conflit',
        type: StreakType.goodDeed,
        targetDays: 4,
        hassanatReward: 500,
        icon: Icons.handshake,
        color: const Color(0xFF5D4037),
      ),
    ];
  }

  Streak incrementStreak() {
    final today = DateTime.now();
    final newHistory = List<DateTime>.from(completionHistory)..add(today);
    final newCurrent = currentStreak + 1;
    final newBest = newCurrent > bestStreak ? newCurrent : bestStreak;

    return copyWith(
      currentStreak: newCurrent,
      bestStreak: newBest,
      lastCompletionDate: today,
      completionHistory: newHistory,
    );
  }

  Streak resetStreak() {
    return copyWith(
      currentStreak: 0,
      lastCompletionDate: null,
    );
  }

  Streak updateForMissedDay() {
    if (lastCompletionDate == null) return this;
    
    final now = DateTime.now();
    final daysSinceLastCompletion = now.difference(lastCompletionDate!).inDays;
    
    if (daysSinceLastCompletion > 1) {
      return resetStreak();
    }
    
    return this;
  }
}

enum StreakType {
  prayer,
  quranReading,
  dhikr,
  charity,
  sunnah,
  goodDeed,
  family,
  worship,
}

enum StreakLevel {
  beginner,
  intermediate, 
  advanced,
  expert,
  master,
  legendary,
}

extension StreakLevelExtension on StreakLevel {
  String get title {
    switch (this) {
      case StreakLevel.beginner:
        return 'Débutant';
      case StreakLevel.intermediate:
        return 'Intermédiaire';
      case StreakLevel.advanced:
        return 'Avancé';
      case StreakLevel.expert:
        return 'Expert';
      case StreakLevel.master:
        return 'Maître';
      case StreakLevel.legendary:
        return 'Légendaire';
    }
  }

  String get titleArabic {
    switch (this) {
      case StreakLevel.beginner:
        return 'مبتدئ';
      case StreakLevel.intermediate:
        return 'متوسط';
      case StreakLevel.advanced:
        return 'متقدم';
      case StreakLevel.expert:
        return 'خبير';
      case StreakLevel.master:
        return 'معلم';
      case StreakLevel.legendary:
        return 'أسطوري';
    }
  }

  Color get color {
    switch (this) {
      case StreakLevel.beginner:
        return const Color(0xFF9E9E9E);
      case StreakLevel.intermediate:
        return const Color(0xFF4CAF50);
      case StreakLevel.advanced:
        return const Color(0xFF2196F3);
      case StreakLevel.expert:
        return const Color(0xFF9C27B0);
      case StreakLevel.master:
        return const Color(0xFFFF9800);
      case StreakLevel.legendary:
        return const Color(0xFFFFD700);
    }
  }

  IconData get icon {
    switch (this) {
      case StreakLevel.beginner:
        return Icons.trending_up;
      case StreakLevel.intermediate:
        return Icons.local_fire_department;
      case StreakLevel.advanced:
        return Icons.flash_on;
      case StreakLevel.expert:
        return Icons.whatshot;
      case StreakLevel.master:
        return Icons.star;
      case StreakLevel.legendary:
        return Icons.diamond;
    }
  }
}