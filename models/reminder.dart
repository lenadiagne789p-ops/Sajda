import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final String message;
  final String arabicMessage;
  final TimeOfDay time;
  final List<int> days; // 1-7 pour lundi-dimanche
  final bool isActive;
  final ReminderType type;
  final String? actionId;

  Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.arabicMessage,
    required this.time,
    required this.days,
    this.isActive = true,
    required this.type,
    this.actionId,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? message,
    String? arabicMessage,
    TimeOfDay? time,
    List<int>? days,
    bool? isActive,
    ReminderType? type,
    String? actionId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      arabicMessage: arabicMessage ?? this.arabicMessage,
      time: time ?? this.time,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      actionId: actionId ?? this.actionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'arabicMessage': arabicMessage,
      'hour': time.hour,
      'minute': time.minute,
      'days': days,
      'isActive': isActive,
      'type': type.index,
      'actionId': actionId,
    };
  }

  static Reminder fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      arabicMessage: json['arabicMessage'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      days: List<int>.from(json['days']),
      isActive: json['isActive'],
      type: ReminderType.values[json['type']],
      actionId: json['actionId'],
    );
  }

  static List<Reminder> getDefaultReminders() {
    return [
      Reminder(
        id: 'fajr_reminder',
        title: 'Prière du Fajr',
        message: 'Il est l\'heure de prier Fajr, commencez votre journée avec Allah',
        arabicMessage: 'حان وقت صلاة الفجر، ابدأ يومك مع الله',
        time: const TimeOfDay(hour: 5, minute: 30),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.prayer,
      ),
      Reminder(
        id: 'dhikr_morning',
        title: 'Dhikr du Matin',
        message: 'Récitez vos adhkar du matin pour une journée bénie',
        arabicMessage: 'اقرأ أذكار الصباح ليوم مبارك',
        time: const TimeOfDay(hour: 7, minute: 0),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.dhikr,
      ),
      Reminder(
        id: 'dhuhr_reminder',
        title: 'Prière du Dhuhr',
        message: 'Pause dans vos activités pour prier Dhuhr',
        arabicMessage: 'توقف عن أعمالك لصلاة الظهر',
        time: const TimeOfDay(hour: 13, minute: 0),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.prayer,
      ),
      Reminder(
        id: 'asr_reminder',
        title: 'Prière du Asr',
        message: 'Il est temps de prier Asr avant le coucher du soleil',
        arabicMessage: 'حان وقت صلاة العصر قبل غروب الشمس',
        time: const TimeOfDay(hour: 16, minute: 30),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.prayer,
      ),
      Reminder(
        id: 'maghrib_reminder',
        title: 'Prière du Maghrib',
        message: 'Le soleil se couche, il est temps de prier Maghrib',
        arabicMessage: 'غربت الشمس، حان وقت صلاة المغرب',
        time: const TimeOfDay(hour: 18, minute: 45),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.prayer,
      ),
      Reminder(
        id: 'dhikr_evening',
        title: 'Dhikr du Soir',
        message: 'Récitez vos adhkar du soir pour une nuit protégée',
        arabicMessage: 'اقرأ أذكار المساء لليلة محفوظة',
        time: const TimeOfDay(hour: 19, minute: 30),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.dhikr,
      ),
      Reminder(
        id: 'isha_reminder',
        title: 'Prière du Isha',
        message: 'Terminez votre journée par la prière Isha',
        arabicMessage: 'اختتم يومك بصلاة العشاء',
        time: const TimeOfDay(hour: 20, minute: 30),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.prayer,
      ),
      Reminder(
        id: 'quran_daily',
        title: 'Lecture du Coran',
        message: 'Prenez quelques minutes pour lire le Coran',
        arabicMessage: 'خذ بعض الوقت لقراءة القرآن',
        time: const TimeOfDay(hour: 21, minute: 0),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.quran,
      ),
      Reminder(
        id: 'charity_weekly',
        title: 'Acte de Charité',
        message: 'Faites un acte de charité pour purifier votre cœur',
        arabicMessage: 'قم بعمل خيري لتطهير قلبك',
        time: const TimeOfDay(hour: 14, minute: 0),
        days: [5], // Vendredi
        type: ReminderType.charity,
      ),
      Reminder(
        id: 'istighfar_night',
        title: 'Istighfar',
        message: 'Demandez pardon à Allah avant de dormir',
        arabicMessage: 'استغفر الله قبل النوم',
        time: const TimeOfDay(hour: 22, minute: 0),
        days: [1, 2, 3, 4, 5, 6, 7],
        type: ReminderType.repentance,
      ),
    ];
  }
}

enum ReminderType {
  prayer,
  dhikr,
  quran,
  charity,
  repentance,
  general,
  custom,
}

extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.prayer:
        return 'Prière';
      case ReminderType.dhikr:
        return 'Dhikr';
      case ReminderType.quran:
        return 'Coran';
      case ReminderType.charity:
        return 'Charité';
      case ReminderType.repentance:
        return 'Repentir';
      case ReminderType.general:
        return 'Général';
      case ReminderType.custom:
        return 'Personnalisé';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.prayer:
        return Icons.mosque;
      case ReminderType.dhikr:
        return Icons.favorite;
      case ReminderType.quran:
        return Icons.menu_book;
      case ReminderType.charity:
        return Icons.volunteer_activism;
      case ReminderType.repentance:
        return Icons.favorite_border;
      case ReminderType.general:
        return Icons.notifications;
      case ReminderType.custom:
        return Icons.settings;
    }
  }

  Color get color {
    switch (this) {
      case ReminderType.prayer:
        return const Color(0xFF1B5E20);
      case ReminderType.dhikr:
        return const Color(0xFFE91E63);
      case ReminderType.quran:
        return const Color(0xFF2E7D32);
      case ReminderType.charity:
        return const Color(0xFF9C27B0);
      case ReminderType.repentance:
        return const Color(0xFFFF7043);
      case ReminderType.general:
        return const Color(0xFF616161);
      case ReminderType.custom:
        return const Color(0xFF795548);
    }
  }
}