import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:sajda/models/mosque.dart';
import 'package:sajda/services/mosque_service.dart';
import 'package:sajda/services/city_suggestion_service.dart';
import 'package:sajda/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;

enum RegionMode { local, france, switzerland, europe }

class MosquesPage extends StatefulWidget {
  const MosquesPage({super.key});

  @override
  State<MosquesPage> createState() => _MosquesPageState();
}

class _MosquesPageState extends State<MosquesPage> {
  List<Mosque> _mosques = [];
  List<Mosque> _franceIndex = [];
  List<Mosque> _swissIndex = [];
  List<Mosque> _europeIndex = [];
  List<Mosque> _displayMosques = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userAddress;
  String _searchRadius = '10';
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  List<CommuneSuggestion> _citySuggestions = [];
  Timer? _debounce;
  double? _currentLatitude;
  double? _currentLongitude;
  bool _usingManualLocation = false;
  bool _locationPermissionDenied = false;
  bool _locationPermissionPermanentlyDenied = false;
  bool _locationServiceDisabled = false;
  RegionMode _mode = RegionMode.local;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _ensurePermissionAndLoad();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _filterController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _ensurePermissionAndLoad() async {
    try {
      // Proactively prompt for permission on page open
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionPermanentlyDenied = true;
            _errorMessage =
                'L\'autorisation de localisation est désactivée. Ouvrez les réglages pour la réactiver.';
          });
        }
        // Still attempt load (may use manual flow)
        await _loadMosques();
        return;
      }

      await _loadMosques();
    } catch (_) {
      await _loadMosques();
    }
  }

  Future<void> _loadMosques({
    double? latitude,
    double? longitude,
    String? overrideAddress,
    bool manualSelection = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationPermissionDenied = false;
      _locationPermissionPermanentlyDenied = false;
      _locationServiceDisabled = false;
    });

    try {
      double targetLat;
      double targetLng;
      String? addressLabel;

      if (latitude != null && longitude != null) {
        targetLat = latitude;
        targetLng = longitude;
        addressLabel = await MosqueService.getAddressFromCoordinates(targetLat, targetLng);
        addressLabel ??= overrideAddress;
      } else {
        final position = await MosqueService.getCurrentLocation();

        if (position == null) {
          // On web or when geolocation fails, show France-wide index
          targetLat = 46.5;
          targetLng = 2.2;
          addressLabel = 'Toute la France';
          manualSelection = false;
          
          // For non-web or when permissions are an issue, show the France index
          if (!kIsWeb) {
            final permissionStatus = await Geolocator.checkPermission();
            if (permissionStatus == LocationPermission.denied || 
                permissionStatus == LocationPermission.unableToDetermine) {
              // Permission not yet decided, but we can still show France index
            }
          }
        } else {
          targetLat = position.latitude;
          targetLng = position.longitude;
          addressLabel = await MosqueService.getAddressFromCoordinates(targetLat, targetLng);
          manualSelection = false;
        }
      }

      // When using default France center position, load full France index instead of nearby search
      final radiusKm = double.tryParse(_searchRadius) ?? 10;
      final isDefaultPosition = (targetLat - 46.5).abs() < 0.01 && (targetLng - 2.2).abs() < 0.01;
      
      List<Mosque> mosques;
      if (isDefaultPosition && !_usingManualLocation) {
        // Load full France index when using default position
        mosques = await MosqueService.getFranceIndex(userLat: targetLat, userLng: targetLng);
        // Debug
        print('Loaded France index with ${mosques.length} mosques');
      } else {
        mosques = await MosqueService.getNearbyMosques(
          targetLat,
          targetLng,
          radiusKm: radiusKm,
        );
      }

      _currentLatitude = targetLat;
      _currentLongitude = targetLng;
      _usingManualLocation = manualSelection;

      if (!mounted) return;

      final displayAddress = addressLabel ??
          (manualSelection ? overrideAddress : null) ??
          'Localisation détectée';

      setState(() {
        _mosques = mosques;
        _userAddress = displayAddress;
        _isLoading = false;
        _locationPermissionDenied = false;
        _locationPermissionPermanentlyDenied = false;
        _locationServiceDisabled = false;
        _errorMessage = mosques.isEmpty
            ? 'Aucune mosquée trouvée dans un rayon de ${radiusKm.toStringAsFixed(0)} km.'
            : null;
        _applyFilter();
      });

      // Enrich with address/phone when missing
      unawaited(_enrichVisibleMosques());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  Future<void> _enrichVisibleMosques() async {
    try {
      // Limit enrichment to first 25 items to keep it responsive
      final List<Mosque> source;
      switch (_mode) {
        case RegionMode.local:
          source = _mosques;
          break;
        case RegionMode.france:
          source = _franceIndex;
          break;
        case RegionMode.switzerland:
          source = _swissIndex;
          break;
        case RegionMode.europe:
          source = _europeIndex;
          break;
      }
      final candidates = source
          .where((m) => (m.address == null || m.phone == null))
          .take(25)
          .toList();
      if (candidates.isEmpty) return;

      for (var i = 0; i < candidates.length; i++) {
        final m = candidates[i];
        final enriched = await MosqueService.enrichWithExternalProviders(m);
        if (!mounted) return;
        if (enriched.address != m.address || enriched.phone != m.phone || enriched.website != m.website) {
          setState(() {
            // update in main list(s)
            List<Mosque> listRef;
            switch (_mode) {
              case RegionMode.local:
                listRef = _mosques;
                break;
              case RegionMode.france:
                listRef = _franceIndex;
                break;
              case RegionMode.switzerland:
                listRef = _swissIndex;
                break;
              case RegionMode.europe:
                listRef = _europeIndex;
                break;
            }
            final idx = listRef.indexWhere((e) => e.id == m.id);
            if (idx != -1) {
              // Recompute distance if we have a current location and coordinates changed
              if (_currentLatitude != null && _currentLongitude != null) {
                enriched.distance = _distanceKm(
                  _currentLatitude!,
                  _currentLongitude!,
                  enriched.latitude,
                  enriched.longitude,
                );
              }
              listRef[idx] = enriched;
            }
            _applyFilter();
          });
        }
        // Be polite with external APIs
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {
      // ignore enrichment errors
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) => degree * 3.141592653589793 / 180.0;

  void _onRadiusChanged(String value) {
    setState(() {
      _searchRadius = value;
    });
    _refreshMosques();
  }

  Future<void> _refreshMosques() {
    if (_currentLatitude != null && _currentLongitude != null) {
      return _loadMosques(
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        overrideAddress: _userAddress,
        manualSelection: _usingManualLocation,
      );
    }
    return _loadMosques();
  }

  Future<void> _useCurrentLocation() async {
    _cityController.clear();
    await _loadMosques(manualSelection: false);
  }

  Future<void> _loadFranceIndex({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await MosqueService.getFranceIndex(
        userLat: _currentLatitude,
        userLng: _currentLongitude,
        forceRefresh: force,
      );
      if (!mounted) return;
      setState(() {
        _franceIndex = list;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger l\'index France: $e';
      });
    }
  }

  Future<void> _loadSwitzerlandIndex({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await MosqueService.getSwitzerlandIndex(
        userLat: _currentLatitude,
        userLng: _currentLongitude,
        forceRefresh: force,
      );
      if (!mounted) return;
      setState(() {
        _swissIndex = list;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger l\'index suisse: $e';
      });
    }
  }

  Future<void> _loadEuropeIndex({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await MosqueService.getEuropeIndex(
        userLat: _currentLatitude,
        userLng: _currentLongitude,
        forceRefresh: force,
      );
      if (!mounted) return;
      setState(() {
        _europeIndex = list;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger l\'index Europe: $e';
      });
    }
  }

  Future<void> _setMode(RegionMode newMode) async {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      _filterQuery = '';
      _filterController.clear();
      _citySuggestions = [];
    });

    switch (_mode) {
      case RegionMode.local:
        await _refreshMosques();
        break;
      case RegionMode.france:
        if (_franceIndex.isEmpty) {
          await _loadFranceIndex();
        } else {
          setState(_applyFilter);
        }
        break;
      case RegionMode.switzerland:
        if (_swissIndex.isEmpty) {
          await _loadSwitzerlandIndex();
        } else {
          setState(_applyFilter);
        }
        break;
      case RegionMode.europe:
        if (_europeIndex.isEmpty) {
          await _loadEuropeIndex();
        } else {
          setState(_applyFilter);
        }
        break;
    }
  }

  void _applyFilter() {
    final List<Mosque> source;
    switch (_mode) {
      case RegionMode.local:
        source = _mosques;
        break;
      case RegionMode.france:
        source = _franceIndex;
        break;
      case RegionMode.switzerland:
        source = _swissIndex;
        break;
      case RegionMode.europe:
        source = _europeIndex;
        break;
    }
    final q = _filterQuery.trim().toLowerCase();
    if (q.isEmpty) {
      _displayMosques = List.of(source);
    } else {
      _displayMosques = source.where((m) {
        final inName = m.name.toLowerCase().contains(q);
        final inAddr = m.address != null && m.address!.toLowerCase().contains(q);
        return inName || inAddr;
      }).toList();
    }
  }

  void _onFilterChanged(String value) {
    setState(() {
      _filterQuery = value;
      _applyFilter();
    });
  }

  

  Future<void> _requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
            _errorMessage =
                'Nous avons besoin de votre autorisation pour afficher les mosquées proches.';
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionPermanentlyDenied = true;
            _errorMessage =
                'L\'autorisation de localisation est bloquée. Ouvrez les réglages pour l\'activer.';
          });
        }
        await _openPermissionSettings();
        return;
      }

      await _useCurrentLocation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de demander l\'autorisation: $e';
        });
      }
    }
  }

  Future<void> _openPermissionSettings() async {
    try {
      // Special handling for web: we cannot open browser settings programmatically
      if (kIsWeb) {
        await _showWebLocationHelp();
        return;
      }

      bool opened = false;

      // If location services are disabled, try opening the location settings first
      if (_locationServiceDisabled) {
        opened = await Geolocator.openLocationSettings();
      }

      // If not opened yet, try app settings (needed when permission is deniedForever)
      if (!opened) {
        opened = await Geolocator.openAppSettings();
      }

      // As a last attempt, try location settings again
      if (!opened) {
        opened = await Geolocator.openLocationSettings();
      }

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible d\'ouvrir les réglages automatiquement. Ouvrez-les manuellement puis revenez dans l\'application.'
            ),
          ),
        );
      }
    } catch (_) {
      // Silently ignore when the platform does not support opening settings.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ouverture des réglages non prise en charge sur cet appareil.'
            ),
          ),
        );
      }
    }
  }

  Future<void> _showWebLocationHelp() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: IslamicColors.emeraldGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Autoriser la localisation (navigateur)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: IslamicColors.emeraldGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Nous ne pouvons pas ouvrir les réglages du navigateur automatiquement. '
                'Veuillez ajuster l\'autorisation de localisation pour ce site, puis réessayez:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildBullet('Cliquez sur l\'icône cadenas/permission près de l\'URL.'),
              _buildBullet('Dans « Autorisations », mettez Localisation sur « Autoriser ».') ,
              _buildBullet('Actualisez la page si nécessaire puis appuyez sur Réessayer.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _requestLocationPermission();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer l\'accès'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IslamicColors.emeraldGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      const helpUrl = 'https://support.google.com/chrome/answer/142065?hl=fr';
                      if (await canLaunchUrl(Uri.parse(helpUrl))) {
                        await launchUrl(Uri.parse(helpUrl), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Aide navigateur'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: IslamicColors.roseGold,
                      side: const BorderSide(color: IslamicColors.roseGold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: IslamicColors.mysticBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: IslamicColors.mysticBlue,
                  ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _searchByCity() async {
    final cityQuery = _cityController.text.trim();
    if (cityQuery.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez saisir une ville pour lancer la recherche.')),
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // If user selected a suggestion formatted as "City (CP)", try to resolve by our suggestions first
      CommuneSuggestion? selected;
      if (_citySuggestions.isNotEmpty) {
        final normalized = cityQuery.toLowerCase();
        selected = _citySuggestions.firstWhere(
          (c) => normalized.startsWith(c.name.toLowerCase()),
          orElse: () => _citySuggestions.first,
        );
      } else {
        // Fallback: direct geocoding
        final locations = await geocoding.locationFromAddress(cityQuery);
        if (locations.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ville introuvable. Vérifiez l\'orthographe ou précisez le pays.'),
            ),
          );
          return;
        }
        final loc = locations.first;
        selected = CommuneSuggestion(name: _formatCityLabel(cityQuery), postalCodes: const [], lat: loc.latitude, lng: loc.longitude);
      }

      await _loadMosques(
        latitude: selected.lat,
        longitude: selected.lng,
        overrideAddress: _formatCityDisplay(selected),
        manualSelection: true,
      );

      if (mounted) {
        final formatted = _formatCityDisplay(selected);
        _cityController
          ..text = formatted
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: formatted.length),
          );
        _citySuggestions = [];
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final message = e.toString().toLowerCase().contains('no result')
          ? 'Ville introuvable. Vérifiez l\'orthographe ou précisez le pays.'
          : 'Nous n\'avons pas pu lancer la recherche. Réessayez dans un instant.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatCityLabel(String city) {
    final words = city
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      final lower = word.toLowerCase();
      return lower.isEmpty
          ? ''
          : '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).where((word) => word.isNotEmpty).toList();

    return words.isEmpty ? city : words.join(' ');
  }

  String _formatCityDisplay(CommuneSuggestion c) {
    final base = _formatCityLabel(c.name);
    final cp = c.postalCodes.isNotEmpty ? ' (${c.postalCodes.first})' : '';
    return '$base$cp';
  }

  void _onCityChanged(String value) {
    _debounce?.cancel();
    if (_mode != RegionMode.local) return;
    if (value.trim().length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await CitySuggestionService.suggestCommunes(value);
      if (!mounted) return;
      setState(() {
        _citySuggestions = results;
      });
    });
  }

  String _buildIndexStatusLabel() {
    switch (_mode) {
      case RegionMode.local:
        return '';
      case RegionMode.france:
        return _franceIndex.isEmpty
            ? 'Index France: en cours...'
            : 'Index France: ${_franceIndex.length} mosquées';
      case RegionMode.switzerland:
        return _swissIndex.isEmpty
            ? 'Index suisse: en cours...'
            : 'Index suisse: ${_swissIndex.length} mosquées';
      case RegionMode.europe:
        return _europeIndex.isEmpty
            ? 'Index Europe: en cours...'
            : 'Index Europe: ${_europeIndex.length} mosquées';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.pearlWhite,
              IslamicColors.pearlWhite.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _buildMosquesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: IslamicColors.roseGold.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: IslamicColors.emeraldGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == RegionMode.local
                          ? 'المساجد القريبة'
                          : _mode == RegionMode.france
                              ? 'Mosquées en France'
                              : _mode == RegionMode.switzerland
                                  ? 'Mosquées en Suisse'
                                  : 'Mosquées en Europe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: IslamicColors.emeraldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userAddress != null)
                      Text(
                        _userAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: IslamicColors.roseGold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModeToggle(),
          const SizedBox(height: 12),
          _buildCitySelector(),
          const SizedBox(height: 12),
          if (_mode == RegionMode.local) _buildRadiusSelector(),
          if (_mode != RegionMode.local)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _buildIndexStatusLabel(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: IslamicColors.mysticBlue,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    // Use Wrap to avoid horizontal overflow/pixel warnings on narrow screens
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Autour de moi'),
          selected: _mode == RegionMode.local,
          onSelected: (sel) => _setMode(RegionMode.local),
          selectedColor: IslamicColors.emeraldGreen.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: _mode == RegionMode.local ? IslamicColors.emeraldGreen : IslamicColors.mysticBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        ChoiceChip(
          label: const Text('France entière'),
          selected: _mode == RegionMode.france,
          onSelected: (sel) => _setMode(RegionMode.france),
          selectedColor: IslamicColors.roseGold.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: _mode == RegionMode.france ? IslamicColors.roseGold : IslamicColors.mysticBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        ChoiceChip(
          label: const Text('Suisse'),
          selected: _mode == RegionMode.switzerland,
          onSelected: (sel) => _setMode(RegionMode.switzerland),
          selectedColor: IslamicColors.emeraldGreen.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: _mode == RegionMode.switzerland ? IslamicColors.emeraldGreen : IslamicColors.mysticBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        ChoiceChip(
          label: const Text('Europe'),
          selected: _mode == RegionMode.europe,
          onSelected: (sel) => _setMode(RegionMode.europe),
          selectedColor: IslamicColors.roseGold.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: _mode == RegionMode.europe ? IslamicColors.roseGold : IslamicColors.mysticBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCitySelector() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              if (_mode == RegionMode.local)
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: IslamicColors.mysticBlue,
                        ),
                    decoration: const InputDecoration(
                       hintText: 'Ville ou pays (ex: Évry, Vigneux, Dakar, Sénégal)',
                      border: InputBorder.none,
                    ),
                    onChanged: _onCityChanged,
                    onSubmitted: (_) => _searchByCity(),
                  ),
                ),
              if (_mode != RegionMode.local)
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    onChanged: _onFilterChanged,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: IslamicColors.mysticBlue,
                        ),
                    decoration: InputDecoration(
                      hintText: _mode == RegionMode.france
                          ? 'Rechercher par nom ou adresse (France)'
                          : _mode == RegionMode.switzerland
                              ? 'Rechercher par nom ou adresse (Suisse)'
                              : 'Rechercher par nom ou adresse (Europe)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  if (_mode != RegionMode.local) {
                    _onFilterChanged(_filterController.text);
                  } else {
                    _searchByCity();
                  }
                },
                icon: const Icon(Icons.search, color: IslamicColors.emeraldGreen),
                tooltip: 'Rechercher',
              ),
              IconButton(
                onPressed: _useCurrentLocation,
                icon: Icon(
                  Icons.my_location,
                  color: _usingManualLocation
                      ? IslamicColors.roseGold
                      : IslamicColors.mysticBlue,
                ),
                tooltip: 'Utiliser ma position',
              ),
            ],
          ),
        ),
        if (_mode == RegionMode.local && _citySuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.15)),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _citySuggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: IslamicColors.mysticBlue.withValues(alpha: 0.06)),
              itemBuilder: (context, index) {
                final c = _citySuggestions[index];
                final cp = c.postalCodes.isNotEmpty ? c.postalCodes.first : '';
                return ListTile(
                  leading: const Icon(Icons.location_city, color: IslamicColors.mysticBlue),
                  title: Text(
                    _formatCityLabel(c.name),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: IslamicColors.mysticBlue),
                  ),
                  subtitle: cp.isNotEmpty ? Text(cp, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: IslamicColors.roseGold)) : null,
                  onTap: () {
                    _cityController.text = _formatCityDisplay(c);
                    _cityController.selection = TextSelection.fromPosition(TextPosition(offset: _cityController.text.length));
                    _citySuggestions = [];
                    _searchByCity();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: IslamicColors.roseGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Rayon de recherche:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<String>(
            value: _searchRadius,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            items: ['5', '10', '15', '20', '25', '50'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text('$value km'),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                _onRadiusChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.emeraldGreen),
          ),
          const SizedBox(height: 16),
          Text(
            _mode == RegionMode.local
                ? 'Localisation en cours...'
                : _mode == RegionMode.france
                    ? 'Chargement de l\'index France...'
                    : _mode == RegionMode.switzerland
                        ? 'Chargement de l\'index suisse...'
                        : 'Chargement de l\'index Europe...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: IslamicColors.emeraldGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IslamicColors.roseGold.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.error_outline,
              color: IslamicColors.roseGold,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: IslamicColors.roseGold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_locationPermissionDenied)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Icons.my_location),
                label: const Text('Autoriser la localisation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IslamicColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          if (_locationPermissionPermanentlyDenied || _locationServiceDisabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _openPermissionSettings,
                icon: const Icon(Icons.settings),
                label: Text(
                  _locationServiceDisabled
                      ? 'Activer les services de localisation'
                      : 'Ouvrir les réglages',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IslamicColors.roseGold,
                  side: const BorderSide(color: IslamicColors.roseGold),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {
              _refreshMosques();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosquesList() {
    return RefreshIndicator(
      onRefresh: () {
        switch (_mode) {
          case RegionMode.local:
            return _refreshMosques();
          case RegionMode.france:
            return _loadFranceIndex(force: true);
          case RegionMode.switzerland:
            return _loadSwitzerlandIndex(force: true);
          case RegionMode.europe:
            return _loadEuropeIndex(force: true);
        }
      },
      color: IslamicColors.emeraldGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _displayMosques.length,
        itemBuilder: (context, index) => _buildMosqueCard(_displayMosques[index]),
      ),
    );
  }

  Widget _buildMosqueCard(Mosque mosque) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            IslamicColors.pearlWhite.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.roseGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: IslamicColors.emeraldGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                  IslamicColors.roseGold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mosque.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: IslamicColors.emeraldGreen,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: IslamicColors.roseGold,
                              ),
                              const SizedBox(width: 4),
                              if (_currentLatitude != null && _currentLongitude != null)
                                Text(
                                  '${mosque.distance.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: IslamicColors.roseGold,
                                        fontWeight: FontWeight.w500,
                                      ),
                                )
                              else
                                Text(
                                  '—',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: IslamicColors.roseGold,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getGenderColor(mosque.gender).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getGenderLabel(mosque.gender),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getGenderColor(mosque.gender),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mosque.address != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: IslamicColors.mysticBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mosque.address!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (mosque.phone != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: IslamicColors.roseGold,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _launchPhone(mosque.phone!),
                        child: Text(
                          mosque.phone!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: IslamicColors.roseGold,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (mosque.website != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.language,
                        size: 16,
                        color: IslamicColors.emeraldGreen,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _launchUrl(mosque.website!),
                        child: Text(
                          'Visiter le site',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                 Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(mosque),
                        icon: const Icon(Icons.directions),
                         label: const Text('Y aller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IslamicColors.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callMosque(mosque),
                        icon: const Icon(Icons.call),
                        label: const Text('Appeler'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: IslamicColors.roseGold,
                          ),
                          foregroundColor: IslamicColors.roseGold,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender) {
      case 'women':
        return Colors.pink;
      case 'men':
        return IslamicColors.mysticBlue;
      default:
        return IslamicColors.emeraldGreen;
    }
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'women':
        return 'Femmes';
      case 'men':
        return 'Hommes';
      default:
        return 'Mixte';
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final targetUrl = url.startsWith('http') ? url : 'https://$url';
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le lien: $e')),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'appeler: $e')),
        );
      }
    }
  }

  Future<void> _launchMaps(Mosque mosque) async {
    try {
      final url = 'https://www.google.com/maps/search/?api=1&query=${mosque.latitude},${mosque.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir les cartes: $e')),
        );
      }
    }
  }

  void _callMosque(Mosque mosque) {
    if (mosque.phone != null) {
      _launchPhone(mosque.phone!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
    }
  }
}
