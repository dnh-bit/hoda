import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the appearance choice (light / dark / follow system) and persists it.
///
/// v0.2 adds the «هماهنگ با سیستم» option. The legacy boolean key is still read
/// on first launch after the update, so nobody's dark mode silently flips.
class ThemeController {
  ThemeController._();

  static const String _keyLegacyIsDark = 'hoda_theme_is_dark';
  static const String _keyMode = 'hoda_theme_mode_v2';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  /// Persian label for the active mode, used by the settings screen.
  static String labelFor(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return 'روشن';
      case ThemeMode.dark:
        return 'شب';
      case ThemeMode.system:
        return 'سیستم';
    }
  }

  static IconData iconFor(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Reads the stored preference. Safe to call before `runApp`.
  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_keyMode);
      if (stored != null) {
        mode.value = _parse(stored);
        return;
      }
      // Migration path from 0.1.x.
      final bool legacyDark = prefs.getBool(_keyLegacyIsDark) ?? false;
      mode.value = legacyDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Keep the default light theme when preferences are unavailable.
    }
  }

  static ThemeMode _parse(String raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String _serialize(ThemeMode value) {
    switch (value) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  static void setMode(ThemeMode value) {
    if (mode.value == value) return;
    mode.value = value;
    _persist(value);
  }

  /// Cycles light → dark → system, for the app bar quick toggle.
  static void cycle() {
    switch (mode.value) {
      case ThemeMode.light:
        setMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        setMode(ThemeMode.light);
        break;
    }
  }

  static void toggle() => setDark(!isDark);

  static void setDark(bool dark) =>
      setMode(dark ? ThemeMode.dark : ThemeMode.light);

  static Future<void> _persist(ThemeMode value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMode, _serialize(value));
      // Keep the legacy key roughly in sync for a rollback to 0.1.x.
      await prefs.setBool(_keyLegacyIsDark, value == ThemeMode.dark);
    } catch (_) {
      // Best-effort: the in-memory theme still applies for this session.
    }
  }
}
