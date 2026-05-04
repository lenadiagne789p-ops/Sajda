import 'dart:convert';
import 'package:http/http.dart' as http;

class CommuneSuggestion {
  final String name;
  final List<String> postalCodes;
  final double lat;
  final double lng;

  CommuneSuggestion({
    required this.name,
    required this.postalCodes,
    required this.lat,
    required this.lng,
  });
}

class CitySuggestionService {
  // Uses https://geo.api.gouv.fr/communes
  static Future<List<CommuneSuggestion>> suggestCommunes(String query) async {
    if (query.trim().length < 2) return [];
    final uri = Uri.parse(
        'https://geo.api.gouv.fr/communes?nom=${Uri.encodeQueryComponent(query)}&fields=code,nom,codesPostaux,centre&boost=population&limit=8');

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! List) return [];

      return data.map<CommuneSuggestion>((raw) {
        final nom = (raw['nom'] ?? '').toString();
        final cps = (raw['codesPostaux'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        final centre = raw['centre'];
        double lat = 0, lng = 0;
        if (centre != null && centre['coordinates'] != null && (centre['coordinates'] as List).length >= 2) {
          // geo.api.gouv.fr returns [lng, lat]
          final coords = centre['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
        return CommuneSuggestion(name: nom, postalCodes: cps, lat: lat, lng: lng);
      }).where((c) => c.lat != 0 || c.lng != 0).toList();
    } catch (_) {
      return [];
    }
  }
}
