import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/services/quran_audio_service.dart';
import 'package:sajda/services/alquran_cloud_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/screens/ayah_player_page.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';

class SurahDetailPage extends StatefulWidget {
  final Map<String, dynamic> surah;

  const SurahDetailPage({super.key, required this.surah});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  static const List<String> _defaultTranslationChoices = [
    'fr.hamidullah',
    'fr.leclerc',
    'en.sahih',
    'en.pickthall',
    'en.asad',
    'en.hilali',
    'en.arberry',
    'ar.muyassar',
    'quran-uthmani',
  ];

  // Traductions chargées dynamiquement depuis l'API
  List<AlQuranTranslation> _dynamicTranslations = [];
  bool _translationsLoaded = false;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isRefreshingTranslation = false;
  String? _errorMessage;

  Map<String, dynamic>? _meta;
  List<Map<String, dynamic>> _ayahs = [];
  bool _showTranslation = true;
  String _translationEdition = 'fr.hamidullah';

  late final AudioPlayer _audioPlayer;
  List<String> _audioCandidates = [];
  bool _isPlaying = false;
  bool _playbackStarted = false;
  bool _isStarting = false; // état de préparation du flux
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _lastAudioIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _attachAudioListeners();
    _loadSurah();
    // Paramétrage pour un démarrage fiable (iOS/Android/Web)
    // - stop: ne boucle pas, libère correctement à la fin
    // - volume: 100%
    // ignore: discarded_futures
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    // ignore: discarded_futures
    _audioPlayer.setVolume(1.0);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _attachAudioListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playbackStarted = false;
        _position = Duration.zero;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _loadSurah({String? overrideTranslation}) async {
    final int surahNumber = (widget.surah['number'] as int?) ?? 0;
    if (surahNumber <= 0) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Numéro de sourate inconnu';
      });
      return;
    }

    final bool changingTranslation = overrideTranslation != null;
    final String targetEditionRaw = (overrideTranslation ?? _translationEdition).trim();
    final String targetEdition = targetEditionRaw.isNotEmpty ? targetEditionRaw : 'fr.hamidullah';

    if (changingTranslation) {
      setState(() {
        _translationEdition = targetEdition;
        _isRefreshingTranslation = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final bundle = await QuranApiService.getSurahForReading(
        surahNumber,
        translationEdition: targetEdition,
        includeTranslation: true,
      );

      if (!mounted) return;

      final metaMap = bundle['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(bundle['meta'] as Map<String, dynamic>)
          : <String, dynamic>{};

      final ayahList = <Map<String, dynamic>>[];
      if (bundle['ayahs'] is List) {
        for (final item in bundle['ayahs'] as List) {
          if (item is Map) {
            ayahList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        _meta = metaMap;
        _ayahs = ayahList;
        _isLoading = false;
        _hasError = false;
        _isRefreshingTranslation = false;
        _translationEdition = metaMap['translationEdition']?.toString().trim().isNotEmpty == true
            ? metaMap['translationEdition'].toString()
            : targetEdition;
        _audioCandidates = QuranAudioService.buildFullSurahUrls(surahNumber);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        _isRefreshingTranslation = false;
      });
    }
  }

  List<String> get _translationChoices {
    final result = <String>[];
    for (final code in _defaultTranslationChoices) {
      if (!result.contains(code)) result.add(code);
    }
    if (!result.contains(_translationEdition)) result.add(_translationEdition);
    return result;
  }

  String _translationLabel(String code) {
    // Chercher dans les traductions dynamiques d'abord
    final dynamic = _dynamicTranslations
        .where((t) => t.identifier == code)
        .map((t) => '${t.name} (${t.language})')
        .firstOrNull;
    if (dynamic != null) return dynamic;
    final label = QuranApiService.availableEditions[code];
    if (label != null && label.isNotEmpty) return label;
    return code;
  }

  Future<void> _loadDynamicTranslations() async {
    if (_translationsLoaded) return;
    try {
      final translations = await AlQuranCloudService.getTranslations();
      if (mounted) {
        setState(() {
          _dynamicTranslations = translations;
          _translationsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _translationsLoaded = true);
    }
  }

  Future<void> _showTranslationPicker() async {
    await _loadDynamicTranslations();
    if (!mounted) return;

    // Grouper par langue
    final Map<String, List<AlQuranTranslation>> byLang = {};
    for (final t in _dynamicTranslations) {
      byLang.putIfAbsent(t.language, () => []).add(t);
    }
    // Ajouter les traductions statiques non présentes
    for (final code in _defaultTranslationChoices) {
      final exists = _dynamicTranslations.any((t) => t.identifier == code);
      if (!exists) {
        final label = QuranApiService.availableEditions[code] ?? code;
        byLang.putIfAbsent('Autres', () => []).add(AlQuranTranslation(
          identifier: code,
          name: label,
          language: 'Autres',
          languageCode: '',
        ));
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        final languages = byLang.keys.toList()..sort();
        // Mettre Français et English en premier
        for (final lang in ['English', 'Français', 'العربية']) {
          if (languages.remove(lang)) languages.insert(0, lang);
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.translate, color: IslamicColors.emeraldGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Choisir une traduction',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${_dynamicTranslations.length} traductions',
                      style: theme.textTheme.labelSmall?.copyWith(color: IslamicColors.emeraldGreen),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: languages.fold(0, (sum, lang) => sum + 1 + (byLang[lang]?.length ?? 0)),
                  itemBuilder: (_, i) {
                    int cursor = 0;
                    for (final lang in languages) {
                      if (i == cursor) {
                        // En-tête de langue
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          child: Text(
                            lang,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: IslamicColors.emeraldGreen,
                            ),
                          ),
                        );
                      }
                      cursor++;
                      final items = byLang[lang] ?? [];
                      if (i < cursor + items.length) {
                        final t = items[i - cursor];
                        final isSelected = t.identifier == _translationEdition;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? IslamicColors.emeraldGreen
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.translate,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            t.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                              color: isSelected ? IslamicColors.emeraldGreen : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: IslamicColors.emeraldGreen, size: 20)
                              : null,
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            _loadSurah(overrideTranslation: t.identifier);
                          },
                        );
                      }
                      cursor += items.length;
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _revelationLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('meccan') || normalized.contains('makkah') || normalized.contains('mecque')) {
      return 'Révélée à La Mecque';
    }
    if (normalized.contains('medinan') || normalized.contains('madinah') || normalized.contains('médine') || normalized.contains('medine')) {
      return 'Révélée à Médine';
    }
    return value;
  }

  Future<void> _startPlayback() async {
    if (_audioCandidates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio indisponible pour cette sourate')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isStarting = true;
    });

    for (int i = 0; i < _audioCandidates.length; i++) {
      final idx = (_lastAudioIndex + i) % _audioCandidates.length;
      final url = _audioCandidates[idx];
      try {
        debugPrint('SurahDetailPage: try play url=$url');
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(url));
        // Attendre un court instant pour vérifier que la lecture démarre
        bool started = false;
        for (int j = 0; j < 20; j++) { // ~3s au total
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;
          if (_isPlaying || _duration > Duration.zero || _position > Duration.zero) {
            started = true;
            break;
          }
        }
        if (!started) {
          debugPrint('SurahDetailPage: url failed to start, trying next');
          continue;
        }

        if (!mounted) return;
        setState(() {
          _playbackStarted = true;
          _lastAudioIndex = idx;
          _isStarting = false;
        });
        return;
      } catch (e) {
        debugPrint('SurahDetailPage: play error=$e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isStarting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecture audio indisponible pour le moment')),
    );
  }

  Future<void> _togglePlayPause() async {
    if (_playbackStarted) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      await _startPlayback();
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _playbackStarted = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }


  void _openAyahPlayer(int initialIndex) {
    if (kDebugMode) {
      debugPrint('SurahDetailPage: request open ayah index=$initialIndex, ayahCount=${_ayahs.length}');
    }
    if (_ayahs.isEmpty) {
      if (kDebugMode) {
        debugPrint('SurahDetailPage: _openAyahPlayer canceled because ayah list is empty');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versets indisponibles pour cette sourate.')),
      );
      return;
    }

    final dynamic rawNumber = widget.surah['number'] ?? _meta?['number'] ?? _meta?['surahNumber'];
    final String rawNumberText = rawNumber == null ? '' : rawNumber.toString();
    final int surahNumber = rawNumber is int ? rawNumber : int.tryParse(rawNumberText) ?? 0;

    if (surahNumber <= 0) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('SurahDetailPage: _openAyahPlayer canceled, invalid surah number: $rawNumber');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de sourate introuvable, veuillez réessayer.')),
      );
      return;
    }

    final englishName = (_meta?['englishName'] ?? widget.surah['englishName'] ?? '').toString();
    final arabicName = (_meta?['name'] ?? widget.surah['name'] ?? '').toString();

    final index = initialIndex <= 0
        ? 0
        : (initialIndex >= _ayahs.length ? _ayahs.length - 1 : initialIndex);
    try {
      if (kDebugMode) {
        debugPrint('SurahDetailPage: opening AyahPlayerPage for surah=$surahNumber index=$index');
      }
      // Route matérielle plein écran fiable (évite tout bug d'animations Sliver/InkWell sur le Web)
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AyahPlayerPage(
            surahNumber: surahNumber,
            surahEnglishName: englishName,
            surahArabicName: arabicName,
            surahMeta: _meta,
            ayahs: _ayahs,
            initialAyahIndex: index,
            initialTranslationEdition: _translationEdition,
            initialShowTranslation: _showTranslation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('SurahDetailPage: failed to open AyahPlayerPage - $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture du lecteur impossible: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final englishName = (_meta?['englishName'] ?? widget.surah['englishName'] ?? '').toString();
    final arabicName = (_meta?['name'] ?? widget.surah['name'] ?? '').toString();
    final translationName = (_meta?['englishNameTranslation'] ?? '').toString();
    final int? verseCount = (_meta?['numberOfAyahs'] as int?) ?? (widget.surah['numberOfAyahs'] as int?) ?? _ayahs.length;
    final revelation = (_meta?['revelationType'] ?? widget.surah['revelationType'] ?? '').toString();

    final subtitleParts = <String>[];
    if (arabicName.isNotEmpty) subtitleParts.add(arabicName);
    if (verseCount != null && verseCount > 0) subtitleParts.add('$verseCount versets');
    if (revelation.isNotEmpty) subtitleParts.add(_revelationLabel(revelation));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          GradientSliverAppBar(
            title: englishName.isNotEmpty
                ? englishName
                : 'Sourate ${widget.surah['number'] ?? ''}',
            subtitle: subtitleParts.join(' • '),
            expandedHeight: 180,
            pinned: true,
            showBack: true,
            actions: [
              if (_isPlaying)
                IconButton(
                  tooltip: 'Stop',
                  onPressed: _stopPlayback,
                  icon: const Icon(Icons.stop, color: Colors.white),
                ),
            ],
          ),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement de la sourate...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_hasError)
            SliverToBoxAdapter(
              child: _buildErrorState(context),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHeaderCard(
                  arabicName,
                  englishName,
                  translationName,
                  verseCount,
                  revelation,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildTranslationCard(),
              ),
            ),
            if (_ayahs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ayah = _ayahs[index];
                      final number = (ayah['number'] as int?) ?? index + 1;
                      final arabic = (ayah['arabic'] ?? '').toString();
                      final translation = ayah['translation']?.toString();
                      return _AyahTile(
                        number: number,
                        arabic: arabic,
                        translation: translation,
                        showTranslation: _showTranslation,
                        onTap: () {
                          if (kDebugMode) {
                            debugPrint('SurahDetailPage: ayah tile tapped -> index=$index');
                          }
                          _openAyahPlayer(index);
                        },
                      );
                    },
                    childCount: _ayahs.length,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Contenu indisponible pour le moment',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      // Removed the full-surah CTA: keep only verse-by-verse reading flow
      // (no bottom action bar)
      bottomNavigationBar: null,
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger la sourate',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _loadSurah(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    String arabicName,
    String englishName,
    String translationName,
    int? verseCount,
    String revelation,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final chipWidgets = <Widget>[];
    if (verseCount != null && verseCount > 0) {
      chipWidgets.add(_MetaChip(icon: Icons.format_list_numbered, label: '$verseCount versets'));
    }
    if (revelation.isNotEmpty) {
      chipWidgets.add(_MetaChip(icon: Icons.place, label: _revelationLabel(revelation)));
    }
    if (_showTranslation && _meta?['translationAvailable'] != false) {
      chipWidgets.add(_MetaChip(icon: Icons.translate, label: _translationLabel(_translationEdition)));
    }

    return Material(
      color: theme.cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (arabicName.isNotEmpty)
              Text(
                arabicName,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: IslamicColors.emeraldGreen,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            if (arabicName.isNotEmpty) const SizedBox(height: 12),
            if (englishName.isNotEmpty)
              Text(
                englishName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            if (translationName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  translationName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (chipWidgets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chipWidgets,
              ),
            ],
            if (_audioCandidates.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _isStarting ? null : _togglePlayPause,
                    icon: _isStarting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    label: Text(
                      _isStarting
                          ? 'Préparation...'
                          : (_isPlaying ? 'Pause' : 'Lecture audio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _playbackStarted ? _stopPlayback : null,
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final translationAvailable = _meta?['translationAvailable'] != false;
    final choices = _translationChoices;

    return Material(
      color: theme.cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: IslamicColors.emeraldGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Traduction',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_isRefreshingTranslation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (translationAvailable && !_isRefreshingTranslation)
                  GestureDetector(
                    onTap: _showTranslationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _translationLabel(_translationEdition),
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: translationAvailable ? _showTranslation : false,
              contentPadding: EdgeInsets.zero,
              onChanged: translationAvailable
                  ? (value) => setState(() => _showTranslation = value)
                  : null,
              title: Text(
                translationAvailable
                    ? 'Afficher la traduction'
                    : 'Traduction indisponible pour cette sourate',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (Removed) Mini-player for full-surah playback has been removed with the CTA.

  // (Removed) Bottom CTA for full-surah reading was here. We now keep only
  // the verse-by-verse reading flow via AyahPlayerPage.
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: IslamicColors.emeraldGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  final int number;
  final String arabic;
  final String? translation;
  final bool showTranslation;
  final VoidCallback? onTap;

  const _AyahTile({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.showTranslation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final borderRadius = BorderRadius.circular(18);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? cs.surface,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge du numéro (visuel seulement, toute la carte est cliquable)
                    Semantics(
                      button: true,
                      label: 'Verset $number, ouvrir le lecteur',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.open_in_new, color: IslamicColors.emeraldGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                if (arabic.isNotEmpty)
                  Text(
                    arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 28,
                      height: 2,
                      fontWeight: FontWeight.w600,
                      color: IslamicColors.emeraldGreen,
                    ),
                  ),
                if (showTranslation && translation != null && translation!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    translation!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}