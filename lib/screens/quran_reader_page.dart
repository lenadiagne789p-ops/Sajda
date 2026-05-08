import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/services/quran_audio_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/widgets/ui/gradient_app_bar.dart';
import 'package:sajda/screens/ayah_player_page.dart';
import 'package:sajda/utils/tajweed_highlighter.dart';
import 'package:sajda/utils/performance_monitor.dart';
import 'package:sajda/services/alquran_cloud_service.dart';
import 'package:sajda/widgets/tajweed_legend_widget.dart';

class QuranReaderPage extends StatefulWidget {
  final Map<String, dynamic> surah;
  final int? initialOpenAyahIndex;

  const QuranReaderPage({super.key, required this.surah, this.initialOpenAyahIndex});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  Map<String, dynamic>? _meta;
  List<Map<String, dynamic>> _ayahs = [];

  // Translation
  bool _showTranslation = true;
  String _translationEdition = 'fr.hamidullah';

  // Full-surah audio
  late final AudioPlayer _audioPlayer;
  List<String> _audioCandidates = [];
  bool _isPlaying = false;
  bool _playbackStarted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _lastAudioIndex = 0;

  // Reading preferences
  int _recitationId = 7;
  String _reciterIdentifier = QuranAudioService.defaultReciterIdentifier;
  double _arabicScale = 1.0; // base scale for Arabic script
  bool _tajweed = false;

  String get _reciterLabel =>
      QuranAudioService.reciterNamesExtended[_reciterIdentifier] ??
      QuranAudioService.reciterNames[_recitationId] ??
      'Récitateur';

  Future<void> _showReciterPickerReader(BuildContext ctx) async {
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
                    const Icon(Icons.record_voice_over, color: IslamicColors.emeraldGreen),
                    const SizedBox(width: 10),
                    Text('Choisir un récitateur',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${reciters.length} récitateurs',
                        style: theme.textTheme.labelSmall?.copyWith(color: IslamicColors.emeraldGreen)),
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
                    final isFeatured = QuranAudioService.featuredReciters.contains(r.identifier);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? IslamicColors.emeraldGreen
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.record_voice_over,
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            size: 18),
                      ),
                      title: Text(r.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? IslamicColors.emeraldGreen : null,
                          )),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: IslamicColors.emeraldGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Populaire',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: IslamicColors.emeraldGreen, fontSize: 10)),
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
                        final sn = (widget.surah['number'] as int?) ?? 0;
                        setState(() {
                          _reciterIdentifier = r.identifier;
                          if (sn > 0) {
                            _audioCandidates = QuranAudioService.buildFullSurahUrls(
                              sn,
                              reciterIdentifier: r.identifier,
                            );
                          }
                        });
                        await _audioPlayer.stop();
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

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _attachAudioListeners();
    _loadSurah();
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
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // 1) Fast path: fetch Arabic-only to render instantly
      PerformanceMonitor.startTimer('quran_reader:arabic_only');
      final arabicOnly = await QuranApiService.getSurahForReading(
        surahNumber,
        translationEdition: 'none',
        includeTranslation: false,
      );
      PerformanceMonitor.stopTimer('quran_reader:arabic_only');

      if (!mounted) return;

      final metaMap = arabicOnly['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(arabicOnly['meta'] as Map<String, dynamic>)
          : <String, dynamic>{};

      final ayahList = <Map<String, dynamic>>[];
      if (arabicOnly['ayahs'] is List) {
        for (final item in arabicOnly['ayahs'] as List) {
          if (item is Map) {
            ayahList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        _meta = metaMap;
        _ayahs = ayahList;
        _isLoading = false; // show Arabic immediately
        _hasError = false;
        _translationEdition = targetEdition;
        _audioCandidates = QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: _recitationId);
      });
      final idx = widget.initialOpenAyahIndex;
      if (idx != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openAyahPlayer(idx));
      }

      // 2) Background: fetch translation and merge when ready
      unawaited(_loadAndMergeTranslation(surahNumber, targetEdition));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAndMergeTranslation(int surahNumber, String edition) async {
    try {
      PerformanceMonitor.startTimer('quran_reader:translation');
      final withTr = await QuranApiService.getSurahForReading(
        surahNumber,
        translationEdition: edition,
        includeTranslation: true,
      );
      PerformanceMonitor.stopTimer('quran_reader:translation');
      if (!mounted) return;
      if (withTr['ayahs'] is! List) return;
      final transAyahs = List<Map<String, dynamic>>.from(withTr['ayahs'] as List);
      final trByNumber = <int, String>{};
      for (final a in transAyahs) {
        final n = (a['number'] as int?) ?? 0;
        final t = a['translation']?.toString();
        if (n > 0 && t != null && t.isNotEmpty) trByNumber[n] = t;
      }
      if (trByNumber.isEmpty) return;
      setState(() {
        for (var i = 0; i < _ayahs.length; i++) {
          final n = (_ayahs[i]['number'] as int?) ?? 0;
          final t = trByNumber[n];
          if (t != null && t.isNotEmpty) {
            _ayahs[i] = {
              ..._ayahs[i],
              'translation': t,
            };
          }
        }
      });
    } catch (_) {
      // Ignore translation failures silently (Arabic already shown)
    }
  }

  String _translationLabel(String code) {
    final label = QuranApiService.availableEditions[code];
    if (label != null && label.isNotEmpty) return label;
    return code;
  }

  List<String> get _translationChoices {
    final result = <String>{
      'fr.hamidullah',
      'en.sahih',
      'en.pickthall',
      'en.asad',
      _translationEdition,
    };
    return result.toList()..sort();
  }

  Future<void> _startPlayback() async {
    if (_audioCandidates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio indisponible pour cette sourate')),
      );
      return;
    }

    for (int i = 0; i < _audioCandidates.length; i++) {
      final idx = (_lastAudioIndex + i) % _audioCandidates.length;
      final url = _audioCandidates[idx];
      try {
        debugPrint('QuranReaderPage: try play url=$url');
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play(UrlSource(url));
        bool started = false;
        for (int j = 0; j < 12; j++) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;
          if (_isPlaying || _duration > Duration.zero || _position > Duration.zero) {
            started = true;
            break;
          }
        }
        if (!started) {
          debugPrint('QuranReaderPage: url failed to start, trying next');
          continue;
        }
        if (!mounted) return;
        setState(() {
          _playbackStarted = true;
          _lastAudioIndex = idx;
        });
        return;
      } catch (e) {
        final msg = e.toString();
        debugPrint('QuranReaderPage: play error=$msg');
        if (kIsWeb && _looksLikeAutoplayBlocked(msg)) {
          if (!mounted) return;
          await _promptWebUnlockAndRetry(_startPlayback);
          return;
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecture audio indisponible pour le moment')),
    );
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

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final englishName = (_meta?['englishName'] ?? widget.surah['englishName'] ?? '').toString();
    final arabicName = (_meta?['name'] ?? widget.surah['name'] ?? '').toString();
    final int? verseCount = (_meta?['numberOfAyahs'] as int?) ?? (widget.surah['numberOfAyahs'] as int?) ?? _ayahs.length;
    final revelation = (_meta?['revelationType'] ?? widget.surah['revelationType'] ?? '').toString();

    final subtitleParts = <String>[];
    if (arabicName.isNotEmpty) subtitleParts.add(arabicName);
    if (verseCount != null && verseCount > 0) subtitleParts.add('$verseCount versets');
    if (revelation.isNotEmpty) subtitleParts.add(_revelationLabel(revelation));

    return Scaffold(
      // Use solid background to avoid rare web canvas asserts on transparent routes
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _AyahSkeleton();
                  },
                  childCount: 6,
                ),
              ),
            )
          else if (_hasError)
            SliverToBoxAdapter(child: _buildErrorState(context))
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildAudioAndOptionsCard(),
              ),
            ),
            if (_ayahs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ayah = _ayahs[index];
                      final number = (ayah['number'] as int?) ?? (index + 1);
                      final arabic = (ayah['arabic'] ?? '').toString();
                      final translation = ayah['translation']?.toString();
                      return _ClickableAyahTile(
                        number: number,
                        arabic: arabic,
                        translation: translation,
                        showTranslation: _showTranslation,
                        arabicScale: _arabicScale,
                        tajweedEnabled: _tajweed,
                        onTap: () => _openAyahPlayer(index),
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
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Contenu indisponible pour le moment',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      // Removed the "Lire la sourate entière" bottom bar to keep only
      // the verse-by-verse reader as the main flow.
      bottomNavigationBar: null,
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

  Widget _buildAudioAndOptionsCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = (_meta?['englishName'] ?? widget.surah['englishName'] ?? 'Sourate').toString();

    return Material(
      color: theme.cardTheme.color ?? cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + audio controls
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: _isPlaying ? 'Pause' : 'Lecture',
                  onPressed: _togglePlayPause,
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: IslamicColors.emeraldGreen),
                  iconSize: 36,
                ),
                IconButton(
                  tooltip: 'Arrêter',
                  onPressed: _stopPlayback,
                  icon: Icon(Icons.stop_circle, color: cs.error),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_formatDuration(_position), style: theme.textTheme.labelSmall),
                Expanded(
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(0, (_duration.inSeconds > 0 ? _duration.inSeconds : 1).toDouble()),
                    min: 0,
                    max: (_duration.inSeconds > 0 ? _duration.inSeconds : (_position.inSeconds + 1)).toDouble(),
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.round()));
                    },
                  ),
                ),
                Text(_formatDuration(_duration), style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openAyahPlayer(0),
                icon: const Icon(Icons.subtitles, color: IslamicColors.emeraldGreen),
                label: const Text('Suivi automatique des versets'),
              ),
            ),
            const SizedBox(height: 8),
            // Reading options: Reciter, Tajwid, Zoom
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Bouton récitateur étendu (22+ récitateurs via API)
                GestureDetector(
                  onTap: () => _showReciterPickerReader(context),
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
                          _reciterLabel,
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        const Icon(Icons.help_outline, size: 16, color: IslamicColors.emeraldGreen),
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
                  onSelected: (_) => _showZoomSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Translation controls
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
                PopupMenuButton<String>(
                  tooltip: 'Changer de traduction',
                  onSelected: (code) => _loadSurah(overrideTranslation: code),
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
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _showTranslation,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _showTranslation = value),
              title: Text('Afficher la traduction', style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showZoomSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<double>(
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
    if (selected != null) {
      setState(() => _arabicScale = selected);
    }
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

  // Ouvre le lecteur plein écran (nouvelle fenêtre) au verset indiqué
  void _openAyahPlayer(int initialIndex) {
    debugPrint('QuranReaderPage:_openAyahPlayer -> initialIndex=$initialIndex, ayahs=${_ayahs.length}');
    if (_ayahs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versets indisponibles pour cette sourate.')),
      );
      return;
    }

    final dynamic rawNumber = widget.surah['number'] ?? _meta?['number'] ?? _meta?['surahNumber'];
    final String rawNumberText = rawNumber == null ? '' : rawNumber.toString();
    final int surahNumber = rawNumber is int ? rawNumber : int.tryParse(rawNumberText) ?? 0;
    if (surahNumber <= 0) {
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

    final navigator = Navigator.of(context, rootNavigator: true);
    debugPrint('QuranReaderPage:navigate -> AyahPlayerPage(surah=$surahNumber)');
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
  }

  // (Removed) Bottom CTA for full-surah reading
}

class _ClickableAyahTile extends StatelessWidget {
  final int number;
  final String arabic;
  final String? translation;
  final bool showTranslation;
  final VoidCallback? onTap;
  final double arabicScale;
  final bool tajweedEnabled;

  const _ClickableAyahTile({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.showTranslation,
    this.onTap,
    this.arabicScale = 1.0,
    this.tajweedEnabled = false,
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
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
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
                    const SizedBox(width: 8),
                    const Icon(Icons.open_in_new, color: IslamicColors.emeraldGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                if (arabic.isNotEmpty)
                  RichText(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    text: TajweedHighlighter.buildCached(
                      text: arabic,
                      enableTajweed: tajweedEnabled,
                      baseStyle: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 28 * arabicScale,
                            height: 2,
                            fontWeight: FontWeight.w600,
                            color: IslamicColors.emeraldGreen,
                          ) ??
                          TextStyle(
                            fontSize: 28 * arabicScale,
                            height: 2,
                            fontWeight: FontWeight.w600,
                            color: IslamicColors.emeraldGreen,
                          ),
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

class _AyahSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 24,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
