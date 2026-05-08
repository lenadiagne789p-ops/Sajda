import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:sajda/models/mosque.dart';
import 'package:sajda/services/google_places_service.dart';
import 'dart:convert';
import 'dart:math';

class MosqueService {

  static Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = [
          pm.locality,
          pm.postalCode,
        ].where((s) => s != null && s.isNotEmpty).toList();
        return parts.isNotEmpty ? parts.join(', ') : null;
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  static Future<List<Mosque>> getNearbyMosques(
    double latitude,
    double longitude, {
    double radiusKm = 10,
  }) async {
    final mosques = <Mosque>[];

    // Combine data from multiple sources
    try {
      // Try Overpass API first (free, OpenStreetMap)
      final overpassMosques =
          await _getFromOverpass(latitude, longitude, radiusKm);
      mosques.addAll(overpassMosques);
    } catch (e) {
      print('Overpass error: $e');
    }

    // Filter France index for nearby mosques
    try {
      final franceIndex = await getFranceIndex(
        userLat: latitude,
        userLng: longitude,
      );
      // Add nearby mosques from France index not already in the list
      for (final m in franceIndex) {
        if (m.distance <= radiusKm &&
            !mosques.any((existing) => existing.id == m.id)) {
          mosques.add(m);
        }
      }
    } catch (e) {
      print('France index error: $e');
    }

    // Sort by distance
    mosques.sort((a, b) => a.distance.compareTo(b.distance));
    return mosques;
  }

  static Future<List<Mosque>> getFranceIndex({
    double? userLat,
    double? userLng,
    bool forceRefresh = false,
  }) async {
    final mosques = _getFranceMosqueDatabase();

    // Calculate distances if user location provided
    if (userLat != null && userLng != null) {
      for (final m in mosques) {
        m.distance = _calculateDistance(userLat, userLng, m.latitude, m.longitude);
      }
      mosques.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return mosques;
  }

  static Future<List<Mosque>> getSwitzerlandIndex({
    double? userLat,
    double? userLng,
    bool forceRefresh = false,
  }) async {
    final mosques = _getSwitzerlandMosqueDatabase();

    if (userLat != null && userLng != null) {
      for (final m in mosques) {
        m.distance = _calculateDistance(userLat, userLng, m.latitude, m.longitude);
      }
      mosques.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return mosques;
  }

  static Future<List<Mosque>> getEuropeIndex({
    double? userLat,
    double? userLng,
    bool forceRefresh = false,
  }) async {
    final mosques = _getEuropeMosqueDatabase();

    if (userLat != null && userLng != null) {
      for (final m in mosques) {
        m.distance = _calculateDistance(userLat, userLng, m.latitude, m.longitude);
      }
      mosques.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return mosques;
  }

  /// Try to enrich a mosque with missing details (address/phone/website)
  /// by querying Overpass API around its coordinates.
  /// Returns an updated Mosque instance if enrichment succeeded, otherwise the original.
  static Future<Mosque> enrichFromOverpass(Mosque mosque) async {
    try {
      const String overpassUrl = 'https://overpass-api.de/api/interpreter';
      // small radius around the point to find the mapped POI
      const radiusM = 200; // 200 meters
      final query = '''
        [out:json][timeout:15];
        (
          node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusM,${mosque.latitude},${mosque.longitude});
          way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusM,${mosque.latitude},${mosque.longitude});
          relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusM,${mosque.latitude},${mosque.longitude});
        );
        out center 1;
      ''';

      final response = await http
          .post(Uri.parse(overpassUrl), body: query)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return mosque;
      final data = jsonDecode(response.body);
      if (data['elements'] == null || (data['elements'] as List).isEmpty) {
        return mosque;
      }

      // Pick the element with a name closest to our current name if possible, otherwise first
      Map<String, dynamic> best = (data['elements'] as List).first;
      for (final el in (data['elements'] as List)) {
        final tags = el['tags'] as Map<String, dynamic>?;
        if (tags == null) continue;
        final name = tags['name:fr'] ?? tags['name'];
        if (name != null &&
            name.toString().toLowerCase().contains(
                mosque.name.toLowerCase().split(' ').first)) {
          best = el as Map<String, dynamic>;
          break;
        }
      }

      final tags = best['tags'] as Map<String, dynamic>?;
      if (tags == null) return mosque;

      final enrichedAddress = tags['addr:full'] ?? _buildAddress(tags);
      final enrichedPhone = tags['phone'] ?? tags['contact:phone'];
      final enrichedWebsite = tags['website'] ?? tags['contact:website'];
      // Use precise geometry if provided
      double? newLat;
      double? newLon;
      if (best['center'] != null) {
        newLat = (best['center']['lat'] as num?)?.toDouble();
        newLon = (best['center']['lon'] as num?)?.toDouble();
      } else if (best['lat'] != null) {
        newLat = (best['lat'] as num?)?.toDouble();
        newLon = (best['lon'] as num?)?.toDouble();
      }

      if (enrichedAddress == null && enrichedPhone == null && enrichedWebsite == null) {
        return mosque;
      }

      return Mosque(
        id: mosque.id,
        name: mosque.name,
        latitude: newLat ?? mosque.latitude,
        longitude: newLon ?? mosque.longitude,
        address: mosque.address ?? (enrichedAddress is String ? enrichedAddress : null),
        phone: mosque.phone ?? (enrichedPhone is String ? enrichedPhone : null),
        website: mosque.website ?? (enrichedWebsite is String ? enrichedWebsite : null),
        gender: mosque.gender,
        distance: mosque.distance,
      );
    } catch (e) {
      // swallow enrich errors, keep original
      return mosque;
    }
  }

  static Future<Mosque> enrichWithExternalProviders(Mosque mosque) async {
    var enriched = await enrichFromOverpass(mosque);

    if ((enriched.address == null || enriched.phone == null) &&
        GooglePlacesService.isConfigured) {
      enriched = await GooglePlacesService.enrichMosque(enriched);
    }

    return enriched;
  }

  static Future<List<Mosque>> _getFromOverpass(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      final radiusM = radiusKm * 1000;
      const String overpassUrl = 'https://overpass-api.de/api/interpreter';

      // Query for mosques around the given location (amenity+religion plus name-based fallback)
      const query = '''
        [out:json];
        (
          node["amenity"="place_of_worship"]["religion"="muslim"](around:RADIUS,LAT,LNG);
          way["amenity"="place_of_worship"]["religion"="muslim"](around:RADIUS,LAT,LNG);
          relation["amenity"="place_of_worship"]["religion"="muslim"](around:RADIUS,LAT,LNG);
          node["name"~"mosque|mosquée|masjid|masjid|مسجد", i](around:RADIUS,LAT,LNG);
          way["name"~"mosque|mosquée|masjid|masjid|مسجد", i](around:RADIUS,LAT,LNG);
          relation["name"~"mosque|mosquée|masjid|masjid|مسجد", i](around:RADIUS,LAT,LNG);
        );
        out center;
      ''';

      final queryFormatted = query
          .replaceAll('RADIUS', radiusM.toStringAsFixed(0))
          .replaceAll('LAT', latitude.toString())
          .replaceAll('LNG', longitude.toString());

      final response = await http
          .post(Uri.parse(overpassUrl), body: queryFormatted)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final mosques = <Mosque>[];

        if (data['elements'] != null) {
          for (final element in data['elements']) {
            try {
              double? lat, lng;
              String? name;

              if (element['center'] != null) {
                lat = (element['center']['lat'] as num).toDouble();
                lng = (element['center']['lon'] as num).toDouble();
              } else if (element['lat'] != null) {
                lat = (element['lat'] as num).toDouble();
                lng = (element['lon'] as num).toDouble();
              }

              // prefer French name if present
              name = element['tags']?['name:fr'] ?? element['tags']?['name'];

              if (lat != null && lng != null) {
                final distance =
                    _calculateDistance(latitude, longitude, lat, lng);
                mosques.add(Mosque(
                  id: 'overpass_${element['id']}',
                  name: name ?? 'Mosquée',
                  latitude: lat,
                  longitude: lng,
                  address: element['tags']?['addr:full'] ??
                      _buildAddress(element['tags']),
                  phone: element['tags']?['phone'],
                  website: element['tags']?['website'],
                  distance: distance,
                ));
              }
            } catch (e) {
              print('Error parsing Overpass element: $e');
            }
          }
        }

        return mosques;
      }
    } catch (e) {
      print('Overpass error: $e');
    }

    return [];
  }

  static String? _buildAddress(Map<String, dynamic>? tags) {
    if (tags == null) return null;

    final parts = [
      tags['addr:street'],
      tags['addr:housenumber'],
      tags['addr:postcode'],
      tags['addr:city'],
    ].where((s) => s != null && (s as String).isNotEmpty).toList();

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double degree) => degree * pi / 180;

  static List<Mosque> _getFranceMosqueDatabase() {
    // Comprehensive database of major mosques in France
    return [
      Mosque(
        id: 'paris_grande_mosquee',
        name: 'Grande Mosquée de Paris',
        latitude: 48.8476,
        longitude: 2.3569,
        address: '39 Rue Geoffroy Saint-Hilaire, 75005 Paris',
        phone: '+33 (0)1 45 35 97 33',
        website: 'www.mosquee-de-paris.org',
        gender: 'mixed',
      ),
      // Essonne / Val-de-Marne additions frequently requested
      Mosque(
        id: 'evry_grande_mosquee',
        name: 'Grande Mosquée d’Évry-Courcouronnes',
        latitude: 48.63, // approximate; enriched via Overpass
        longitude: 2.44,
        address: null,
        gender: 'mixed',
      ),
      Mosque(
        id: 'vigneux_salle_priere',
        name: 'Salle de prière Vigneux-sur-Seine',
        latitude: 48.70, // approximate; enriched via Overpass
        longitude: 2.41,
        address: null,
        gender: 'mixed',
      ),
      Mosque(
        id: 'evry_courcouronnes_salle_priere',
        name: 'Salle de prière Évry-Courcouronnes',
        latitude: 48.62,
        longitude: 2.44,
        address: null,
        gender: 'mixed',
      ),
      Mosque(
        id: 'marseille_mosquee',
        name: 'Mosquée Al-Salam de Marseille',
        latitude: 43.3027,
        longitude: 5.3716,
        address: 'Marseille',
        gender: 'mixed',
      ),
      Mosque(
        id: 'lyon_mosquee',
        name: 'Mosquée de Lyon',
        latitude: 45.7282,
        longitude: 4.8338,
        address: 'Lyon',
        gender: 'mixed',
      ),
      Mosque(
        id: 'toulouse_mosquee',
        name: 'Mosquée du Mirail',
        latitude: 43.5582,
        longitude: 1.4434,
        address: 'Toulouse',
        gender: 'mixed',
      ),
      Mosque(
        id: 'nice_mosquee',
        name: 'Mosquée de Nice',
        latitude: 43.7102,
        longitude: 7.2620,
        address: 'Nice',
        gender: 'mixed',
      ),
      Mosque(
        id: 'nantes_mosquee',
        name: 'Mosquée de Nantes',
        latitude: 47.2184,
        longitude: -1.5536,
        address: 'Nantes',
        gender: 'mixed',
      ),
      Mosque(
        id: 'strasbourg_mosquee',
        name: 'Mosquée de Strasbourg',
        latitude: 48.5734,
        longitude: 7.7521,
        address: 'Strasbourg',
        gender: 'mixed',
      ),
      Mosque(
        id: 'montpellier_mosquee',
        name: 'Mosquée de Montpellier',
        latitude: 43.6108,
        longitude: 3.8767,
        address: 'Montpellier',
        gender: 'mixed',
      ),
      Mosque(
        id: 'bordeaux_mosquee',
        name: 'Mosquée de Bordeaux',
        latitude: 44.8378,
        longitude: -0.5792,
        address: 'Bordeaux',
        gender: 'mixed',
      ),
      Mosque(
        id: 'lille_mosquee',
        name: 'Mosquée de Lille',
        latitude: 50.6292,
        longitude: 3.0573,
        address: 'Lille',
        gender: 'mixed',
      ),
      Mosque(
        id: 'rennes_mosquee',
        name: 'Mosquée de Rennes',
        latitude: 48.1173,
        longitude: -1.6778,
        address: 'Rennes',
        gender: 'mixed',
      ),
      Mosque(
        id: 'rouen_mosquee',
        name: 'Mosquée de Rouen',
        latitude: 49.4432,
        longitude: 1.0993,
        address: 'Rouen',
        gender: 'mixed',
      ),
      Mosque(
        id: 'reims_mosquee',
        name: 'Mosquée de Reims',
        latitude: 49.2583,
        longitude: 4.0347,
        address: 'Reims',
        gender: 'mixed',
      ),
      Mosque(
        id: 'orleans_mosquee',
        name: 'Mosquée d\'Orléans',
        latitude: 47.9029,
        longitude: 1.9091,
        address: 'Orléans',
        gender: 'mixed',
      ),
      Mosque(
        id: 'angers_mosquee',
        name: 'Mosquée d\'Angers',
        latitude: 47.4712,
        longitude: -0.5517,
        address: 'Angers',
        gender: 'mixed',
      ),
      Mosque(
        id: 'brest_mosquee',
        name: 'Mosquée de Brest',
        latitude: 48.3905,
        longitude: -4.4860,
        address: 'Brest',
        gender: 'mixed',
      ),
      Mosque(
        id: 'caen_mosquee',
        name: 'Mosquée de Caen',
        latitude: 49.1793,
        longitude: -0.3704,
        address: 'Caen',
        gender: 'mixed',
      ),
      Mosque(
        id: 'clermont_mosquee',
        name: 'Mosquée de Clermont-Ferrand',
        latitude: 45.7772,
        longitude: 3.0862,
        address: 'Clermont-Ferrand',
        gender: 'mixed',
      ),
      Mosque(
        id: 'dijon_mosquee',
        name: 'Mosquée de Dijon',
        latitude: 47.3220,
        longitude: 5.0402,
        address: 'Dijon',
        gender: 'mixed',
      ),
      Mosque(
        id: 'grenoble_mosquee',
        name: 'Mosquée de Grenoble',
        latitude: 45.1885,
        longitude: 5.7245,
        address: 'Grenoble',
        gender: 'mixed',
      ),
      Mosque(
        id: 'limoges_mosquee',
        name: 'Mosquée de Limoges',
        latitude: 45.8342,
        longitude: 1.2617,
        address: 'Limoges',
        gender: 'mixed',
      ),
      Mosque(
        id: 'metz_mosquee',
        name: 'Mosquée de Metz',
        latitude: 49.1193,
        longitude: 6.1757,
        address: 'Metz',
        gender: 'mixed',
      ),
      Mosque(
        id: 'nancy_mosquee',
        name: 'Mosquée de Nancy',
        latitude: 48.6921,
        longitude: 6.1844,
        address: 'Nancy',
        gender: 'mixed',
      ),
      Mosque(
        id: 'nimes_mosquee',
        name: 'Mosquée de Nîmes',
        latitude: 43.8345,
        longitude: 4.3605,
        address: 'Nîmes',
        gender: 'mixed',
      ),
      Mosque(
        id: 'pau_mosquee',
        name: 'Mosquée de Pau',
        latitude: 43.2965,
        longitude: -0.3700,
        address: 'Pau',
        gender: 'mixed',
      ),
      Mosque(
        id: 'perpignan_mosquee',
        name: 'Mosquée de Perpignan',
        latitude: 42.7085,
        longitude: 2.8959,
        address: 'Perpignan',
        gender: 'mixed',
      ),
      Mosque(
        id: 'poitiers_mosquee',
        name: 'Mosquée de Poitiers',
        latitude: 46.5801,
        longitude: 0.3401,
        address: 'Poitiers',
        gender: 'mixed',
      ),
      Mosque(
        id: 'toulon_mosquee',
        name: 'Mosquée de Toulon',
        latitude: 43.1256,
        longitude: 5.9355,
        address: 'Toulon',
        gender: 'mixed',
      ),
      Mosque(
        id: 'tours_mosquee',
        name: 'Mosquée de Tours',
        latitude: 47.3941,
        longitude: 0.6848,
        address: 'Tours',
        gender: 'mixed',
      ),
      Mosque(
        id: 'versailles_mosquee',
        name: 'Mosquée de Versailles',
        latitude: 48.8047,
        longitude: 2.1303,
        address: 'Versailles',
        gender: 'mixed',
      ),
      Mosque(
        id: 'vitry_mosquee',
        name: 'Mosquée de Vitry-sur-Seine',
        latitude: 48.7819,
        longitude: 2.3935,
        address: 'Vitry-sur-Seine',
        gender: 'mixed',
      ),
      Mosque(
        id: 'saint_denis_mosquee',
        name: 'Mosquée de Saint-Denis',
        latitude: 48.9355,
        longitude: 2.3561,
        address: 'Saint-Denis',
        gender: 'mixed',
      ),
      Mosque(
        id: 'creteil_mosquee',
        name: 'Mosquée de Créteil',
        latitude: 48.7844,
        longitude: 2.4553,
        address: 'Créteil',
        gender: 'mixed',
      ),
      Mosque(
        id: 'fontenay_mosquee',
        name: 'Mosquée de Fontenay-sous-Bois',
        latitude: 48.8511,
        longitude: 2.4848,
        address: 'Fontenay-sous-Bois',
        gender: 'mixed',
      ),
      Mosque(
        id: 'aubervilliers_mosquee',
        name: 'Mosquée d\'Aubervilliers',
        latitude: 48.9078,
        longitude: 2.3866,
        address: 'Aubervilliers',
        gender: 'mixed',
      ),
      Mosque(
        id: 'gentilly_mosquee',
        name: 'Mosquée de Gentilly',
        latitude: 48.8160,
        longitude: 2.3456,
        address: 'Gentilly',
        gender: 'mixed',
      ),
      Mosque(
        id: 'ivry_mosquee',
        name: 'Mosquée d\'Ivry-sur-Seine',
        latitude: 48.8143,
        longitude: 2.3850,
        address: 'Ivry-sur-Seine',
        gender: 'mixed',
      ),
      Mosque(
        id: 'nogent_mosquee',
        name: 'Mosquée de Nogent-sur-Marne',
        latitude: 48.8343,
        longitude: 2.4835,
        address: 'Nogent-sur-Marne',
        gender: 'mixed',
      ),
      Mosque(
        id: 'pantin_mosquee',
        name: 'Mosquée de Pantin',
        latitude: 48.8945,
        longitude: 2.3939,
        address: 'Pantin',
        gender: 'mixed',
      ),
      Mosque(
        id: 'saint_ouen_mosquee',
        name: 'Mosquée de Saint-Ouen',
        latitude: 48.9141,
        longitude: 2.3379,
        address: 'Saint-Ouen',
        gender: 'mixed',
      ),
      Mosque(
        id: 'villepinte_mosquee',
        name: 'Mosquée de Villepinte',
        latitude: 48.9616,
        longitude: 2.5648,
        address: 'Villepinte',
        gender: 'mixed',
      ),
    ];
  }

  static List<Mosque> _getSwitzerlandMosqueDatabase() {
    // Representative selection of notable mosques/centres in Switzerland
    return [
      Mosque(
        id: 'geneve_cig',
        name: 'Centre Islamique de Genève',
        latitude: 46.2286,
        longitude: 6.1236,
        address: '104 Route de Meyrin, 1202 Genève',
        website: 'www.cige.org',
        gender: 'mixed',
      ),
      Mosque(
        id: 'lausanne_mosquee',
        name: 'Mosquée de Lausanne',
        latitude: 46.5216,
        longitude: 6.6323,
        address: 'Lausanne',
        gender: 'mixed',
      ),
      Mosque(
        id: 'zurich_mahmud',
        name: 'Mosquée Mahmoud (Zürich)',
        latitude: 47.3609,
        longitude: 8.5318,
        address: 'Forchstrasse 323, 8008 Zürich',
        website: 'www.mahmudmoschee.ch',
        gender: 'mixed',
      ),
      Mosque(
        id: 'basel_islamic_center',
        name: 'Basel Islamic Center',
        latitude: 47.5606,
        longitude: 7.5926,
        address: 'Basel',
        gender: 'mixed',
      ),
      Mosque(
        id: 'bern_mosquee',
        name: 'Mosquée de Berne',
        latitude: 46.9481,
        longitude: 7.4474,
        address: 'Bern',
        gender: 'mixed',
      ),
      Mosque(
        id: 'neuchatel_mosquee',
        name: 'Mosquée de Neuchâtel',
        latitude: 46.9920,
        longitude: 6.9310,
        address: 'Neuchâtel',
        gender: 'mixed',
      ),
      Mosque(
        id: 'lugano_mosquee',
        name: 'Mosquée de Lugano',
        latitude: 46.0037,
        longitude: 8.9511,
        address: 'Lugano',
        gender: 'mixed',
      ),
      Mosque(
        id: 'winterthur_annur',
        name: 'Mosquée An’Nur (Winterthur)',
        latitude: 47.4988,
        longitude: 8.7241,
        address: 'Winterthur',
        gender: 'mixed',
      ),
    ];
  }

  static List<Mosque> _getEuropeMosqueDatabase() {
    // Curated list of prominent mosques across Europe
    return [
      Mosque(
        id: 'london_central_mosque',
        name: 'London Central Mosque',
        latitude: 51.5321,
        longitude: -0.1659,
        address: '146 Park Rd, London NW8 7RG, UK',
        website: 'www.iccuk.org',
        gender: 'mixed',
      ),
      Mosque(
        id: 'east_london_mosque',
        name: 'East London Mosque',
        latitude: 51.5196,
        longitude: -0.0596,
        address: '82-92 Whitechapel Rd, London E1 1JQ, UK',
        website: 'www.eastlondonmosque.org.uk',
        gender: 'mixed',
      ),
      Mosque(
        id: 'cologne_central_mosque',
        name: 'Cologne Central Mosque (DITIB)',
        latitude: 50.9451,
        longitude: 6.9209,
        address: 'Venloer Str. 160, 50823 Köln, Germany',
        website: 'www.ditib.de',
        gender: 'mixed',
      ),
      Mosque(
        id: 'brussels_great_mosque',
        name: 'Great Mosque of Brussels',
        latitude: 50.8396,
        longitude: 4.3926,
        address: 'Parc du Cinquantenaire, Brussels, Belgium',
        gender: 'mixed',
      ),
      Mosque(
        id: 'amsterdam_westermoskee',
        name: 'Westermoskee Ayasofya (Amsterdam)',
        latitude: 52.3579,
        longitude: 4.8721,
        address: 'Piri Reisplein 101, 1057 KH Amsterdam, Netherlands',
        gender: 'mixed',
      ),
      Mosque(
        id: 'rome_grand_mosque',
        name: 'Grand Mosque of Rome',
        latitude: 41.9484,
        longitude: 12.4989,
        address: 'Viale della Moschea, 85, 00199 Roma RM, Italy',
        website: 'www.moscheadiroma.com',
        gender: 'mixed',
      ),
      Mosque(
        id: 'madrid_centro_cultural_islamico',
        name: 'Centro Cultural Islámico de Madrid (M-30 Mosque)',
        latitude: 40.4413,
        longitude: -3.6621,
        address: 'C. Salvador de Madariaga, 4, 28027 Madrid, Spain',
        gender: 'mixed',
      ),
      Mosque(
        id: 'granada_mosque',
        name: 'Mezquita Mayor de Granada',
        latitude: 37.1816,
        longitude: -3.5881,
        address: 'Plaza de San Nicolás, 18010 Granada, Spain',
        gender: 'mixed',
      ),
      Mosque(
        id: 'vienna_islamic_centre',
        name: 'Islamic Centre of Vienna',
        latitude: 48.2425,
        longitude: 16.4038,
        address: 'Am Bruckhaufen 3, 1210 Wien, Austria',
        website: 'www.islamiccentre.at',
        gender: 'mixed',
      ),
      Mosque(
        id: 'stockholm_mosque',
        name: 'Stockholm Mosque (Zayed bin Sultan Al Nahyan)',
        latitude: 59.3347,
        longitude: 18.0506,
        address: 'Kapellgränd 10, 116 25 Stockholm, Sweden',
        gender: 'mixed',
      ),
      Mosque(
        id: 'oslo_jamaat',
        name: 'Central Jamaat-e Ahl-e Sunnat (Oslo)',
        latitude: 59.9188,
        longitude: 10.7523,
        address: 'Calmeyers gate 8, 0183 Oslo, Norway',
        gender: 'mixed',
      ),
      Mosque(
        id: 'copenhagen_mosque',
        name: 'Masjid Hamad Bin Khalifa (Copenhagen)',
        latitude: 55.6586,
        longitude: 12.5765,
        address: 'Koge Landevej 2, 2500 København, Denmark',
        gender: 'mixed',
      ),
      Mosque(
        id: 'sarajevo_gazi_husrevbeg',
        name: 'Gazi Husrev-beg Mosque (Sarajevo)',
        latitude: 43.8596,
        longitude: 18.4285,
        address: 'Sarajevo, Bosnia and Herzegovina',
        gender: 'mixed',
      ),
      Mosque(
        id: 'zagreb_mosque',
        name: 'Zagreb Mosque',
        latitude: 45.7886,
        longitude: 15.9807,
        address: 'Av. Marina Držića 19, 10000, Zagreb, Croatia',
        gender: 'mixed',
      ),
      Mosque(
        id: 'sofia_banya_bashi',
        name: 'Banya Bashi Mosque (Sofia)',
        latitude: 42.6982,
        longitude: 23.3219,
        address: 'bul. Maria Luiza 18, 1000 Sofia, Bulgaria',
        gender: 'mixed',
      ),
      Mosque(
        id: 'athens_mosque',
        name: 'Athens Mosque (Votanikos)',
        latitude: 37.9782,
        longitude: 23.6981,
        address: 'Iera Odos 114, Athens, Greece',
        gender: 'mixed',
      ),
      Mosque(
        id: 'lisbon_central_mosque',
        name: 'Central Mosque of Lisbon',
        latitude: 38.7481,
        longitude: -9.1609,
        address: 'Av. José Malhoa 16, 1070-159 Lisboa, Portugal',
        gender: 'mixed',
      ),
      Mosque(
        id: 'istanbul_sultanahmet',
        name: 'Sultan Ahmed Mosque (Blue Mosque, Istanbul)',
        latitude: 41.0055,
        longitude: 28.9768,
        address: 'Sultan Ahmet, Istanbul, Türkiye',
        gender: 'mixed',
      ),
    ];
  }
}
