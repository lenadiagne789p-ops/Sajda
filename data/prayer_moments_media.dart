import 'package:flutter/material.dart';

class PrayerMomentsMedia {
  // Base curated assets
  static const String fajr = 'assets/images/mosque_dawn_fajr_prayer_blue_1761577546239.jpg';
  static const String sunrise = 'assets/images/mosque_sunrise_golden_hour_orange_1761577546927.jpg';
  static const String dhuhr = 'assets/images/mosque_midday_noon_prayer_dhuhr_white_1761577547821.jpg';
  static const String asr = 'assets/images/mosque_afternoon_asr_prayer_yellow_1761577548842.jpg';
  static const String maghrib = 'assets/images/mosque_sunset_maghrib_prayer_red_1761577549781.jpg';
  static const String isha = 'assets/images/mosque_night_sky_isha_prayer_stars_black_1761577552242.jpg';

  // Additional variants (auto-fetched assets). The more we add, the richer the rotation.
  static const Map<String, List<String>> _variants = {
    'fajr': [
      fajr,
      'assets/images/mosque_dawn_sky_blue_1761768817699.jpg',
      'assets/images/mosque_dawn_prayer_blue_1761768818541.jpg',
    ],
    'sunrise': [
      sunrise,
      'assets/images/mosque_sunrise_minaret_orange_1761768819659.jpg',
      'assets/images/mosque_sunrise_golden_hour_orange_1761768820613.jpg',
    ],
    'dhuhr': [
      dhuhr,
      'assets/images/mosque_midday_clear_sky_white_1761768821394.jpg',
      'assets/images/mosque_noon_exterior_yellow_1761768822310.jpg',
    ],
    'asr': [
      asr,
      'assets/images/mosque_afternoon_light_yellow_1761768823249.jpg',
      'assets/images/mosque_afternoon_courtyard_yellow_1761768824005.jpg',
    ],
    'maghrib': [
      maghrib,
      'assets/images/mosque_sunset_horizon_red_1761768824893.jpg',
      'assets/images/mosque_sunset_prayer_red_1761768825613.jpg',
    ],
    'isha': [
      isha,
      'assets/images/mosque_night_sky_stars_black_1761768826397.jpg',
      'assets/images/mosque_night_lights_black_1761768827249.jpg',
    ],
  };

  // Backward compatibility
  static String urlForKey(String key) => pickFor(key);

  // Algorithmic selection that changes image deterministically over time.
  // Default policy: day-of-year rotation per moment, stable throughout the day.
  static String pickFor(String key, {DateTime? at}) {
    final list = _variants[key] ?? [dhuhr];
    if (list.isEmpty) return dhuhr;
    final now = at ?? DateTime.now();
    final dayOfYear = int.parse('${now.difference(DateTime(now.year, 1, 1)).inDays + 1}');
    final idx = dayOfYear % list.length;
    return list[idx];
  }
}

class MomentLabel {
  final String key;
  final String titleAr;
  final String titleFr;
  final IconData icon;
  const MomentLabel({required this.key, required this.titleAr, required this.titleFr, required this.icon});
}

class PrayerMomentLabelsCatalog {
  static const List<MomentLabel> labels = [
    MomentLabel(key: 'fajr', titleAr: 'الفجر', titleFr: 'Fajr', icon: Icons.wb_sunny_outlined),
    MomentLabel(key: 'sunrise', titleAr: 'شروق الشمس', titleFr: 'Lever du soleil', icon: Icons.wb_sunny_outlined),
    MomentLabel(key: 'dhuhr', titleAr: 'الظهر', titleFr: 'Dhouhr', icon: Icons.wb_sunny),
    MomentLabel(key: 'asr', titleAr: 'العصر', titleFr: 'Asr', icon: Icons.wb_cloudy),
    MomentLabel(key: 'maghrib', titleAr: 'المغرب', titleFr: 'Maghrib', icon: Icons.brightness_4),
    MomentLabel(key: 'isha', titleAr: 'العشاء', titleFr: 'Isha', icon: Icons.nights_stay),
  ];
}
