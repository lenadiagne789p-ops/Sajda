import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  Completer<void>? _activeCompleter;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(kIsWeb ? 0.6 : 0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _activeCompleter?..complete();
        _activeCompleter = null;
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _activeCompleter?..complete();
        _activeCompleter = null;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> speakArabic(String text) async {
    await initialize();
    try {
      await _startSpeaking(text, language: 'ar');
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> speakFrench(String text) async {
    await initialize();
    try {
      await _startSpeaking(text, language: 'fr-FR');
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      _activeCompleter?..complete();
      _activeCompleter = null;
    } catch (_) {}
  }

  Future<void> _startSpeaking(String text, {required String language}) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    _activeCompleter?..complete();
    _activeCompleter = Completer<void>();
    await _tts.setLanguage(language);
    await _tts.speak(text);
    await _activeCompleter?.future;
  }

  void dispose() {
    // FlutterTts has no explicit dispose; stop to release audio focus
    _tts.stop();
  }
}