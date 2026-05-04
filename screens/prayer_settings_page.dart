import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sajda/services/prayer_notification_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/aladhan_api_service.dart';

class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> with TickerProviderStateMixin {
  final PrayerNotificationService _notificationService = PrayerNotificationService();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _customAdhanController = TextEditingController();
  
  bool _adhanEnabled = true;
  bool _vibrationEnabled = true;
  bool _popupEnabled = true;
  bool _isLocationLoading = false;
  String? _currentCity;
  Position? _currentPosition;
  int _selectedMethod = 12;
  List<AdhanSoundOption> _adhanOptions = const [];
  String? _selectedAdhanId;
  String? _previewingAdhanId;
  bool _isPreviewing = false;
  bool _customUrlValid = true;
  int _leadMinutes = 10;
  bool _isLeadUpdating = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadSettings();

    _playerStateSubscription = _notificationService.playerStateStream.listen((playerState) {
      final isPlaying = playerState == PlayerState.playing;
      if (!mounted) return;
      setState(() {
        _isPreviewing = isPlaying;
        if (!isPlaying) {
          _previewingAdhanId = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cityController.dispose();
    _customAdhanController.dispose();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final adhan = await _notificationService.isAdhanEnabled();
    final vibration = await _notificationService.isVibrationEnabled();
    final popup = await _notificationService.isPopupEnabled();
    final city = await _notificationService.getSelectedCity();
    final position = await _notificationService.getSavedLocation();
    final method = await _notificationService.getCalculationMethod();
    final selectedAdhan = await _notificationService.getSelectedAdhanOption();
    final adhanOptions = await _notificationService.availableAdhanOptionsAsync();
    final customUrl = await _notificationService.getCustomAdhanUrl();
    final leadMinutes = await _notificationService.getNotificationLeadMinutes();

    setState(() {
      _adhanEnabled = adhan;
      _vibrationEnabled = vibration;
      _popupEnabled = popup;
      _currentCity = city;
      _currentPosition = position;
      _cityController.text = city ?? '';
      _selectedMethod = method;
      _selectedAdhanId = selectedAdhan.id;
      _adhanOptions = adhanOptions;
      _customAdhanController.text = customUrl ?? '';
      _leadMinutes = leadMinutes;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final position = await _notificationService.getCurrentLocation();
      if (position != null) {
        final city = await _notificationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (city != null) {
          await _notificationService.saveSelectedCity(city);
          setState(() {
            _currentCity = city;
            _currentPosition = position;
            _cityController.text = city;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Localisation détectée: $city'),
              backgroundColor: IslamicColors.emeraldGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible d\'obtenir votre localisation'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _saveCityManually() async {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      setState(() {
        _isLocationLoading = true;
      });

      try {
        final position = await _notificationService.saveCityByName(city);
        if (position != null) {
          final resolvedCity = await _notificationService.getSelectedCity();
          if (!mounted) return;
          setState(() {
            _currentCity = resolvedCity ?? city;
            _currentPosition = position;
            _cityController.text = resolvedCity ?? city;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🏙️ Ville sauvegardée: ${resolvedCity ?? city}'),
              backgroundColor: IslamicColors.mysticBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Ville introuvable, veuillez vérifier l\'orthographe'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (!mounted) return;
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _testAdhan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎵 Test de l\'adhan...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    final selectedId = _selectedAdhanId;
    if (selectedId != null) {
      await _notificationService.playAdhan();
      setState(() {
        _previewingAdhanId = selectedId;
      });
    }
    
    // Arrêter après 10 secondes pour le test
    Future.delayed(const Duration(seconds: 10), () {
      _notificationService.stopAdhan();
    });
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
              IslamicColors.mysticBlue.withValues(alpha: 0.1),
              IslamicColors.pearlWhite.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationCard(),
                      const SizedBox(height: 20),
                      _buildNotificationSettings(),
                      const SizedBox(height: 20),
                      _buildCalculationMethodCard(),
                      const SizedBox(height: 20),
                      _buildTestSection(),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: IslamicColors.mysticBlue),
            onPressed: () => Navigator.pop(context, true),
          ),
          Expanded(
            child: Text(
              '⚙️ Paramètres de prière',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.mysticBlue,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.15),
            IslamicColors.emeraldGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: IslamicColors.emeraldGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Localisation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ville actuelle: ${_currentCity ?? 'Non définie'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          if (_currentPosition != null)
            Text(
              'Coordonnées: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Saisir votre ville',
              hintText: 'Ex: Paris, Casablanca, Istanbul...',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveCityManually,
              ),
            ),
            onSubmitted: (_) => _saveCityManually(),
          ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isLocationLoading ? _pulseAnimation.value : 1.0,
                  child: ElevatedButton.icon(
                    onPressed: _isLocationLoading ? null : _getCurrentLocation,
                    icon: _isLocationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_isLocationLoading 
                        ? 'Localisation...' 
                        : 'Détecter ma position'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IslamicColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IslamicColors.mysticBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: IslamicColors.mysticBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications de prière',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: IslamicColors.mysticBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildToggleOption(
            'Adhan audio',
            'Jouer l\'appel à la prière',
            Icons.volume_up,
            _adhanEnabled,
            (value) async {
              setState(() {
                _adhanEnabled = value;
              });
              await _notificationService.setAdhanEnabled(value);
            },
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'Vibration',
            'Vibrer lors de l\'appel',
            Icons.vibration,
            _vibrationEnabled,
            (value) async {
              setState(() {
                _vibrationEnabled = value;
              });
              await _notificationService.setVibrationEnabled(value);
            },
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'Notifications pop-up',
            'Afficher les alertes',
            Icons.notification_important,
            _popupEnabled,
            (value) async {
              setState(() {
                _popupEnabled = value;
              });
              await _notificationService.setPopupEnabled(value);
            },
          ),
          const SizedBox(height: 16),
          _buildLeadTimeSelector(),
          const SizedBox(height: 20),
          _buildAdhanSelectionSection(),
          const SizedBox(height: 12),
          _buildCustomAdhanSection(),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: IslamicColors.mysticBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: IslamicColors.emeraldGreen,
        ),
      ],
    );
  }

  Widget _buildLeadTimeSelector() {
    const presets = [0, 5, 10, 15, 20, 30];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: IslamicColors.emeraldGreen),
            const SizedBox(width: 12),
            Text(
              'Avertissement avant la salat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutes in presets)
              ChoiceChip(
                label: Text(minutes == 0 ? 'À l\'heure' : '-$minutes min'),
                selected: _leadMinutes == minutes,
                onSelected: _isLeadUpdating ? null : (selected) => _onLeadMinutesSelected(minutes, selected),
                selectedColor: IslamicColors.emeraldGreen.withValues(alpha: 0.15),
                backgroundColor: Colors.grey.withValues(alpha: 0.08),
                disabledColor: Colors.grey.withValues(alpha: 0.03),
                labelStyle: TextStyle(
                  color: _leadMinutes == minutes ? IslamicColors.emeraldGreen : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _leadMinutes == 0
              ? 'Les notifications arrivent exactement à l\'heure de la prière.'
              : 'Les notifications arrivent ${_leadMinutes == 1 ? '1 minute' : '$_leadMinutes minutes'} avant la salat.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        if (_isLeadUpdating)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(IslamicColors.emeraldGreen.withValues(alpha: 0.8)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Actualisation des horaires...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _onLeadMinutesSelected(int minutes, bool selected) async {
    if (!selected || _isLeadUpdating || _leadMinutes == minutes) {
      return;
    }

    final previous = _leadMinutes;
    setState(() {
      _leadMinutes = minutes;
      _isLeadUpdating = true;
    });

    try {
      await _notificationService.setNotificationLeadMinutes(minutes);
      await _notificationService.refreshPrayerNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            minutes == 0
                ? '🔔 Notifications réglées à l\'heure exacte de la prière'
                : '🔔 Notifications réglées ${minutes == 1 ? '1 minute' : '$minutes minutes'} avant la prière',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leadMinutes = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLeadUpdating = false;
      });
    }
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.roseGold.withValues(alpha: 0.15),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.roseGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IslamicColors.roseGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle,
                  color: IslamicColors.roseGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Test des notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: IslamicColors.roseGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Testez vos paramètres de notification pour vous assurer qu\'ils fonctionnent correctement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _testAdhan,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tester l\'adhan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: IslamicColors.roseGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodCard() {
    final methods = AladhanMethodsCatalog.common;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calculate, color: IslamicColors.emeraldGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Méthode de calcul', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedMethod,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.settings_suggest)),
            items: methods
                .map((m) => DropdownMenuItem<int>(
                      value: m.id,
                      child: Text(m.name),
                    ))
                .toList(),
            onChanged: (val) async {
              if (val == null) return;
              setState(() => _selectedMethod = val);
              await _notificationService.setCalculationMethod(val);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Méthode appliquée: ${methods.firstWhere((e) => e.id == val).name}'), behavior: SnackBarBehavior.floating));
              }
            },
          ),
          const SizedBox(height: 8),
          Text('Choisissez votre méthode de calcul préférée selon votre région. Par défaut: UOIF (France).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.softViolet.withValues(alpha: 0.15),
            IslamicColors.softViolet.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicColors.softViolet.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: IslamicColors.softViolet,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Informations importantes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IslamicColors.softViolet,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Les heures de prière sont calculées selon votre position géographique\n'
            '• Assurez-vous d\'avoir autorisé les notifications dans les paramètres de votre téléphone\n'
            '• L\'adhan sera joué uniquement si votre téléphone n\'est pas en mode silencieux\n'
            '• Les notifications peuvent varier selon votre appareil et votre version d\'OS',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanSelectionSection() {
    if (_adhanOptions.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: IslamicColors.roseGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.library_music, color: IslamicColors.roseGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Son de l\'adhan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._adhanOptions.map(_buildAdhanTile),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez votre muezzin préféré. L\'ensemble des audios provient de l\'API AlAdhan et sera utilisé pour chaque notification.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanTile(AdhanSoundOption option) {
    final isCurrent = _selectedAdhanId == option.id;
    final isPreviewingThis = _previewingAdhanId == option.id && _isPreviewing;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? IslamicColors.roseGold : Colors.grey.withValues(alpha: 0.2)),
        color: isCurrent ? IslamicColors.roseGold.withValues(alpha: 0.05) : Colors.white,
      ),
      child: RadioListTile<String>(
        value: option.id,
        groupValue: _selectedAdhanId,
        onChanged: (value) => _onAdhanChanged(value, option),
        title: Text(option.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(option.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        secondary: IconButton(
          icon: Icon(isPreviewingThis ? Icons.stop_circle : Icons.play_circle_fill, color: IslamicColors.roseGold, size: 28),
          onPressed: () => _togglePreview(option),
        ),
      ),
    );
  }

  Future<void> _onAdhanChanged(String? value, AdhanSoundOption option) async {
    if (value == null) return;
    setState(() {
      _selectedAdhanId = value;
    });
    await _notificationService.setSelectedAdhan(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 Adhan sélectionné: ${option.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _togglePreview(AdhanSoundOption option) async {
    if (_previewingAdhanId == option.id && _isPreviewing) {
      await _notificationService.stopAdhan();
      setState(() {
        _previewingAdhanId = null;
      });
      return;
    }

    setState(() {
      _previewingAdhanId = option.id;
    });
    await _notificationService.previewAdhan(option.id);
  }

  Widget _buildCustomAdhanSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: IslamicColors.mysticBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.link, color: IslamicColors.mysticBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Lien personnalisé AlAdhan Play', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.mysticBlue, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: _openAladhanPlay,
                icon: const Icon(Icons.open_in_new, color: IslamicColors.mysticBlue),
                label: const Text('Ouvrir', style: TextStyle(color: IslamicColors.mysticBlue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customAdhanController,
            decoration: InputDecoration(
              labelText: 'URL MP3 (copiée depuis aladhan.com/play)',
              hintText: 'https://cdn.islamic.network/adhan/audio/64/...mp3',
              prefixIcon: const Icon(Icons.music_note),
              errorText: _customUrlValid ? null : 'URL invalide. Doit être un lien https vers un .mp3',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) {
              setState(() => _customUrlValid = _isValidAdhanUrl(v));
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final url = _customAdhanController.text.trim();
                  if (!_isValidAdhanUrl(url)) {
                    setState(() => _customUrlValid = false);
                    return;
                  }
                  final opt = AdhanSoundOption(id: 'custom_url', name: 'Personnalisé (prévisualisation)', description: 'Depuis AlAdhan Play', source: url);
                  setState(() => _previewingAdhanId = opt.id);
                  await _notificationService.playAdhanOption(opt, respectToggle: false, withVibration: false);
                },
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Prévisualiser'),
                style: ElevatedButton.styleFrom(backgroundColor: IslamicColors.mysticBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = _customAdhanController.text.trim();
                  if (!_isValidAdhanUrl(url)) {
                    setState(() => _customUrlValid = false);
                    return;
                  }
                  await _notificationService.setCustomAdhanUrl(url);
                  final list = await _notificationService.availableAdhanOptionsAsync();
                  final selected = await _notificationService.getSelectedAdhanOption();
                  if (!mounted) return;
                  setState(() {
                    _adhanOptions = list;
                    _selectedAdhanId = selected.id;
                    _customUrlValid = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Lien enregistré comme adhan par défaut')));
                },
                icon: const Icon(Icons.save, color: IslamicColors.emeraldGreen),
                label: const Text('Enregistrer'),
                style: OutlinedButton.styleFrom(foregroundColor: IslamicColors.emeraldGreen, side: const BorderSide(color: IslamicColors.emeraldGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Astuce: Cliquez sur "Ouvrir" pour parcourir et copier un lien MP3.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  bool _isValidAdhanUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) return false;
    return url.toLowerCase().endsWith('.mp3');
  }

  Future<void> _openAladhanPlay() async {
    final uri = Uri.parse('https://aladhan.com/play');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir aladhan.com')));
    }
  }
}