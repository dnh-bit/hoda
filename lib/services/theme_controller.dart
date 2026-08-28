import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the light/dark theme choice and persists it across launches.
class ThemeController {
  ThemeController._();

  static const String _keyIsDark = 'hoda_theme_is_dark';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  /// Reads the stored preference. Safe to call before `runApp`.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIsDark = prefs.getBool(_keyIsDark) ?? false;
      mode.value = savedIsDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Keep the default light theme when preferences are unavailable.
    }
  }

  static void toggle() => setDark(!isDark);

  static void setDark(bool dark) {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    _persist(dark);
  }

  static Future<void> _persist(bool dark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsDark, dark);
    } catch (_) {
      // Best-effort: the in-memory theme still applies for this session.
    }
  }
}
