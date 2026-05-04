import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôleur global du thème (clair / sombre / système).
class ThemeController {
  ThemeController._();

  static const String _themeModeKey = 'app_theme_mode';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Charge le thème sauvegardé au démarrage de l'application.
  static Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);
      mode.value = _decode(saved);
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  /// Définit et persiste le mode de thème.
  static Future<void> set(ThemeMode newMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _encode(newMode));
    } catch (_) {}
    mode.value = newMode;
  }

  /// Bascule entre mode clair et mode sombre.
  static Future<void> toggle() async {
    final current = mode.value;
    final next = (current == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }

  static bool get isDark => mode.value == ThemeMode.dark;

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
