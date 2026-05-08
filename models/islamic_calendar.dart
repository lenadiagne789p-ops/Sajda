import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;
  final String monthNameArabic;

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthNameArabic,
  });

  static HijriDate fromDateTime(DateTime dateTime) {
    // Accurate civil conversion using Umm al-Qura via hijri package
    final h = HijriCalendar.fromDate(dateTime);
    final hijriDay = h.hDay;
    final hijriMonth = h.hMonth;
    final hijriYear = h.hYear;

    return HijriDate(
      day: hijriDay,
      month: hijriMonth,
      year: hijriYear,
      monthName: _getMonthName(hijriMonth),
      monthNameArabic: _getMonthNameArabic(hijriMonth),
    );
  }

  /// Convenience factory to build a HijriDate from day/month/year
  /// while automatically deriving localized month names.
  static HijriDate of({
    required int day,
    required int month,
    required int year,
  }) {
    return HijriDate(
      day: day,
      month: month,
      year: year,
      monthName: _getMonthName(month),
      monthNameArabic: _getMonthNameArabic(month),
    );
  }

  static String _getMonthName(int month) {
    const names = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani',
      'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    return names[(month - 1) % 12];
  }

  static String _getMonthNameArabic(int month) {
    const names = [
      'مُحَرَّم', 'صَفَر', 'رَبِيع الأَوَّل', 'رَبِيع الثَّانِي',
      'جُمَادَى الأُولَى', 'جُمَادَى الآخِرَة', 'رَجَب', 'شَعْبَان',
      'رَمَضَان', 'شَوَّال', 'ذُو القِعْدَة', 'ذُو الحِجَّة'
    ];
    return names[(month - 1) % 12];
  }

  @override
  String toString() => '$day $monthName $year H';
  String toArabicString() => '$day $monthNameArabic ${_toArabicNumerals(year)} هـ';

  /// Returns the Gregorian DateTime corresponding to this Hijri date.
  ///
  /// Strategy: start from a fast astronomical approximation, then adjust by
  /// comparing against HijriCalendar.fromDate until the exact civil date is found.
  DateTime toApproxGregorianDate() {
    // 1) Fast initial approximation (same formula we used previously)
    final base = DateTime(622, 7, 16);
    final approxDays = (((year - 1) * 354.37) + ((month - 1) * 29.5) + (day - 1)).round();
    DateTime guess = base.add(Duration(days: approxDays));

    // 2) Refine by walking day by day to match Umm al-Qura civil date
    final targetY = year, targetM = month, targetD = day;
    const int maxSteps = 80; // safety bound (~2.5 months)
    for (int i = 0; i < maxSteps; i++) {
      final h = HijriCalendar.fromDate(guess);
      final y = h.hYear, m = h.hMonth, d = h.hDay;
      if (y == targetY && m == targetM && d == targetD) {
        return guess;
      }
      // Determine direction: if current hijri date is before target, move forward
      final beforeTarget = (y < targetY) || (y == targetY && (m < targetM || (m == targetM && d < targetD)));
      guess = beforeTarget ? guess.add(const Duration(days: 1)) : guess.subtract(const Duration(days: 1));
    }
    // Fallback: return best guess if not matched within bounds
    return guess;
  }

  /// Returns a simple dd/MM/yyyy string for the approximate Gregorian date.
  String toGregorianString() {
    final d = toApproxGregorianDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static String _toArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      return arabicNumerals[int.parse(digit)];
    }).join('');
  }
}

class IslamicEvent {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final String occurrence;
  final HijriDate date;
  final IslamicEventType type;
  final int specialHassanatMultiplier;
  final IconData icon;
  final Color color;
  final List<String> recommendedActions;
  final List<String> benefits;

  IslamicEvent({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.occurrence,
    required this.date,
    required this.type,
    this.specialHassanatMultiplier = 1,
    required this.icon,
    required this.color,
    this.recommendedActions = const [],
    this.benefits = const [],
  });

  static List<IslamicEvent> getAnnualEvents() {
    // Generate events dynamically for the current Hijri year and the next one,
    // so the Gregorian dates shown are up-to-date (covers 2025–2026 and beyond).
    final currentHijriYear = HijriDate.fromDateTime(DateTime.now()).year;
    final events = <IslamicEvent>[
      ..._buildForHijriYear(currentHijriYear),
      ..._buildForHijriYear(currentHijriYear + 1),
    ];

    return events;
  }

  /// Generate all supported events for a specific Hijri year.
  static List<IslamicEvent> _buildForHijriYear(int year) {
    return [
      IslamicEvent(
        id: 'muharram_1',
        name: 'Nouvel An Islamique',
        nameArabic: 'رأس السنة الهجرية',
        description: 'Premier jour de l\'année hijri, moment privilégié pour prendre de bonnes résolutions spirituelles.',
        occurrence: '1er Muharram',
        date: HijriDate.of(day: 1, month: 1, year: year),
        type: IslamicEventType.specialSeason,
        specialHassanatMultiplier: 2,
        icon: Icons.celebration,
        color: const Color(0xFF1B5E20),
        recommendedActions: ['Faire du dhikr', 'Lire le Coran', 'Faire des du\'a'],
        benefits: [
          'Renouveler son intention et ses objectifs spirituels pour la nouvelle année hijri.',
          'Multiplier les invocations et les salawat sur le Prophète ﷺ.',
        ],
      ),
      IslamicEvent(
        id: 'ashura',
        name: 'Jour d\'Ashura',
        nameArabic: 'يوم عاشوراء',
        description: 'Dixième jour de Muharram, jour de jeûne recommandée en souvenir du salut de Musa (AS).',
        occurrence: '10 Muharram',
        date: HijriDate.of(day: 10, month: 1, year: year),
        type: IslamicEventType.recommendedFast,
        specialHassanatMultiplier: 10,
        icon: Icons.dining,
        color: const Color(0xFF673AB7),
        recommendedActions: ['Jeûner', 'Faire du dhikr', 'Lire l\'histoire de Musa (AS)'],
        benefits: [
          'Efface les péchés de l\'année précédente selon la tradition prophétique.',
          'Renforce la gratitude envers Allah pour Ses bienfaits et Ses délivrances.',
        ],
      ),
      IslamicEvent(
        id: 'mawlid',
        name: 'Mawlid an-Nabawi',
        nameArabic: 'المولد النبوي الشريف',
        description: 'Commémoration de la naissance du Prophète Muhammad ﷺ, opportunité pour se rapprocher de sa Sunnah.',
        occurrence: '12 Rabi\' al-Awwal',
        date: HijriDate.of(day: 12, month: 3, year: year),
        type: IslamicEventType.commemoration,
        specialHassanatMultiplier: 5,
        icon: Icons.star_border,
        color: const Color(0xFFD4AF37),
        recommendedActions: ['Réciter des salawat', 'Lire la sira', 'Faire des invocations'],
        benefits: [
          'Ravive l\'amour du Prophète ﷺ et la volonté de suivre sa voie.',
          'Encourage l\'étude de la sirah et la transmission de ses enseignements.',
        ],
      ),
      IslamicEvent(
        id: 'laylat_miraj',
        name: 'Laylat al-Mi\'raj',
        nameArabic: 'ليلة الإسراء والمعراج',
        description: 'Nuit du voyage nocturne et de l\'ascension du Prophète ﷺ, rappel de l\'importance de la Salat.',
        occurrence: '27 Rajab',
        date: HijriDate.of(day: 27, month: 7, year: year),
        type: IslamicEventType.sacredNight,
        specialHassanatMultiplier: 7,
        icon: Icons.nights_stay,
        color: const Color(0xFF1A237E),
        recommendedActions: ['Prier la nuit', 'Lire le Coran', 'Faire du dhikr'],
        benefits: [
          'Renforce la relation avec la prière obligatoire et les prières nocturnes.',
          'Occasion de méditer sur le miracle d\'Isra et Mi\'raj et ses enseignements.',
        ],
      ),
      IslamicEvent(
        id: 'laylat_nisf_shaban',
        name: 'Laylat Nisf Sha\'ban',
        nameArabic: 'ليلة النصف من شعبان',
        description: 'Nuit du milieu de Sha\'ban, nuit de pardon et de miséricorde.',
        occurrence: '15 Sha\'ban (nuit)',
        date: HijriDate.of(day: 15, month: 8, year: year),
        type: IslamicEventType.sacredNight,
        specialHassanatMultiplier: 5,
        icon: Icons.auto_awesome,
        color: const Color(0xFF9C27B0),
        recommendedActions: ['Demander pardon', 'Faire des du\'a', 'Prier la nuit'],
        benefits: [
          'Moment pour purifier son cœur et demander le pardon d\'Allah.',
          'Prépare spirituellement à l\'arrivée du Ramadan.',
        ],
      ),
      IslamicEvent(
        id: 'fast_shaban',
        name: 'Jeûne de mi-Sha\'ban',
        nameArabic: 'صيام منتصف شعبان',
        description: 'Jeûne recommandé autour du 15 Sha\'ban pour augmenter ses œuvres avant Ramadan.',
        occurrence: '13, 14 et 15 Sha\'ban',
        date: HijriDate.of(day: 13, month: 8, year: year),
        type: IslamicEventType.recommendedFast,
        specialHassanatMultiplier: 6,
        icon: Icons.self_improvement,
        color: const Color(0xFF7B1FA2),
        recommendedActions: ['Jeûner les jours blancs', 'Multiplier les invocations', 'Donner en aumône'],
        benefits: [
          'Prépare le corps et le cœur au jeûne du mois de Ramadan.',
          'Augmente les bonnes actions alors que les registres sont élevés vers Allah.',
        ],
      ),
      IslamicEvent(
        id: 'ramadan_start',
        name: 'Début du Ramadan',
        nameArabic: 'بداية شهر رمضان المبارك',
        description: 'Premier jour du mois béni du Ramadan, période de jeûne obligatoire, de recueillement et de charité.',
        occurrence: '1er Ramadan (durée : 29 ou 30 jours)',
        date: HijriDate.of(day: 1, month: 9, year: year),
        type: IslamicEventType.obligatoryFast,
        specialHassanatMultiplier: 70,
        icon: Icons.brightness_3,
        color: const Color(0xFF4CAF50),
        recommendedActions: ['Jeûner', 'Lire le Coran', 'Faire l\'aumône', 'Prier Tarawih'],
        benefits: [
          'Piliers de l\'Islam : purifier l\'âme et développer la taqwa.',
          'Multiplier les récompenses via la lecture du Coran et les actes de charité.',
        ],
      ),
      IslamicEvent(
        id: 'laylat_qadr',
        name: 'Laylat al-Qadr',
        nameArabic: 'ليلة القدر',
        description: 'Nuit du Destin, meilleure que mille mois, où le Coran a été révélé.',
        occurrence: 'Les nuits impaires des 10 derniers jours de Ramadan',
        date: HijriDate.of(day: 27, month: 9, year: year),
        type: IslamicEventType.sacredNight,
        specialHassanatMultiplier: 1000,
        icon: Icons.diamond,
        color: const Color(0xFFFFD700),
        recommendedActions: ['Prier toute la nuit', 'Lire le Coran', 'Faire du dhikr', 'Demander pardon'],
        benefits: [
          'Période où les actes d\'adoration sont équivalents à plus de 83 années.',
          'Occasion unique d\'obtenir le pardon total d\'Allah.',
        ],
      ),
      IslamicEvent(
        id: 'eid_fitr',
        name: 'Eid al-Fitr',
        nameArabic: 'عيد الفطر المبارك',
        description: 'Fête de la rupture du jeûne, moment de gratitude après Ramadan.',
        occurrence: '1er Shawwal',
        date: HijriDate.of(day: 1, month: 10, year: year),
        type: IslamicEventType.festival,
        specialHassanatMultiplier: 10,
        icon: Icons.celebration,
        color: const Color(0xFF4CAF50),
        recommendedActions: ['Prière de l\'Eid', 'Faire l\'aumône', 'Visiter la famille', 'Féliciter les musulmans'],
        benefits: [
          'Renforce la fraternité et la gratitude collective.',
          'Encourage la générosité via la zakat al-fitr et le partage.',
        ],
      ),
      IslamicEvent(
        id: 'shawwal_fast',
        name: 'Jeûne des 6 jours de Shawwal',
        nameArabic: 'صيام ستة أيام من شوال',
        description: 'Jeûne recommandé de six jours après Eid al-Fitr pour compléter l\'année.',
        occurrence: 'Du 2 au 29 Shawwal (6 jours au choix après l\'Eid)',
        date: HijriDate.of(day: 2, month: 10, year: year),
        type: IslamicEventType.recommendedFast,
        specialHassanatMultiplier: 12,
        icon: Icons.local_florist,
        color: const Color(0xFF009688),
        recommendedActions: ['Jeûner six jours séparés ou consécutifs', 'Rester constant dans le dhikr', 'Multiplier les invocations'],
        benefits: [
          'Récompense équivalente à un jeûne continu de toute une année.',
          'Permet de garder le rythme spirituel acquis durant Ramadan.',
        ],
      ),
      IslamicEvent(
        id: 'hajj_start',
        name: 'Début du Hajj',
        nameArabic: 'بداية موسم الحج',
        description: 'Début des dix premiers jours de Dhul-Hijjah, jours les plus aimés d\'Allah.',
        occurrence: '1er Dhul-Hijjah',
        date: HijriDate.of(day: 1, month: 12, year: year),
        type: IslamicEventType.specialSeason,
        specialHassanatMultiplier: 10,
        icon: Icons.foundation,
        color: const Color(0xFF1B5E20),
        recommendedActions: ['Jeûner les 9 premiers jours', 'Faire du dhikr', 'Faire l\'aumône'],
        benefits: [
          'Les jours les plus aimés d\'Allah pour les œuvres pieuses.',
          'Prépare au jour d\'Arafat et à la célébration de l\'Eid al-Adha.',
        ],
      ),
      IslamicEvent(
        id: 'arafat',
        name: 'Jour d\'Arafat',
        nameArabic: 'يوم عرفة',
        description: 'Neuvième jour de Dhul-Hijjah, sommet du pèlerinage et jour de jeûne recommandé.',
        occurrence: '9 Dhul-Hijjah',
        date: HijriDate.of(day: 9, month: 12, year: year),
        type: IslamicEventType.recommendedFast,
        specialHassanatMultiplier: 100,
        icon: Icons.landscape,
        color: const Color(0xFF795548),
        recommendedActions: ['Jeûner', 'Faire du du\'a', 'Demander pardon', 'Lire le Coran'],
        benefits: [
          'Efface les péchés de l\'année précédente et de l\'année suivante.',
          'Jour où Allah affranchit des foules du feu et exauce les invocations.',
        ],
      ),
      IslamicEvent(
        id: 'eid_adha',
        name: 'Eid al-Adha',
        nameArabic: 'عيد الأضحى المبارك',
        description: 'Fête du sacrifice en commémoration de la soumission d\'Ibrahim (AS).',
        occurrence: '10 Dhul-Hijjah',
        date: HijriDate.of(day: 10, month: 12, year: year),
        type: IslamicEventType.festival,
        specialHassanatMultiplier: 10,
        icon: Icons.celebration,
        color: const Color(0xFFFF5722),
        recommendedActions: ['Prière de l\'Eid', 'Sacrifier si possible', 'Partager avec les nécessiteux'],
        benefits: [
          'Renforce la fraternité via le partage de la viande du sacrifice.',
          'Rappelle la soumission totale à Allah et la confiance absolue.',
        ],
      ),
    ];
  }

  bool isToday() {
    final today = HijriDate.fromDateTime(DateTime.now());
    return date.day == today.day && date.month == today.month && date.year == today.year;
  }

  bool isThisWeek() {
    final now = DateTime.now();
    final greg = date.toApproxGregorianDate();
    final diff = greg.difference(now).inDays;
    return diff >= 0 && diff <= 7;
  }
}

enum IslamicEventType {
  festival,
  obligatoryFast,
  recommendedFast,
  sacredNight,
  specialSeason,
  commemoration,
}