import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:sajda/models/mosque.dart';
import 'package:sajda/utils/secrets.dart';

/// Service léger d’enrichissement des mosquées via l’API Google Places.
class GooglePlacesService {
  static const _textSearchEndpoint =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';
  static const _detailsEndpoint =
      'https://maps.googleapis.com/maps/api/place/details/json';

  static String? get _apiKey {
    final key = AppSecrets.googlePlacesApiKey.trim();
    if (key.isEmpty) return null;
    return key;
  }

  static bool get isConfigured => _apiKey != null;

  /// Complète éventuellement une mosquée avec adresse/téléphone/site.
  static Future<Mosque> enrichMosque(Mosque mosque) async {
    final key = _apiKey;
    if (key == null) return mosque;

    try {
      final placeId = await _findBestPlaceId(mosque, key);
      if (placeId == null) return mosque;

      final details = await _fetchDetails(placeId, key);
      if (details == null) return mosque;

      final result = details['result'];
      if (result is! Map<String, dynamic>) return mosque;

      final location = result['geometry']?['location'];
      final enriched = Mosque(
        id: mosque.id,
        name: mosque.name,
        latitude: location is Map<String, dynamic>
            ? (location['lat'] as num?)?.toDouble() ?? mosque.latitude
            : mosque.latitude,
        longitude: location is Map<String, dynamic>
            ? (location['lng'] as num?)?.toDouble() ?? mosque.longitude
            : mosque.longitude,
        address: mosque.address ?? result['formatted_address'] as String?,
        phone: mosque.phone ?? _pickPhone(result),
        website: mosque.website ?? result['website'] as String?,
        gender: mosque.gender,
        distance: mosque.distance,
      );

      return enriched;
    } catch (e) {
      // ignore: avoid_print
      print('GooglePlaces enrichment failed: $e');
      return mosque;
    }
  }

  static Future<Map<String, dynamic>?> _fetchDetails(
    String placeId,
    String key,
  ) async {
    final uri = Uri.parse(_detailsEndpoint).replace(queryParameters: {
      'place_id': placeId,
      'fields':
          'formatted_address,formatted_phone_number,international_phone_number,geometry/location,website',
      'language': 'fr',
      'key': key,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    if (body['status'] != 'OK') return null;
    return body;
  }

  static Future<String?> _findBestPlaceId(Mosque mosque, String key) async {
    final params = <String, String>{
      'query': '${mosque.name} mosquée',
      'language': 'fr',
      'key': key,
    };

    if (!_isZero(mosque.latitude) && !_isZero(mosque.longitude)) {
      params['location'] = '${mosque.latitude},${mosque.longitude}';
      params['radius'] = '2500';
    }

    final uri = Uri.parse(_textSearchEndpoint).replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    if (body['status'] != 'OK' || body['results'] is! List) return null;

    final List results = body['results'] as List;
    if (results.isEmpty) return null;

    final target = _normalize(mosque.name);
    double bestScore = -1;
    Map<String, dynamic>? best;

    for (final entry in results.cast<Map<String, dynamic>>()) {
      final name = entry['name'] as String?;
      final placeId = entry['place_id'] as String?;
      if (name == null || placeId == null) continue;

      final location = entry['geometry']?['location'];
      final score = _computeScore(
        target,
        _normalize(name),
        location is Map<String, dynamic>
            ? (location['lat'] as num?)?.toDouble()
            : null,
        location is Map<String, dynamic>
            ? (location['lng'] as num?)?.toDouble()
            : null,
        mosque,
        entry['types'] as List<dynamic>?,
      );

      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    return best?['place_id'] as String? ??
        (results.first as Map<String, dynamic>)['place_id'] as String?;
  }

  static String? _pickPhone(Map<String, dynamic> result) {
    final intl = result['international_phone_number'];
    if (intl is String && intl.trim().isNotEmpty) {
      return intl.trim();
    }
    final formatted = result['formatted_phone_number'];
    if (formatted is String && formatted.trim().isNotEmpty) {
      return formatted.trim();
    }
    return null;
  }

  static double _computeScore(
    String target,
    String candidate,
    double? candLat,
    double? candLng,
    Mosque base,
    List<dynamic>? types,
  ) {
    if (candidate.isEmpty) return 0;

    final targetWords = target.split(' ').where((w) => w.isNotEmpty).toList();
    final candidateWords = candidate.split(' ').where((w) => w.isNotEmpty).toSet();
    if (targetWords.isEmpty) return 0;

    final matches = targetWords.where(candidateWords.contains).length;
    final nameScore = matches / targetWords.length;

    double distanceScore = 0.0;
    if (candLat != null && candLng != null) {
      final dist = _haversine(base.latitude, base.longitude, candLat, candLng);
      distanceScore = dist < 0.05
          ? 1.0
          : 1 / (1 + (dist / 2)); // 0 à ~1 sur 2km
    }

    final typeBonus = (types ?? const [])
            .map((t) => t is String ? t : t.toString())
            .any((t) => t.contains('mosque'))
        ? 0.15
        : 0.0;

    return nameScore * 0.7 + distanceScore * 0.25 + typeBonus;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isZero(double v) => v.abs() < 1e-6;

  static double _haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}