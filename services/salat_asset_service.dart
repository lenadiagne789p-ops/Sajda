import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sajda/models/npm_salat_media.dart';
import 'package:sajda/models/salat_course.dart';

/// Loads Salat images and audios from bundled assets by scanning AssetManifest.json
/// Expected directories (you can create any of these and drop files in):
/// - Images
///   • assets/images/salat/learn/
///   • assets/images/salat/mastery/
///   • assets/images/salat/positions/standing/
///   • assets/images/salat/positions/bowing/    (or ruku)
///   • assets/images/salat/positions/prostration/ (or sujud)
///   • assets/images/salat/positions/sitting/   (or julus)
/// - Audios
///   • assets/audio/salat/invocations/
///   • assets/audio/invocations/
///
/// The service gracefully returns empty lists if no matching assets are found.
class SalatAssetService {
  static const _assetManifestPath = 'AssetManifest.json';

  static Future<Map<String, dynamic>> _loadManifest() async {
    final raw = await rootBundle.loadString(_assetManifestPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<List<String>> loadLearnImages() async {
    final manifest = await _loadManifest();
    return _filterImages(manifest, const [
      'assets/images/salat/learn/',
    ]);
  }

  static Future<List<String>> loadMasteryImages() async {
    final manifest = await _loadManifest();
    return _filterImages(manifest, const [
      'assets/images/salat/mastery/',
    ]);
  }

  static Future<Map<SalatStepType, List<String>>> loadPositionImages() async {
    final manifest = await _loadManifest();
    List<String> standing = _filterImages(manifest, const [
      'assets/images/salat/positions/standing/',
      'assets/images/salat/positions/qiyam/',
    ]);
    List<String> bowing = _filterImages(manifest, const [
      'assets/images/salat/positions/bowing/',
      'assets/images/salat/positions/ruku/',
    ]);
    List<String> prostration = _filterImages(manifest, const [
      'assets/images/salat/positions/prostration/',
      'assets/images/salat/positions/sujud/',
    ]);
    List<String> sitting = _filterImages(manifest, const [
      'assets/images/salat/positions/sitting/',
      'assets/images/salat/positions/julus/',
    ]);

    // Si aucun fichier n'est trouvé dans les sous-dossiers "positions/",
    // tenter une détection par mots-clés parmi les photos importées récemment
    // (ex: "ruku-priere-salat.jpg", "prosternation-priere-salat.jpg", etc.).
    if (standing.isEmpty || bowing.isEmpty || prostration.isEmpty || sitting.isEmpty) {
      final keywordMatches = _filterImagesByKeywords(manifest);
      standing = standing.isEmpty ? (keywordMatches[SalatStepType.standing] ?? standing) : standing;
      bowing = bowing.isEmpty ? (keywordMatches[SalatStepType.bowing] ?? bowing) : bowing;
      prostration = prostration.isEmpty ? (keywordMatches[SalatStepType.prostration] ?? prostration) : prostration;
      sitting = sitting.isEmpty ? (keywordMatches[SalatStepType.sitting] ?? sitting) : sitting;
    }

    // Prioriser la dernière capture d'écran ajoutée pour la position assise (Julûs)
    // Exemple de nom courant: assets/images/Capture_d_e_cran_2025-11-05_a_11.17.47.png
    final latestJulusScreenshot = _findLatestScreenshotForJulus(manifest);
    if (latestJulusScreenshot != null) {
      // Éviter les doublons et placer en tête
      sitting = [
        latestJulusScreenshot,
        ...sitting.where((p) => p != latestJulusScreenshot),
      ];
    }

    return {
      SalatStepType.standing: standing,
      SalatStepType.bowing: bowing,
      SalatStepType.prostration: prostration,
      SalatStepType.sitting: sitting,
    };
  }

  /// Load images specifically for the standing-after-bowing (Qawmah / I'tidāl) step.
  ///
  /// Supported directories (create any of these and drop files inside):
  ///   - assets/images/salat/positions/qawmah/
  ///   - assets/images/salat/positions/itidal/
  ///   - assets/images/salat/positions/standing_after_bowing/
  static Future<List<String>> loadQawmahImages() async {
    final manifest = await _loadManifest();
    final direct = _filterImages(manifest, const [
      'assets/images/salat/positions/qawmah/',
      'assets/images/salat/positions/itidal/',
      'assets/images/salat/positions/standing_after_bowing/',
    ]);
    if (direct.isNotEmpty) return direct;
    // Fallback : utiliser les images debout (Qiyâm) si aucune image spécifique Qawmah
    final byKeywords = _filterImagesByKeywords(manifest);
    return byKeywords[SalatStepType.standing] ?? const [];
  }

  static Future<List<NpmAudioItem>> loadInvocationAudios() async {
    final manifest = await _loadManifest();
    final audioPaths = _filterAudios(manifest, const [
      'assets/audio/salat/invocations/',
      'assets/audio/invocations/',
      'assets/audio/salat/',
    ]);

    return audioPaths
        .map((p) => NpmAudioItem(url: p, title: _prettyTitleFromPath(p)))
        .toList(growable: false);
  }

  // For the "Apprendre la Salat" page that previously relied on network scraping.
  static Future<NpmSalatMedia> loadLearnBundle() async {
    final images = await loadLearnImages();
    final audios = await loadInvocationAudios();
    return NpmSalatMedia(imageUrls: images, audios: audios, fetchedAt: DateTime.now());
  }

  static List<String> _filterImages(Map<String, dynamic> manifest, List<String> prefixes) {
    return manifest.keys
        .where((k) => _isImage(k) && prefixes.any((p) => k.startsWith(p)))
        .toList(growable: false);
  }

  /// Détection d'images selon des mots-clés dans le nom de fichier
  /// pour mapper vos photos importées librement dans assets/images/ vers
  /// les types de positions correspondants.
  static Map<SalatStepType, List<String>> _filterImagesByKeywords(Map<String, dynamic> manifest) {
    final keys = manifest.keys
        .where((k) => _isImage(k) && k.startsWith('assets/images/'))
        .toList(growable: false);

    bool matchAny(String lower, List<RegExp> patterns) => patterns.any((re) => re.hasMatch(lower));

    final standingKeys = <String>[];
    final bowingKeys = <String>[];
    final prostrationKeys = <String>[];
    final sittingKeys = <String>[];

    final standingPatterns = <RegExp>[
      RegExp(r'\b(qiyam|qiyâm|standing|debout)\b'),
      RegExp(r'allahu[_\- ]?akbar|takbir|tahrim'),
      RegExp(r'se[-_ ]?tenir[-_ ]?debout'),
      RegExp(r'fatiha'),
    ];
    final bowingPatterns = <RegExp>[
      RegExp(r'ruku|rukoo|inclinaison|bow(ing)?'),
    ];
    final prostrationPatterns = <RegExp>[
      RegExp(r'sujud|sujood|prosternation'),
    ];
    final sittingPatterns = <RegExp>[
      RegExp(r'jul(us|ûs)|sitting|assise|assois'),
      RegExp(r'tashahhud|tachahoud'),
    ];

    for (final k in keys) {
      final lower = k.toLowerCase();
      if (matchAny(lower, standingPatterns)) {
        standingKeys.add(k);
        continue;
      }
      if (matchAny(lower, bowingPatterns)) {
        bowingKeys.add(k);
        continue;
      }
      if (matchAny(lower, prostrationPatterns)) {
        prostrationKeys.add(k);
        continue;
      }
      if (matchAny(lower, sittingPatterns)) {
        sittingKeys.add(k);
        continue;
      }
    }

    return {
      SalatStepType.standing: standingKeys,
      SalatStepType.bowing: bowingKeys,
      SalatStepType.prostration: prostrationKeys,
      SalatStepType.sitting: sittingKeys,
    };
  }

  /// Détecte la "dernière" capture d'écran qui pourra servir pour Julûs,
  /// même si elle n'est pas rangée dans le dossier julus/. Nous cherchons
  /// d'abord dans les dossiers dédiés à Julûs, sinon nous prenons la dernière
  /// capture générique trouvée dans assets/images/ (patterns: capture_d_e_cran, screenshot, screen_shot).
  static String? _findLatestScreenshotForJulus(Map<String, dynamic> manifest) {
    // 1) Si des images existent dans les dossiers julus/sitting, on regarde
    //    si l'une d'elles semble être une capture (parfois renommée)
    final sittingPaths = manifest.keys
        .where((k) => _isImage(k) && (k.startsWith('assets/images/salat/positions/sitting/') || k.startsWith('assets/images/salat/positions/julus/')))
        .toList(growable: false);

    final captureLike = sittingPaths.where((k) => _looksLikeScreenshot(k)).toList(growable: false);
    if (captureLike.isNotEmpty) {
      captureLike.sort();
      return captureLike.last; // lexicographiquement "dernière"
    }

    // 2) Sinon, balayer toutes les images d'actifs (n'importe où sous assets/)
    //    et choisir la « dernière » capture trouvée (lexicographiquement)
    final genericCaptures = manifest.keys
        .where((k) => _isImage(k) && k.startsWith('assets/') && _looksLikeScreenshot(k))
        .toList(growable: false);
    if (genericCaptures.isNotEmpty) {
      genericCaptures.sort();
      return genericCaptures.last;
    }
    return null;
  }

  static bool _looksLikeScreenshot(String path) {
    final lower = path.toLowerCase();
    return lower.contains('capture_d_e_cran') ||
        lower.contains('screenshot') ||
        lower.contains('screen_shot') ||
        lower.contains('screen-shot');
  }

  static List<String> _filterAudios(Map<String, dynamic> manifest, List<String> prefixes) {
    return manifest.keys
        .where((k) => _isAudio(k) && prefixes.any((p) => k.startsWith(p)))
        .toList(growable: false);
  }

  static bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp') || lower.endsWith('.gif');
  }

  static bool _isAudio(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') || lower.endsWith('.aac') || lower.endsWith('.m4a') || lower.endsWith('.ogg') || lower.endsWith('.wav');
  }

  static String _prettyTitleFromPath(String path) {
    // assets/audio/salat/invocations/takbir_allahu_akbar.mp3 -> "takbir allahu akbar"
    final file = path.split('/').last;
    final name = file.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    return name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }
}
