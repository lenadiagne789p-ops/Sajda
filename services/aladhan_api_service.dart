import 'dart:convert';
import 'dart:math' as _math;
import 'package:http/http.dart' as http;
import 'package:sajda/models/prayer_times.dart';

class AladhanApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  /// Returns Qibla bearing (degrees from true North, clockwise)
  /// using AlAdhan endpoint /qibla/{lat}/{lng}.
  /// Falls back to local great-circle bearing to Kaaba if API fails.
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/qibla/$latitude/$longitude');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 200 && data['data'] is Map<String, dynamic>) {
          final direction = (data['data']['direction'] as num?)?.toDouble();
          if (direction != null && direction.isFinite) {
            // Normalize to [0, 360)
            return (direction % 360 + 360) % 360;
          }
        }
      }
      // If non-200 or invalid body, fallback
      return _computeQiblaBearing(latitude, longitude);
    } catch (_) {
      return _computeQiblaBearing(latitude, longitude);
    }
  }

  Future<PrayerTimes> getTimingsByCoordinates({required double latitude, required double longitude, int method = 3, DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final uri = Uri.parse('$_baseUrl/timings').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': method.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer timings (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['code'] != 200 || data['data'] == null) {
      throw Exception('Invalid response from AlAdhan API');
    }

    final timings = Map<String, String>.from(data['data']['timings'] as Map);

    DateTime _parseTime(String value) {
      // Some API responses include timezone in parentheses, strip it
      final onlyTime = value.split(' ').first.trim();
      final parts = onlyTime.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return DateTime(targetDate.year, targetDate.month, targetDate.day, h, m);
    }

    return PrayerTimes(
      fajr: _parseTime(timings['Fajr'] ?? '05:00'),
      sunrise: _parseTime(timings['Sunrise'] ?? '06:30'),
      dhuhr: _parseTime(timings['Dhuhr'] ?? '12:30'),
      asr: _parseTime(timings['Asr'] ?? '15:45'),
      maghrib: _parseTime(timings['Maghrib'] ?? '18:15'),
      isha: _parseTime(timings['Isha'] ?? '19:30'),
      date: DateTime(targetDate.year, targetDate.month, targetDate.day),
    );
  }

  Future<List<PrayerTimes>> getMonthlyTimingsByCoordinates({
    required double latitude,
    required double longitude,
    required int method,
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse('$_baseUrl/calendar').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': method.toString(),
      'month': month.toString(),
      'year': year.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch monthly prayer timings (${response.statusCode})');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200 || body['data'] == null || body['data'] is! List) {
      throw Exception('Invalid response from AlAdhan API for calendar');
    }

    final List list = body['data'] as List;
    List<PrayerTimes> out = [];
    for (final item in list) {
      try {
        final dateInfo = item['date'] as Map<String, dynamic>;
        final greg = dateInfo['gregorian'] as Map<String, dynamic>;
        final dateStr = greg['date'] as String; // e.g., 09-10-2025
        final parts = dateStr.split('-');
        final d = DateTime(
          int.parse(greg['year']?.toString() ?? year.toString()),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        final timings = Map<String, dynamic>.from(item['timings'] as Map);
        DateTime _parse(String v) {
          final onlyTime = (v).split(' ').first.trim();
          final p = onlyTime.split(':');
          final h = int.tryParse(p[0]) ?? 0;
          final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
          return DateTime(d.year, d.month, d.day, h, m);
        }

        out.add(PrayerTimes(
          fajr: _parse(timings['Fajr'] ?? '05:00'),
          sunrise: _parse(timings['Sunrise'] ?? '06:30'),
          dhuhr: _parse(timings['Dhuhr'] ?? '12:30'),
          asr: _parse(timings['Asr'] ?? '15:45'),
          maghrib: _parse(timings['Maghrib'] ?? '18:15'),
          isha: _parse(timings['Isha'] ?? '19:30'),
          date: DateTime(d.year, d.month, d.day),
        ));
      } catch (_) {
        // skip malformed entry
      }
    }
    return out;
  }

  // Kaaba coordinates (Masjid al-Haram)
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  /// Great-circle initial bearing from (lat1,lng1) to Kaaba.
  /// Returns degrees from true North, clockwise, in [0, 360).
  double _computeQiblaBearing(double lat1, double lng1) {
    final phi1 = lat1 * (3.141592653589793 / 180.0);
    final phi2 = _kaabaLat * (3.141592653589793 / 180.0);
    final dlambda = (_kaabaLng - lng1) * (3.141592653589793 / 180.0);

    final y = MathHelpers.sin(dlambda) * MathHelpers.cos(phi2);
    final x = MathHelpers.cos(phi1) * MathHelpers.sin(phi2) -
        MathHelpers.sin(phi1) * MathHelpers.cos(phi2) * MathHelpers.cos(dlambda);
    final bearingRad = MathHelpers.atan2(y, x);
    final bearingDeg = bearingRad * (180.0 / 3.141592653589793);
    return (bearingDeg % 360 + 360) % 360;
  }
}

class AladhanCalculationMethod {
  final int id;
  final String name;
  const AladhanCalculationMethod({required this.id, required this.name});
}

class AladhanMethodsCatalog {
  static const List<AladhanCalculationMethod> common = [
    AladhanCalculationMethod(id: 3, name: 'Muslim World League (MWL)'),
    AladhanCalculationMethod(id: 12, name: 'UOIF - France'),
    AladhanCalculationMethod(id: 2, name: 'ISNA - North America'),
    AladhanCalculationMethod(id: 5, name: 'Egyptian Authority'),
    AladhanCalculationMethod(id: 4, name: 'Umm Al-Qura - Makkah'),
    AladhanCalculationMethod(id: 13, name: 'Diyanet - Turkey'),
    AladhanCalculationMethod(id: 14, name: 'SAMR - Russia'),
    AladhanCalculationMethod(id: 15, name: 'Moonsighting Committee'),
    AladhanCalculationMethod(id: 16, name: 'Dubai'),
  ];
}

/// Lightweight math helpers to avoid importing dart:math trigonometric names
class MathHelpers {
  static double sin(double x) => _math.sin(x);
  static double cos(double x) => _math.cos(x);
  static double atan2(double y, double x) => _math.atan2(y, x);
}