import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Simple global controller to manage app locale changes without heavy setup.
class LanguageController {
  LanguageController._();

  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('fr'));

  static final StreamController<Locale> _localeChangedController =
      StreamController<Locale>.broadcast();
  static Stream<Locale> get onLocaleChanged => _localeChangedController.stream;

  /// Load saved language at app start. Defaults to 'fr'.
  static Future<void> loadSaved() async {
    final code = await StorageService.getLanguageCode();
    final loc = Locale(code);
    locale.value = loc;
    if (!_localeChangedController.isClosed) {
      _localeChangedController.add(loc);
    }
  }

  /// Persist and broadcast a new language code: 'fr', 'en', or 'ar'.
  static Future<void> setLanguage(String code) async {
    // Accept only supported codes, default to 'fr'
    final supported = {'fr', 'en', 'ar'};
    final normalized = supported.contains(code) ? code : 'fr';
    await StorageService.setLanguageCode(normalized);
    final loc = Locale(normalized);
    locale.value = loc;
    if (!_localeChangedController.isClosed) {
      _localeChangedController.add(loc);
    }
  }
}
