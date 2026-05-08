import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/services/quran_audio_service.dart';
import 'package:sajda/services/alquran_cloud_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/utils/tajweed_highlighter.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/widgets/tajweed_legend_widget.dart';

class AyahPlayerPage extends StatefulWidget {
  final int surahNumber;
  final String surahEnglishName;
  final String surahArabicName;
  final Map<String, dynamic>? surahMeta;
  final List<Map<String, dynamic>> ayahs;
  final int initialAyahIndex;
  final String initialTranslationEdition;
  final bool initialShowTranslation;

  const AyahPlayerPage({
    super.key,
    required this.surahNumber,
    required this.surahEnglishName,
    required this.surahArabicName,
    required this.ayahs,
    required this.initialAyahIndex,
    required this.initialTranslationEdition,
    required this.initialShowTranslation,
    this.surahMeta,
  });

  @override
  State<AyahPlayerPage> createState() => _AyahPlayerPageState();
}

class _AyahPlayerPageState extends State<AyahPlayerPage> {
  static const List<String> _translationShortlist = [
    'fr.hamidullah',
    'en.sahih',
    'en.pickthall',
    'en.asad',
  ];

  late final AudioPlayer _audioPlayer;
  late List<Map<String, dynamic>> _ayahs;
  late List<GlobalKey> _ayahKeys;
  late int _currentIndex;
  late bool _showTranslation;
  late String _translationEdition;

  Map<String, dynamic>? _meta;

  bool _isPlaying = false;
  bool _isUpdatingTranslation = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackRate = 1.0;
  // Repeat behavior for the current ayah
  // null = infinite repeat, 1 = default (play once, then advance)
  int? _repeatCount = 1;
  int _repeatCyclesCompleted = 0;
  bool _hasStarted = false;
  int _recitationId = 7; // legacy (rétrocompatibilité signets)
  String _reciterIdentifier = QuranAudioService.defaultReciterIdentifier;
  bool _recitersLoaded = false;
  double _arabicScale = 1.0;
  bool _tajweed = true;
  // Anti-doublon pour la détection de fin de verset
  bool _completionTriggeredForCurrentAyah = false;
  bool _autoScrolledForCurrentAyah = false;
  double? _pinchBaseScale;

  // Quran Majeed-like additions
  // A↔B range repeat
  int? _rangeStartIndex; // inclusive
  int? _rangeEndIndex; // inclusive
  int? _rangeRepeatCount; // null = infinite
  int _rangeCyclesCompleted = 0; // completed full A..B loops

  // Auto-advance to next surah when last ayah completes
  bool _autoAdvanceNextSurah = true;

  // Sleep timer (stop after duration)
  Duration? _sleepDuration;
  Timer? _sleepTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // Configuration du player pour une lecture fiable
    // ignore: discarded_futures
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _attachAudioListeners();
    // Log d'initialisation pour diagnostiquer l'ouverture de la page
    // ignore: avoid_print
    // Use debugPrint to ensure consistent behavior on web
    debugPrint('AyahPlayerPage:init -> surah=${widget.surahNumber}, initialIndex=${widget.initialAyahIndex}, ayahs=${widget.ayahs.length}');

    _meta = widget.surahMeta != null ? Map<String, dynamic>.from(widget.surahMeta!) : null;
    _ayahs = widget.ayahs.map((ayah) => Map<String, dynamic>.from(ayah)).toList(growable: false);
    _ayahKeys = List<GlobalKey>.generate(_ayahs.length, (_) => GlobalKey());
    if (_ayahs.isEmpty) {
      _currentIndex = 0;
    } else {
      final initial = widget.initialAyahIndex;
      if (initial <= 0) {
        _currentIndex = 0;
      } else if (initial >= _ayahs.length) {
        _currentIndex = _ayahs.length - 1;
      } else {
        _currentIndex = initial;
      }
    }
    _showTranslation = widget.initialShowTranslation;
    _translationEdition = widget.initialTranslationEdition;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pré-charger les URLs audio de toute la sourate en arrière-plan
      unawaited(QuranAudioService.prefetchSurahAudio(
        widget.surahNumber,
        reciterIdentifier: _reciterIdentifier,
      ));
      if (_ayahs.isNotEmpty) {
        if (!kIsWeb) {
          await _playCurrentAyah(autoScroll: false);
        }
        _scrollToCurrentAyah(animated: false);
      }
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _attachAudioListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      // Auto-follow: scroll shortly after playback starts for the current ayah
      if (_isPlaying && !_autoScrolledForCurrentAyah && position.inMilliseconds > 200) {
        _autoScrolledForCurrentAyah = true;
        _scrollToCurrentAyah();
      }
      // Fallback: sur certains navigateurs, onPlayerComplete peut être capricieux.
      // Si on approche de la fin, on déclenche manuellement l’avancement.
      final dMs = _duration.inMilliseconds;
      if (_isPlaying && dMs > 0) {
        final pMs = position.inMilliseconds;
        final remaining = dMs - pMs;
        if (remaining <= 250 && !_completionTriggeredForCurrentAyah) {
          _completionTriggeredForCurrentAyah = true;
          // Laisser 100 ms pour éviter une course avec onPlayerComplete
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!mounted) return;
            _handlePlaybackCompleted();
          });
        }
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _handlePlaybackCompleted();
    });
  }

  Future<void> _handlePlaybackCompleted() async {
    if (!mounted) return;
    // Réinitialise le drapeau pour le verset suivant
    _completionTriggeredForCurrentAyah = false;
    if (_repeatCount == null) {
      await _playCurrentAyah();
      return;
    }

    _repeatCyclesCompleted += 1;
    if (_repeatCyclesCompleted < _repeatCount!) {
      await _playCurrentAyah();
      return;
    }

    _repeatCyclesCompleted = 0;
    // Range repeat logic (A↔B)
    if (_rangeStartIndex != null && _rangeEndIndex != null) {
      final a = _rangeStartIndex!.clamp(0, _ayahs.length - 1);
      final b = _rangeEndIndex!.clamp(0, _ayahs.length - 1);
      final start = a <= b ? a : b;
      final end = a <= b ? b : a;
      final withinRange = _currentIndex >= start && _currentIndex <= end;
      if (withinRange) {
        if (_currentIndex < end) {
          await _goToAyah(_currentIndex + 1, autoPlay: true);
          return;
        }
        // We just finished B
        if (_rangeRepeatCount == null) {
          _rangeCyclesCompleted = 0;
          await _goToAyah(start, autoPlay: true);
          return;
        } else {
          _rangeCyclesCompleted += 1;
          if (_rangeCyclesCompleted < _rangeRepeatCount!) {
            await _goToAyah(start, autoPlay: true);
            return;
          } else {
            // Range completed the requested number of loops -> continue after B
            _rangeCyclesCompleted = 0;
            if (end < _ayahs.length - 1) {
              await _goToAyah(end + 1, autoPlay: true);
              return;
            }
            // End of surah: fallthrough to post-surah behavior
          }
        }
      }
    }

    if (_currentIndex < _ayahs.length - 1) {
      await _goToAyah(_currentIndex + 1, autoPlay: true);
      return;
    }

    // Last ayah reached
    if (_autoAdvanceNextSurah) {
      await _openNextSurah();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _hasStarted = false;
    });
  }

  Map<String, dynamic> get _currentAyah {
    if (_ayahs.isEmpty) return <String, dynamic>{};
    final safeIndex = _currentIndex.clamp(0, _ayahs.length - 1);
    return _ayahs[safeIndex];
  }

  int get _currentAyahNumber {
    if (_ayahs.isEmpty) return 1;
    final number = _currentAyah['numberInSurah'];
    if (number is int) return number;
    if (number is String) return int.tryParse(number) ?? (_currentIndex + 1);
    return (_currentIndex + 1);
  }

  double get _progressFraction {
    final totalMs = _duration.inMilliseconds;
    if (totalMs <= 0) return 0;
    final currentMs = _position.inMilliseconds;
    return (currentMs / totalMs).clamp(0.0, 1.0);
  }

  Future<void> _playCurrentAyah({bool autoScroll = true}) async {
    if (_ayahs.isEmpty) return;
    final ayahNumber = _currentAyahNumber;

    // Essayer d'abord de récupérer l'URL via l'API (numéro global correct)
    final apiUrl = await QuranAudioService.fetchAyahAudioUrl(
      widget.surahNumber,
      ayahNumber,
      reciterIdentifier: _reciterIdentifier,
    );

    // Construire la liste complète de candidats (API en premier si disponible)
    final candidates = <String>[
      if (apiUrl != null && apiUrl.isNotEmpty) apiUrl,
      ...QuranAudioService.buildAyahAudioUrls(
        widget.surahNumber,
        ayahNumber,
        recitationId: _recitationId,
        reciterIdentifier: _reciterIdentifier,
      ),
    ];

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio introuvable pour ce verset.')),
        );
      }
      return;
    }

    setState(() {
      _duration = Duration.zero;
      _position = Duration.zero;
      _repeatCyclesCompleted = 0;
      _autoScrolledForCurrentAyah = false;
    });

    Exception? lastError;
    // Drapeau de fin pour ce verset
    _completionTriggeredForCurrentAyah = false;
    for (final url in candidates) {
      try {
        debugPrint('AyahPlayerPage: try play url=$url');
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(url));
        if (_playbackRate != 1.0) {
          await _audioPlayer.setPlaybackRate(_playbackRate);
        }

        // Attendre un court instant pour vérifier que la lecture démarre bien
        bool started = false;
        for (int i = 0; i < 20; i++) { // ~3s au total
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;
          if (_isPlaying || _duration > Duration.zero || _position > Duration.zero) {
            started = true;
            break;
          }
        }
        if (!started) {
          debugPrint('AyahPlayerPage: url failed to start, trying next');
          continue; // essayer l’URL suivante
        }

        if (!mounted) return;
        setState(() {
          _isPlaying = true;
          _hasStarted = true;
        });
        _saveBookmark();
        if (autoScroll) {
          _autoScrolledForCurrentAyah = true;
          _scrollToCurrentAyah();
        }
        return;
      } catch (e) {
        // Gestion spéciale des blocages d'autoplay côté navigateur (Web)
        final msg = e.toString();
        if (kIsWeb && _looksLikeAutoplayBlocked(msg)) {
          if (!mounted) return;
          await _promptWebUnlockAndRetry(() => _playCurrentAyah(autoScroll: autoScroll));
          return; // on sort: la relance sera faite depuis le bouton de l'utilisateur
        }
        lastError = Exception(e.toString());
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lire le verset: ${lastError?.toString() ?? 'source audio indisponible'}')),
      );
    }
  }

  bool _looksLikeAutoplayBlocked(String msg) {
    final m = msg.toLowerCase();
    return m.contains('notallowederror') || m.contains("play() failed") || m.contains('user gesture') || m.contains('autoplay');
  }

  Future<void> _promptWebUnlockAndRetry(Future<void> Function() retry) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volume_off, color: IslamicColors.emeraldGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lecture audio bloquée',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre navigateur nécessite une action pour autoriser le son. Touchez le bouton ci‑dessous pour démarrer la lecture.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      // Relance immédiate dans le contexte du geste utilisateur
                      await retry();
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Autoriser et lire'),
                    style: FilledButton.styleFrom(
                      backgroundColor: IslamicColors.emeraldGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_hasStarted) {
        await _audioPlayer.resume();
      } else {
        await _playCurrentAyah();
      }
    }
  }

  Future<void> _restartCurrentAyah() async {
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.resume();
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      _repeatCyclesCompleted = 0;
      _hasStarted = true;
    });
  }

  Future<void> _seekRelative(Duration delta) async {
    final totalMs = _duration.inMilliseconds;
    if (totalMs <= 0) return;
    final currentMs = _position.inMilliseconds;
    var target = currentMs + delta.inMilliseconds;
    if (target < 0) target = 0;
    if (target > totalMs) target = totalMs;
    await _audioPlayer.seek(Duration(milliseconds: target));
  }

  Future<void> _goToAyah(int index, {bool autoPlay = false}) async {
    if (index < 0 || index >= _ayahs.length) return;
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
      _repeatCyclesCompleted = 0;
      _hasStarted = false;
      _completionTriggeredForCurrentAyah = false;
      _autoScrolledForCurrentAyah = false;
    });
    if (autoPlay) {
      await _playCurrentAyah();
    } else {
      _scrollToCurrentAyah();
    }
    _saveBookmark();
  }

  Future<void> _goToNext() async {
    if (_currentIndex >= _ayahs.length - 1) return;
    await _goToAyah(_currentIndex + 1, autoPlay: true);
  }

  Future<void> _goToPrevious() async {
    if (_position.inSeconds > 2) {
      await _restartCurrentAyah();
      return;
    }
    if (_currentIndex == 0) {
      await _restartCurrentAyah();
      return;
    }
    await _goToAyah(_currentIndex - 1, autoPlay: true);
  }

  Future<void> _changePlaybackRate(double rate) async {
    setState(() => _playbackRate = rate);
    try {
      await _audioPlayer.setPlaybackRate(rate);
    } catch (_) {}
  }

  void _changeRepeatCount(int? repeat) {
    setState(() {
      _repeatCount = repeat;
      _repeatCyclesCompleted = 0;
    });
  }

  Future<void> _updateTranslation(String code) async {
    final targetEdition = code.trim().isEmpty ? 'fr.hamidullah' : code.trim();
    setState(() {
      _isUpdatingTranslation = true;
    });
    try {
      final bundle = await QuranApiService.getSurahForReading(
        widget.surahNumber,
        translationEdition: targetEdition,
        includeTranslation: true,
      );

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

      final currentAyahNumber = _currentAyahNumber;
      int newIndex = ayahList.indexWhere((element) {
        final number = element['numberInSurah'] ?? element['number'];
        if (number is int) return number == currentAyahNumber;
        if (number is String) return int.tryParse(number) == currentAyahNumber;
        return false;
      });
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= ayahList.length && ayahList.isNotEmpty) {
        newIndex = ayahList.length - 1;
      }

      await _audioPlayer.stop();

      setState(() {
        _ayahs = ayahList;
        _ayahKeys = List<GlobalKey>.generate(_ayahs.length, (_) => GlobalKey());
        _currentIndex = ayahList.isNotEmpty ? newIndex : 0;
        _meta = metaMap;
        _translationEdition = metaMap['translationEdition']?.toString().trim().isNotEmpty == true
            ? metaMap['translationEdition'].toString()
            : targetEdition;
        _hasStarted = false;
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentAyah(animated: false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Traduction indisponible: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTranslation = false);
      }
    }
  }

  void _scrollToCurrentAyah({bool animated = true}) {
    if (_currentIndex < 0 || _currentIndex >= _ayahKeys.length) return;
    final key = _ayahKeys[_currentIndex];
    final context = key.currentContext;
    if (context == null) return;
    if (animated) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        alignment: 0.2,
        curve: Curves.easeInOut,
      );
    } else {
      Scrollable.ensureVisible(
        context,
        duration: Duration.zero,
        alignment: 0.2,
      );
    }
  }

  String _translationLabel(String code) {
    final label = QuranApiService.availableEditions[code];
    if (label != null && label.isNotEmpty) return label;
    return code;
  }

  List<String> get _translationChoices {
    final set = {
      ..._translationShortlist,
      _translationEdition,
    };
    return set.toList()..sort();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _reciterAccentColor() {
    if (_reciterIdentifier.contains('mujawwad')) return IslamicColors.amethystPurple;
    if (_reciterIdentifier.contains('husary')) return IslamicColors.mysticBlue;
    if (_reciterIdentifier.contains('sudais')) return IslamicColors.topaz;
    if (_reciterIdentifier.contains('minshawi')) return IslamicColors.roseGold;
    return IslamicColors.emeraldGreen;
  }

  Future<void> _showReciterPicker(BuildContext ctx) async {
    // Charger les récitateurs si pas encore fait
    List<AlQuranReciter> reciters;
    try {
      reciters = await AlQuranCloudService.getReciters();
    } catch (_) {
      reciters = QuranAudioService.reciterNamesExtended.entries
          .map((e) => AlQuranReciter(
                identifier: e.key,
                name: e.value,
                nameAr: '',
                style: 'Murattal',
                country: '',
              ))
          .toList();
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over,
                        color: IslamicColors.emeraldGreen),
                    const SizedBox(width: 10),
                    Text(
                      'Choisir un récitateur',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${reciters.length} récitateurs',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: IslamicColors.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: reciters.length,
                  itemBuilder: (_, i) {
                    final r = reciters[i];
                    final isSelected = r.identifier == _reciterIdentifier;
                    final isFeatured = QuranAudioService.featuredReciters
                        .contains(r.identifier);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? IslamicColors.emeraldGreen
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.record_voice_over,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        r.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? IslamicColors.emeraldGreen
                              : null,
                        ),
                      ),
                      subtitle: r.nameAr.isNotEmpty || r.country.isNotEmpty
                          ? Text(
                              [if (r.nameAr.isNotEmpty) r.nameAr, if (r.country.isNotEmpty) r.country].join(' • '),
                              style: theme.textTheme.labelSmall,
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: IslamicColors.emeraldGreen
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Populaire',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: IslamicColors.emeraldGreen,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.check_circle,
                                  color: IslamicColors.emeraldGreen, size: 20),
                            ),
                        ],
                      ),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        setState(() {
                          _reciterIdentifier = r.identifier;
                          // Mise à jour legacy pour rétrocompatibilité
                          // Pas de mapping inverse nécessaire : on garde 7 par défaut
                          _recitationId = 7;
                        });
                        await _audioPlayer.stop();
                        if (_hasStarted) {
                          await _playCurrentAyah(autoScroll: false);
                        }
                        _saveBookmark();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveBookmark() async {
    try {
      final payload = {
        'surahNumber': widget.surahNumber,
        'surahEnglishName': widget.surahEnglishName,
        'surahArabicName': widget.surahArabicName,
        'ayahIndex': _currentIndex,
        'ayahNumber': _currentAyahNumber,
        'translationEdition': _translationEdition,
        'recitationId': _recitationId,
        'arabicScale': _arabicScale,
        'showTranslation': _showTranslation,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await StorageService.setQuranReadingData(payload);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Log à la construction pour confirmer le rendu
    debugPrint('AyahPlayerPage:build -> index=$_currentIndex, playing=$_isPlaying');
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final englishName = widget.surahEnglishName;
    final arabicName = widget.surahArabicName;
    final verseCount = _ayahs.length;
    final currentAyahNumber = _ayahs.isNotEmpty ? _currentAyahNumber : 0;

    return Scaffold(
      // Solid background to avoid rare web canvas asserts on transparent routes
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          GradientSliverAppBar(
            title: englishName.isNotEmpty ? englishName : 'Sourate ${widget.surahNumber}',
            subtitle: 'Verset $currentAyahNumber • $verseCount versets',
            expandedHeight: 160,
            pinned: true,
            showBack: true,
            actions: [
              IconButton(
                tooltip: 'Signet: enregistrer la position',
                onPressed: _saveBookmark,
                icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildCurrentAyahCard(theme, cs, arabicName, currentAyahNumber),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _buildAudioController(theme, cs),
                ),
              ),
            ),
          ),
          if (_ayahs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ayah = _ayahs[index];
                    final number = (ayah['numberInSurah'] as int?) ?? index + 1;
                    final translation = ayah['translation']?.toString();
                    final arabic = ayah['arabic']?.toString() ?? '';
                    final isActive = index == _currentIndex;
                    final progress = isActive ? _progressFraction : 0.0;

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: _AyahReaderTile(
                          key: _ayahKeys[index],
                          number: number,
                          arabic: arabic,
                          translation: translation,
                          showTranslation: _showTranslation,
                          isActive: isActive,
                          progress: progress,
                          arabicScale: _arabicScale,
                          tajweedEnabled: _tajweed,
                          activeAccent: _reciterAccentColor(),
                          onTap: () => _goToAyah(index, autoPlay: true),
                          onPinchStart: _onPinchStart,
                          onPinchUpdate: _onPinchUpdate,
                          onPinchEnd: _onPinchEnd,
                        ),
                      ),
                    );
                  },
                  childCount: _ayahs.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Versets indisponibles pour le moment',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentAyahCard(ThemeData theme, ColorScheme cs, String arabicName, int ayahNumber) {
    final translationAvailable = _meta?['translationAvailable'] != false;
    final title = arabicName.isNotEmpty ? arabicName : widget.surahEnglishName;
    final verseLabel = ayahNumber > 0 ? 'Verset $ayahNumber' : 'Verset indisponible';

    return Material(
      color: theme.cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              verseLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
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
                if (_isUpdatingTranslation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Changer de traduction',
                  enabled: translationAvailable && !_isUpdatingTranslation,
                  onSelected: _updateTranslation,
                  itemBuilder: (context) => _translationChoices
                      .map(
                        (code) => PopupMenuItem<String>(
                          value: code,
                          child: Text(_translationLabel(code)),
                        ),
                      )
                      .toList(),
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
                    : 'Traduction indisponible',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioController(ThemeData theme, ColorScheme cs) {
    final totalSeconds = _duration.inSeconds;
    final sliderMax = totalSeconds > 0 ? totalSeconds.toDouble() : (_position.inSeconds + 1).toDouble();
    final sliderValue = _position.inSeconds.clamp(0, sliderMax.round()).toDouble();

    return Material(
      color: theme.cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq, color: IslamicColors.emeraldGreen, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Lecture audio',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying ? 'En cours' : 'Pause',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Options row: reciter selection, zoom, tajwid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                // Bouton sélection récitateur — ouvre le picker étendu (22 récitateurs)
                GestureDetector(
                  onTap: () => _showReciterPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.record_voice_over, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          QuranAudioService.reciterNamesExtended[_reciterIdentifier] ??
                              QuranAudioService.reciterNames[_recitationId] ??
                              'Récitateur',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                  ),
                ),
                FilterChip(
                  selected: _tajweed,
                  label: Text('Tajwid', style: theme.textTheme.labelMedium),
                  avatar: const Icon(Icons.palette, size: 18, color: IslamicColors.emeraldGreen),
                  onSelected: (v) => setState(() => _tajweed = v),
                ),
                // Bouton légende Tajwid
                GestureDetector(
                  onTap: () => TajweedLegendWidget.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline,
                            size: 16, color: IslamicColors.emeraldGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Légende',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FilterChip(
                  selected: false,
                  label: Text('Zoom x${_arabicScale.toStringAsFixed(2)}', style: theme.textTheme.labelMedium),
                  avatar: const Icon(Icons.zoom_in, size: 18, color: IslamicColors.emeraldGreen),
                  onSelected: (_) async {
                    final result = await showModalBottomSheet<double>(
                      context: context,
                      builder: (context) {
                        double temp = _arabicScale;
                        return SafeArea(
                          child: StatefulBuilder(
                            builder: (context, setSt) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.zoom_in, color: IslamicColors.emeraldGreen),
                                      const SizedBox(width: 8),
                                      Text('Zoom de l’écriture arabe', style: Theme.of(context).textTheme.titleMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Slider(
                                    value: temp.clamp(0.8, 2.0),
                                    min: 0.8,
                                    max: 2.0,
                                    divisions: 12,
                                    label: 'x${temp.toStringAsFixed(2)}',
                                    onChanged: (v) => setSt(() => temp = v),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: () => Navigator.of(context).pop(temp),
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Appliquer'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    if (result != null) setState(() => _arabicScale = result);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Verset précédent',
                  onPressed: _goToPrevious,
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: IslamicColors.emeraldGreen,
                ),
                IconButton(
                  tooltip: _isPlaying ? 'Pause' : 'Lecture',
                  onPressed: _togglePlayPause,
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  color: IslamicColors.emeraldGreen,
                  iconSize: 44,
                ),
                IconButton(
                  tooltip: 'Verset suivant',
                  onPressed: _goToNext,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: IslamicColors.emeraldGreen,
                ),
                IconButton(
                  tooltip: 'Rejouer le verset',
                  onPressed: _restartCurrentAyah,
                  icon: const Icon(Icons.replay_circle_filled),
                ),
                IconButton(
                  tooltip: '⏪ 5 sec',
                  onPressed: () => _seekRelative(const Duration(seconds: -5)),
                  icon: const Icon(Icons.replay_5),
                ),
                IconButton(
                  tooltip: '⏩ 5 sec',
                  onPressed: () => _seekRelative(const Duration(seconds: 5)),
                  icon: const Icon(Icons.forward_5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: theme.textTheme.labelSmall,
                ),
                Expanded(
                  child: Slider(
                    value: sliderValue,
                    min: 0,
                    max: sliderMax > 0 ? sliderMax : 1,
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.round()));
                    },
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _OptionPill(
                  icon: Icons.slow_motion_video,
                  label: 'x${_playbackRate.toStringAsFixed(2)}',
                  onTap: () => _showSpeedSheet(context),
                ),
                // Quick speed toggles
                ActionChip(
                  avatar: const Icon(Icons.speed, size: 16, color: IslamicColors.emeraldGreen),
                  label: const Text('x1'),
                  onPressed: () => _changePlaybackRate(1.0),
                ),
                ActionChip(
                  avatar: const Icon(Icons.speed, size: 16, color: IslamicColors.emeraldGreen),
                  label: const Text('x2'),
                  onPressed: () => _changePlaybackRate(2.0),
                ),
                _OptionPill(
                  icon: Icons.repeat,
                  label: _repeatCount == null ? '∞' : 'x$_repeatCount',
                  onTap: () => _showRepeatSheet(context),
                ),
                _OptionPill(
                  icon: Icons.repeat_on,
                  label: _abLabel,
                  onTap: () => _showRangeSheet(context),
                ),
                _OptionPill(
                  icon: Icons.timer,
                  label: _sleepLabel,
                  onTap: () => _showSleepTimerSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _autoAdvanceNextSurah,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _autoAdvanceNextSurah = v),
              title: Text('Continuer à la sourate suivante', style: theme.textTheme.bodyLarge),
              secondary: const Icon(Icons.queue_music, color: IslamicColors.emeraldGreen),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Pinch-to-zoom callbacks -----
  void _onPinchStart() {
    _pinchBaseScale = _arabicScale;
  }

  void _onPinchUpdate(double scale) {
    final base = _pinchBaseScale ?? _arabicScale;
    final next = (base * scale).clamp(0.8, 2.5);
    setState(() => _arabicScale = next);
  }

  void _onPinchEnd() {
    _pinchBaseScale = null;
  }

  Future<void> _showSpeedSheet(BuildContext context) async {
    final options = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final selected = await showModalBottomSheet<double>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (rate) => ListTile(
                    leading: Icon(
                      rate == _playbackRate ? Icons.check : Icons.speed,
                      color: rate == _playbackRate ? IslamicColors.emeraldGreen : null,
                    ),
                    title: Text('Vitesse x${rate.toStringAsFixed(2)}'),
                    onTap: () => Navigator.of(context).pop(rate),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      await _changePlaybackRate(selected);
    }
  }

  Future<void> _showRepeatSheet(BuildContext context) async {
    final options = <int>[1, 2, 3, -1];
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (value) => ListTile(
                    leading: Icon(
                      (value == -1 && _repeatCount == null) || value == _repeatCount
                          ? Icons.check
                          : Icons.repeat,
                      color: (value == -1 && _repeatCount == null) || value == _repeatCount
                          ? IslamicColors.emeraldGreen
                          : null,
                    ),
                    title: Text(value == -1 ? 'Répéter en continu' : 'Répéter x$value'),
                    onTap: () => Navigator.of(context).pop(value),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      _changeRepeatCount(selected == -1 ? null : selected);
    }
  }

  String get _abLabel {
    if (_rangeStartIndex == null || _rangeEndIndex == null) return 'A↔B';
    final a = (_rangeStartIndex! + 1).toString();
    final b = (_rangeEndIndex! + 1).toString();
    if (_rangeRepeatCount == null) {
      return 'A$a–B$b ∞';
    }
    return 'A$a–B$b x$_rangeRepeatCount';
  }

  String get _sleepLabel {
    if (_sleepDuration == null) return 'Minuteur: off';
    final m = _sleepDuration!.inMinutes;
    return 'Minuteur: ${m}m';
  }

  Future<void> _showRangeSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag, color: IslamicColors.emeraldGreen),
                title: const Text('Définir A (début) au verset actuel'),
                onTap: () => Navigator.of(context).pop('setA'),
              ),
              ListTile(
                leading: const Icon(Icons.outlined_flag, color: IslamicColors.emeraldGreen),
                title: const Text('Définir B (fin) au verset actuel'),
                onTap: () => Navigator.of(context).pop('setB'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  _rangeRepeatCount == null ? Icons.repeat_on : Icons.repeat,
                  color: IslamicColors.emeraldGreen,
                ),
                title: const Text('Répétitions du segment'),
                subtitle: Text(_rangeRepeatCount == null ? 'Infini' : 'x$_rangeRepeatCount'),
                onTap: () => Navigator.of(context).pop('repeat'),
              ),
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.red),
                title: const Text('Effacer A↔B'),
                onTap: () => Navigator.of(context).pop('clear'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    switch (selected) {
      case 'setA':
        setState(() {
          _rangeStartIndex = _currentIndex;
          if (_rangeEndIndex != null && _rangeEndIndex! < _rangeStartIndex!) {
            // Keep order consistent
            final tmp = _rangeEndIndex;
            _rangeEndIndex = _rangeStartIndex;
            _rangeStartIndex = tmp;
          }
          _rangeCyclesCompleted = 0;
        });
        break;
      case 'setB':
        setState(() {
          _rangeEndIndex = _currentIndex;
          if (_rangeStartIndex != null && _rangeEndIndex! < _rangeStartIndex!) {
            final tmp = _rangeEndIndex;
            _rangeEndIndex = _rangeStartIndex;
            _rangeStartIndex = tmp;
          }
          _rangeCyclesCompleted = 0;
        });
        break;
      case 'repeat':
        final rep = await showModalBottomSheet<int?>(
          context: context,
          builder: (context) {
            final options = <int>[1, 2, 3, 5, -1];
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map(
                      (v) => ListTile(
                        leading: Icon(
                          (v == -1 && _rangeRepeatCount == null) || v == _rangeRepeatCount
                              ? Icons.check
                              : Icons.repeat,
                          color: (v == -1 && _rangeRepeatCount == null) || v == _rangeRepeatCount
                              ? IslamicColors.emeraldGreen
                              : null,
                        ),
                        title: Text(v == -1 ? 'Infini' : 'Répéter x$v'),
                        onTap: () => Navigator.of(context).pop(v == -1 ? null : v),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
        if (!mounted) return;
        setState(() {
          _rangeRepeatCount = rep;
          _rangeCyclesCompleted = 0;
        });
        break;
      case 'clear':
        setState(() {
          _rangeStartIndex = null;
          _rangeEndIndex = null;
          _rangeRepeatCount = null;
          _rangeCyclesCompleted = 0;
        });
        break;
      default:
        break;
    }
  }

  Future<void> _showSleepTimerSheet(BuildContext context) async {
    final options = <Duration?>[
      null,
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(minutes: 60),
    ];
    final selected = await showModalBottomSheet<Duration?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (d) => ListTile(
                    leading: Icon(
                      (_sleepDuration == null && d == null) || (_sleepDuration != null && d != null && d.inMinutes == _sleepDuration!.inMinutes)
                          ? Icons.check
                          : Icons.timer,
                      color: (_sleepDuration == null && d == null) || (_sleepDuration != null && d != null && d.inMinutes == _sleepDuration!.inMinutes)
                          ? IslamicColors.emeraldGreen
                          : null,
                    ),
                    title: Text(d == null ? 'Désactiver' : 'Arrêter après ${d.inMinutes} minutes'),
                    onTap: () => Navigator.of(context).pop(d),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _sleepDuration = selected;
    });
    _resetSleepTimer();
  }

  void _resetSleepTimer() {
    _sleepTimer?.cancel();
    if (_sleepDuration == null) {
      return;
    }
    _sleepTimer = Timer(_sleepDuration!, () async {
      try {
        await _audioPlayer.pause();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _hasStarted = false;
        _isPlaying = false;
      });
    });
  }

  Future<void> _openNextSurah() async {
    final current = widget.surahNumber;
    if (current >= 114) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _hasStarted = false;
      });
      return;
    }
    try {
      final nextNumber = current + 1;
      final bundle = await QuranApiService.getSurahForReading(
        nextNumber,
        translationEdition: _translationEdition,
        includeTranslation: true,
      );
      if (!mounted) return;
      final meta = (bundle['meta'] is Map<String, dynamic>) ? Map<String, dynamic>.from(bundle['meta'] as Map<String, dynamic>) : <String, dynamic>{};
      final ayahsRaw = <Map<String, dynamic>>[];
      if (bundle['ayahs'] is List) {
        for (final a in bundle['ayahs'] as List) {
          if (a is Map) ayahsRaw.add(Map<String, dynamic>.from(a));
        }
      }
      if (ayahsRaw.isEmpty) {
        // Nothing to play
        setState(() {
          _isPlaying = false;
          _hasStarted = false;
        });
        return;
      }

      // Navigate to next surah reader
      // Stop current playback first
      await _audioPlayer.stop();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AyahPlayerPage(
            surahNumber: nextNumber,
            surahEnglishName: meta['englishName']?.toString() ?? 'Sourate $nextNumber',
            surahArabicName: meta['name']?.toString() ?? '',
            surahMeta: meta,
            ayahs: ayahsRaw
                .map((e) => {
                      'numberInSurah': e['number'] ?? e['numberInSurah'] ?? 1,
                      'arabic': e['arabic']?.toString() ?? e['text']?.toString() ?? '',
                      if (e['translation'] != null) 'translation': e['translation'].toString(),
                    })
                .toList(),
            initialAyahIndex: 0,
            initialTranslationEdition: _translationEdition,
            initialShowTranslation: _showTranslation,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _hasStarted = false;
      });
    }
  }
}

class _OptionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: IslamicColors.emeraldGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahReaderTile extends StatelessWidget {
  final int number;
  final String arabic;
  final String? translation;
  final bool showTranslation;
  final bool isActive;
  final double progress;
  final VoidCallback onTap;
  final double arabicScale;
  final bool tajweedEnabled;
  final Color activeAccent;
  final VoidCallback? onPinchStart;
  final ValueChanged<double>? onPinchUpdate;
  final VoidCallback? onPinchEnd;

  const _AyahReaderTile({
    super.key,
    required this.number,
    required this.arabic,
    required this.translation,
    required this.showTranslation,
    required this.isActive,
    required this.progress,
    required this.onTap,
    this.arabicScale = 1.0,
    this.tajweedEnabled = false,
    this.activeAccent = IslamicColors.emeraldGreen,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseColor = isActive ? cs.surfaceTint.withValues(alpha: 0.15) : cs.surface;
    final borderColor = isActive ? IslamicColors.emeraldGreen : cs.outlineVariant.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: activeAccent.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Progress overlay
            if (isActive && progress > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: activeAccent.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [activeAccent, IslamicColors.roseGold],
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
                  const SizedBox(width: 12),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.equalizer, size: 16, color: activeAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Lecture en cours',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: activeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (arabic.isNotEmpty)
                GestureDetector(
                  onScaleStart: (_) => onPinchStart?.call(),
                  onScaleUpdate: (details) => onPinchUpdate?.call(details.scale),
                  onScaleEnd: (_) => onPinchEnd?.call(),
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TajweedHighlighter.buildCached(
                      text: arabic,
                      enableTajweed: tajweedEnabled,
                      baseStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.8,
                            fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 22) * arabicScale,
                            color: isActive ? activeAccent : cs.onSurface.withValues(alpha: 0.9),
                          ) ??
                          TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.8,
                            fontSize: 22 * arabicScale,
                            color: isActive ? activeAccent : cs.onSurface.withValues(alpha: 0.9),
                          ),
                    ),
                  ),
                ),
              if (showTranslation && translation != null && translation!.isNotEmpty) ...[
                const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }
}

