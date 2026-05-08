import 'dart:math' as math;

class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  static PrayerTimes calculate(double latitude, double longitude, DateTime date) {
    // Simplistic prayer times calculation
    // In a real app, you would use a proper library like 'adhan'
    
    final julian = _julianDay(date);
    final equation = _equationOfTime(julian);
    final declination = _sunDeclination(julian);
    
    final dhuhrTime = 12 - equation / 60;
    final fajrTime = dhuhrTime - _timeForAngle(-18, latitude, declination) / 60;
    final sunriseTime = dhuhrTime - _timeForAngle(-0.833, latitude, declination) / 60;
    final asrTime = dhuhrTime + _asrTime(latitude, declination) / 60;
    final maghribTime = dhuhrTime + _timeForAngle(-0.833, latitude, declination) / 60;
    final ishaTime = dhuhrTime + _timeForAngle(-17, latitude, declination) / 60;

    return PrayerTimes(
      fajr: _timeToDateTime(date, fajrTime),
      sunrise: _timeToDateTime(date, sunriseTime),
      dhuhr: _timeToDateTime(date, dhuhrTime),
      asr: _timeToDateTime(date, asrTime),
      maghrib: _timeToDateTime(date, maghribTime),
      isha: _timeToDateTime(date, ishaTime),
      date: date,
    );
  }

  static double _julianDay(DateTime date) {
    return date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  static double _equationOfTime(double julian) {
    final n = julian - 2451545.0;
    final l = (280.460 + 0.9856474 * n) % 360;
    final g = math.pi / 180 * ((357.528 + 0.9856003 * n) % 360);
    return 4 * (l - 0.0057183 - math.atan2(math.tan(g), math.cos(math.pi / 180 * 23.44)));
  }

  static double _sunDeclination(double julian) {
    final n = julian - 2451545.0;
    final l = math.pi / 180 * ((280.460 + 0.9856474 * n) % 360);
    return math.asin(math.sin(math.pi / 180 * 23.44) * math.sin(l));
  }

  static double _timeForAngle(double angle, double latitude, double declination) {
    final latRad = math.pi / 180 * latitude;
    final angleRad = math.pi / 180 * angle;
    return 180 / math.pi * math.acos(
      (math.sin(angleRad) - math.sin(latRad) * math.sin(declination)) /
      (math.cos(latRad) * math.cos(declination))
    ) * 4;
  }

  static double _asrTime(double latitude, double declination) {
    final latRad = math.pi / 180 * latitude;
    final shadowFactor = 1 + math.tan((latRad - declination).abs());
    final angle = -math.atan(1 / shadowFactor);
    return 180 / math.pi * math.acos(
      (math.sin(angle) - math.sin(latRad) * math.sin(declination)) /
      (math.cos(latRad) * math.cos(declination))
    ) * 4;
  }

  static DateTime _timeToDateTime(DateTime date, double timeInHours) {
    final hours = timeInHours.floor();
    final minutes = ((timeInHours - hours) * 60).round();
    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  String getPrayerNameInArabic(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return 'صلاة الفجر';
      case PrayerType.dhuhr:
        return 'صلاة الظهر';
      case PrayerType.asr:
        return 'صلاة العصر';
      case PrayerType.maghrib:
        return 'صلاة المغرب';
      case PrayerType.isha:
        return 'صلاة العشاء';
    }
  }

  String getPrayerNameInFrench(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  DateTime getPrayerTime(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
    }
  }

  PrayerType? getCurrentPrayer() {
    final now = DateTime.now();
    
    if (now.isBefore(fajr)) return null;
    if (now.isBefore(sunrise)) return PrayerType.fajr;
    if (now.isBefore(dhuhr)) return null;
    if (now.isBefore(asr)) return PrayerType.dhuhr;
    if (now.isBefore(maghrib)) return PrayerType.asr;
    if (now.isBefore(isha)) return PrayerType.maghrib;
    return PrayerType.isha;
  }

  PrayerType? getNextPrayer() {
    final now = DateTime.now();
    
    if (now.isBefore(fajr)) return PrayerType.fajr;
    if (now.isBefore(dhuhr)) return PrayerType.dhuhr;
    if (now.isBefore(asr)) return PrayerType.asr;
    if (now.isBefore(maghrib)) return PrayerType.maghrib;
    if (now.isBefore(isha)) return PrayerType.isha;
    return null; // Next day Fajr
  }
}

enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}