import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajda/services/quran_api_service.dart';
import 'package:sajda/services/quran_audio_service.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/services/tts_service.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/utils/app_state.dart';
import 'package:sajda/widgets/premium_feature_lock.dart';

class SajdaVersesPage extends StatefulWidget {
  const SajdaVersesPage({Key? key}) : super(key: key);

  @override
  State<SajdaVersesPage> createState() => _SajdaVersesPageState();
}

class _SajdaVersesPageState extends State<SajdaVersesPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();

  List<Map<String, dynamic>> _surahCatalog = [];
  List<Map<String, dynamic>> _verses = [];
  List<Map<String, dynamic>> _translationOptions = [];
  List<Map<String, dynamic>> _reciterOptions = [];

  Map<String, dynamic>? _selectedSurah;
  Map<String, dynamic>? _selectedTranslation;
  Map<String, dynamic>? _selectedReciter;

  bool _isInitializing = true;
  bool _isLoadingSurah = false;
  bool _showTranslation = true;

  String? _initError;
  String? _surahError;

  List<String> _fullSurahUrls = [];
  int? _currentAyahIndex;
  bool _isPlaying = false;
  StreamSubscription<void>? _completionSub;
  bool _isSpeakingTranslation = false;
  int? _currentTranslationIndex;

  @override
  void initState() {
    super.initState();
    _completionSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentAyahIndex = null;
      });
    });
    Future.microtask(() => _ttsService.initialize());
    _loadInitialData();
  }

  @override
  void dispose() {
    _completionSub?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _ttsService.stop();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final surahs = await QuranApiService.getSurahsList();
      final translations = await QuranApiService.getFrenchTranslationsCatalog();
      final reciters = await QuranApiService.getRecitersCatalog();

      Map<String, dynamic>? defaultSurah;
      if (surahs.isNotEmpty) {
        defaultSurah = surahs.firstWhere(
          (s) => (s['number'] as int?) == 1,
          orElse: () => surahs.first,
        );
      }

      Map<String, dynamic>? defaultTranslation;
      if (translations.isNotEmpty) {
        defaultTranslation = translations.firstWhere(
          (t) => t['source'] == 'quran_com' && t['id'] == 131,
          orElse: () => translations.first,
        );
      }

      Map<String, dynamic>? defaultReciter;
      if (reciters.isNotEmpty) {
        defaultReciter = reciters.firstWhere(
          (r) => r['id'] == 7,
          orElse: () => reciters.first,
        );
      }

      setState(() {
        _surahCatalog = surahs;
        _translationOptions = translations;
        _reciterOptions = reciters;
        _selectedSurah = defaultSurah;
        _selectedTranslation = defaultTranslation;
        _selectedReciter = defaultReciter;
        _isInitializing = false;
      });

      if (defaultSurah != null) {
        await _loadSurah(defaultSurah['number'] as int);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadSurah(int surahNumber) async {
    await _stopAudio();
    setState(() {
      _isLoadingSurah = true;
      _surahError = null;
      _verses = [];
      _fullSurahUrls = [];
    });

    try {
      final recitationId = (_selectedReciter != null ? _selectedReciter!['id'] as int? : null) ?? 7;
      final translationId = (_selectedTranslation != null && _selectedTranslation!['source'] == 'quran_com')
          ? _selectedTranslation!['id'] as int?
          : 131;
      final tanzilCode = (_selectedTranslation != null && _selectedTranslation!['source'] == 'tanzil')
          ? _selectedTranslation!['code'] as String?
          : null;

      final payload = await QuranApiService.getSurahWithTranslationAndAudio(
        surahNumber,
        recitationId: recitationId,
        quranComTranslationId: translationId,
        tanzilCode: tanzilCode,
      );

      final arabic = payload['arabic'] as Map<String, dynamic>?;
      final translation = (payload['translation'] ?? payload['english']) as Map<String, dynamic>?;
      final audio = payload['audio'] as Map<String, dynamic>?;

      final combined = _mergeAyahs(
        surahNumber: surahNumber,
        arabic: arabic,
        translation: translation,
        audio: audio,
      );

      final urls = <String>[];
      if (audio != null) {
        final primary = audio['surahUrl'];
        if (primary is String && primary.isNotEmpty) urls.add(primary);
        final list = audio['surahUrls'];
        if (list is List) {
          for (final item in list) {
            if (item is String && item.isNotEmpty && !urls.contains(item)) urls.add(item);
          }
        }
      }
      if (urls.isEmpty) {
        urls.addAll(QuranAudioService.buildFullSurahUrls(surahNumber, recitationId: recitationId));
      }

      if (!mounted) return;
      setState(() {
        _verses = combined;
        _fullSurahUrls = urls;
        _isLoadingSurah = false;
        _surahError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _surahError = e.toString();
        _isLoadingSurah = false;
      });
    }
  }

  List<Map<String, dynamic>> _mergeAyahs({
    required int surahNumber,
    Map<String, dynamic>? arabic,
    Map<String, dynamic>? translation,
    Map<String, dynamic>? audio,
  }) {
    final result = <int, Map<String, dynamic>>{};

    void ensureEntry(int number) {
      result.putIfAbsent(number, () => {
            'number': number,
            'arabic': '',
            'translation': '',
            'audio': '',
            'secondary': <String>[],
          });
    }

    void mergeText(Map<String, dynamic>? source, String key) {
      final ayahs = source?['ayahs'];
      if (ayahs is! List) return;
      for (final raw in ayahs) {
        if (raw is! Map) continue;
        final number = _parseInt(raw['numberInSurah']) ?? _parseInt(raw['number']) ?? _parseInt(raw['ayah']) ?? 0;
        if (number <= 0) continue;
        ensureEntry(number);
        var text = (raw['text'] ?? '').toString();
        if (key == 'translation') {
          text = QuranApiService.sanitizeTranslationText(text);
        }
        result[number]![key] = text;
      }
    }

    mergeText(arabic, 'arabic');
    mergeText(translation, 'translation');

    final audioAyahs = audio?['ayahs'];
    if (audioAyahs is List) {
      for (final raw in audioAyahs) {
        if (raw is! Map) continue;
        final number = _parseInt(raw['numberInSurah']) ?? _parseInt(raw['number']) ?? _parseInt(raw['ayah']) ?? 0;
        if (number <= 0) continue;
        ensureEntry(number);
        final entry = result[number]!;
        final primary = raw['audio'];
        if (primary is String && primary.trim().isNotEmpty) {
          entry['audio'] = primary.trim();
        }
        final secondary = raw['audioSecondary'];
        if (secondary is List) {
          final cleaned = <String>{};
          for (final s in secondary) {
            if (s is String && s.trim().isNotEmpty) cleaned.add(s.trim());
          }
          if (cleaned.isNotEmpty) entry['secondary'] = cleaned.toList();
        }
      }
    }

    if (result.isEmpty && arabic != null) {
      final count = _parseInt(arabic['numberOfAyahs']) ?? 0;
      for (var i = 1; i <= count; i++) {
        ensureEntry(i);
      }
    }

    final orderedKeys = result.keys.toList()..sort();
    final fallbackTemplates = QuranAudioService.buildPerAyahUrlTemplates(surahNumber, recitationId: (_selectedReciter != null ? _selectedReciter!['id'] as int? : null) ?? 7);

    final merged = <Map<String, dynamic>>[];
    for (final key in orderedKeys) {
      final value = result[key]!;
      final audio = value['audio'] as String?;
      final secondary = List<String>.from((value['secondary'] as List));
      if ((audio == null || audio.isEmpty) && fallbackTemplates.isNotEmpty) {
        for (final template in fallbackTemplates) {
          if (!template.contains('%s')) continue;
          final needsPadded = template.contains('_%s');
          final replacement = needsPadded ? key.toString().padLeft(3, '0') : key.toString();
          final candidate = template.replaceFirst('%s', replacement);
          secondary.add(candidate);
        }
      }
      merged.add({
        'number': key,
        'arabic': value['arabic'] as String? ?? '',
        'translation': value['translation'] as String? ?? '',
        'audio': audio ?? '',
        'secondary': secondary,
      });
    }

    return merged;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Future<void> _playAyah(int index) async {
    if (index < 0 || index >= _verses.length) return;
    await _stopTranslationSpeech();
    final verse = _verses[index];
    final candidates = <String>[];
    final first = (verse['audio'] as String?)?.trim();
    if (first != null && first.isNotEmpty) candidates.add(first);
    final secondary = verse['secondary'];
    if (secondary is List) {
      for (final s in secondary) {
        if (s is String && s.isNotEmpty && !candidates.contains(s)) {
          candidates.add(s);
        }
      }
    }

    if (kIsWeb && candidates.isNotEmpty) {
      final badHosts = ['audio.qurancdn.com', 'download.quran.com'];
      final good = <String>[];
      final bad = <String>[];
      for (final url in candidates) {
        final isBad = badHosts.any((host) => url.contains(host));
        (isBad ? bad : good).add(url);
      }
      candidates
        ..clear()
        ..addAll(good)
        ..addAll(bad);
    }

    if (candidates.isEmpty) {
      await _playFullSurah(showToast: true);
      return;
    }

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      if (!candidate.startsWith('http')) continue;
      final uri = Uri.tryParse(candidate);
      if (uri == null) continue;
      try {
        await _audioPlayer.play(UrlSource(candidate));
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
          _currentAyahIndex = index;
        });
        return;
      } catch (e) {
        if (i == candidates.length - 1 && mounted) {
          // Friendly fallback to full surah stream instead of showing raw error
          await _playFullSurah(showToast: true);
        }
      }
    }
  }

  Future<void> _playFullSurah({bool showToast = false}) async {
    if (_fullSurahUrls.isEmpty) return;
    for (var i = 0; i < _fullSurahUrls.length; i++) {
      final url = _fullSurahUrls[i];
      try {
        await _audioPlayer.play(UrlSource(url));
        if (!mounted) return;
        setState(() {
          _isPlaying = true;
          _currentAyahIndex = null;
        });
        if (showToast) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Diffusion de la sourate complète.'),
              backgroundColor: IslamicColors.emeraldGreen,
            ),
          );
        }
        return;
      } catch (e) {
        if (i == _fullSurahUrls.length - 1 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio sourate indisponible: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _currentAyahIndex = null;
    });
    await _stopTranslationSpeech();
  }

  Future<void> _stopTranslationSpeech() async {
    await _ttsService.stop();
    if (!mounted) return;
    setState(() {
      _isSpeakingTranslation = false;
      _currentTranslationIndex = null;
    });
  }

  Future<void> _speakTranslation(int index) async {
    if (index < 0 || index >= _verses.length) return;
    final rawTranslation = (_verses[index]['translation'] as String?) ?? '';
    final content = QuranApiService.sanitizeTranslationText(rawTranslation);
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traduction française indisponible pour ce verset.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isSpeakingTranslation && _currentTranslationIndex == index) {
      await _stopTranslationSpeech();
      return;
    }

    await _stopAudio();
    if (!mounted) return;

    setState(() {
      _isSpeakingTranslation = true;
      _currentTranslationIndex = index;
    });

    try {
      await _ttsService.speakFrench(content);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur TTS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSpeakingTranslation = false;
        if (_currentTranslationIndex == index) {
          _currentTranslationIndex = null;
        }
      });
    }
  }

  Future<void> _completeSurahReading() async {
    final surahNumber = _selectedSurah?['number'];
    if (surahNumber is! int) return;
    await StorageService.addHassanat(100);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('MashaAllah! +100 Hassanates pour la sourate ${_selectedSurah?['englishName'] ?? ''}.'),
            ),
          ],
        ),
        backgroundColor: IslamicColors.emeraldGreen,
      ),
    );
    context.read<AppState>().refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.user.isPremium;

    return Scaffold(
      backgroundColor: IslamicColors.pearlWhite,
      appBar: AppBar(
        title: const Text(
          'Lecture du Coran',
          style: TextStyle(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: IslamicColors.emeraldGreen),
        actions: [
          if (_isPlaying)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              onPressed: _stopAudio,
              tooltip: 'Arrêter',
            ),
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.language,
              color: _showTranslation ? IslamicColors.roseGold : IslamicColors.emeraldGreen,
            ),
            tooltip: _showTranslation ? 'Masquer la traduction' : 'Afficher la traduction',
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
        ],
      ),
      body: _buildBody(isPremium),
    );
  }

  Widget _buildBody(bool isPremium) {
    if (!isPremium) {
      return PremiumFeatureLock(
        child: const SizedBox.shrink(),
        isPremium: false,
        featureName: 'Lecture du Coran',
        description: 'Accédez aux 114 sourates complètes avec audio et traduction.',
      );
    }

    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: IslamicColors.emeraldGreen),
            SizedBox(height: 16),
            Text('Chargement du Coran...'),
          ],
        ),
      );
    }

    if (_initError != null) {
      return _buildErrorState(
        message: _initError!,
        onRetry: _loadInitialData,
      );
    }

    return Column(
      children: [
        _buildHeaderCard(),
        Expanded(
          child: _isLoadingSurah
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: IslamicColors.emeraldGreen),
                  ),
                )
              : _surahError != null
                  ? _buildErrorState(message: _surahError!, onRetry: _retryCurrentSurah)
                  : _verses.isEmpty
                      ? _buildErrorState(
                          message: 'Aucun verset disponible. Réessayez plus tard.',
                          onRetry: _retryCurrentSurah,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _verses.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildAudioBanner();
                            }
                            final verse = _verses[index - 1];
                            return _buildVerseCard(index - 1, verse);
                          },
                        ),
        ),
      ],
    );
  }

  void _retryCurrentSurah() {
    final number = _selectedSurah?['number'];
    if (number is int) {
      _loadSurah(number);
    }
  }

  Widget _buildHeaderCard() {
    final surahName = _selectedSurah?['name'] ?? '';
    final englishName = _selectedSurah?['englishName'] ?? '';
    final translationName = _selectedSurah?['englishNameTranslation'] ?? '';
    final revelation = _selectedSurah?['revelationType'] ?? '';
    final ayahs = _selectedSurah?['numberOfAyahs'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.08),
            IslamicColors.roseGold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: IslamicColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${_selectedSurah?['number'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: IslamicColors.emeraldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      englishName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                    if (translationName.toString().isNotEmpty)
                      Text(
                        translationName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '$ayahs versets • ${revelation == 'Meccan' ? 'Révélée à La Mecque' : 'Révélée à Médine'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedSurah,
                  decoration: InputDecoration(
                    labelText: 'Sourate',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _surahCatalog.map((surah) {
                    final label = '${surah['number']}. ${surah['englishName']} (${surah['numberOfAyahs']} versets)';
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: surah,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedSurah = value);
                    _loadSurah(value['number'] as int);
                  },
                ),
              ),
              if (_translationOptions.isNotEmpty)
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedTranslation,
                    decoration: InputDecoration(
                      labelText: 'Traduction',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _translationOptions.map((option) {
                      final label = option['name']?.toString() ?? 'Traduction';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: option,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTranslation = value);
                      if (_selectedSurah != null) {
                        _loadSurah(_selectedSurah!['number'] as int);
                      }
                    },
                  ),
                ),
              if (_reciterOptions.isNotEmpty)
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedReciter,
                    decoration: InputDecoration(
                      labelText: 'Récitateur',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _reciterOptions.map((option) {
                      final label = option['name']?.toString() ?? 'Reciter';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: option,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedReciter = value);
                      if (_selectedSurah != null) {
                        _loadSurah(_selectedSurah!['number'] as int);
                      }
                    },
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _completeSurahReading,
                icon: const Icon(Icons.star, color: Colors.white),
                label: const Text('Marquer comme lue', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IslamicColors.emeraldGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBanner() {
    if (_fullSurahUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final isFullPlaying = _isPlaying && _currentAyahIndex == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IslamicColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.library_music, color: IslamicColors.emeraldGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lecture continue de la sourate disponible.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (isFullPlaying) {
                _stopAudio();
              } else {
                _playFullSurah();
              }
            },
            icon: Icon(isFullPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white),
            label: Text(isFullPlaying ? 'Arrêter' : 'Sourate complète', style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(int index, Map<String, dynamic> verse) {
    final number = verse['number'];
    final arabic = (verse['arabic'] as String?)?.trim() ?? '';
    final rawTranslation = (verse['translation'] as String?) ?? '';
    final translation = QuranApiService.sanitizeTranslationText(rawTranslation);
    final hasAudio = (verse['audio'] as String?)?.isNotEmpty == true || ((verse['secondary'] as List).isNotEmpty);
    final hasTranslation = translation.isNotEmpty;
    final isPlayingThis = _isPlaying && _currentAyahIndex == index;
    final isSpeakingThisTranslation = _isSpeakingTranslation && _currentTranslationIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPlayingThis ? IslamicColors.roseGold.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [IslamicColors.emeraldGreen, IslamicColors.roseGold]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                 const Spacer(),
                 Wrap(
                   spacing: 8,
                   runSpacing: 8,
                   crossAxisAlignment: WrapCrossAlignment.center,
                   children: [
                     if (hasTranslation)
                       ElevatedButton.icon(
                         onPressed: () => _speakTranslation(index),
                         icon: Icon(
                           isSpeakingThisTranslation ? Icons.stop_circle : Icons.record_voice_over,
                           color: Colors.white,
                         ),
                         label: const Text('Traduction', style: TextStyle(color: Colors.white)),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: isSpeakingThisTranslation ? IslamicColors.roseGold : const Color(0xFF455A64),
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         ),
                       ),
                     hasAudio
                         ? ElevatedButton.icon(
                             onPressed: () => _playAyah(index),
                             icon: Icon(isPlayingThis ? Icons.volume_up : Icons.play_arrow, color: Colors.white),
                             label: const Text('Récitation', style: TextStyle(color: Colors.white)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: isPlayingThis ? IslamicColors.roseGold : IslamicColors.emeraldGreen,
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                             ),
                           )
                         : Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.grey[300],
                               borderRadius: BorderRadius.circular(20),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: const [
                                 Icon(Icons.volume_off, size: 16, color: Colors.grey),
                                 SizedBox(width: 6),
                                 Text('Audio indisponible', style: TextStyle(color: Colors.grey, fontSize: 12)),
                               ],
                             ),
                           ),
                   ],
                 ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              arabic.isNotEmpty ? arabic : '—',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    height: 2,
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            if (_showTranslation && translation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  translation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF455A64), height: 1.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({required String message, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: IslamicColors.roseGold),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: IslamicColors.emeraldGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}