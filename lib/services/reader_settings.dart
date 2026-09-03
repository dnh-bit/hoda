import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading preferences for the detail screen: text size and whether the
/// translation is justified.
///
/// Scripture apps live or die by legibility, and «فونت کوچک است» is the single
/// most common complaint about them — so the size control is one tap away on
/// every content page and is remembered forever.
class ReaderSettings {
  ReaderSettings._();

  static const String _keyScale = 'hoda_reader_scale_v1';
  static const String _keyJustify = 'hoda_reader_justify_v1';

  static const double minScale = 0.9;
  static const double maxScale = 1.6;
  static const double step = 0.1;

  /// Multiplier applied to body and Arabic text on reading screens.
  static final ValueNotifier<double> scale = ValueNotifier<double>(1.0);

  /// Justified Persian paragraphs (on by default — it is how books set them).
  static final ValueNotifier<bool> justify = ValueNotifier<bool>(true);

  static bool _loaded = false;

  static bool get canGrow => scale.value < maxScale - 0.001;
  static bool get canShrink => scale.value > minScale + 0.001;

  /// «۱۰۰٪» label for the current scale.
  static int get percent => (scale.value * 100).round();

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final double stored = prefs.getDouble(_keyScale) ?? 1.0;
      scale.value = stored.clamp(minScale, maxScale);
      justify.value = prefs.getBool(_keyJustify) ?? true;
    } catch (_) {
      // Defaults are perfectly usable.
    }
    _loaded = true;
  }

  static void grow() => setScale(scale.value + step);

  static void shrink() => setScale(scale.value - step);

  static void setScale(double value) {
    final double next =
        double.parse(value.clamp(minScale, maxScale).toStringAsFixed(2));
    if (next == scale.value) return;
    scale.value = next;
    _persistDouble(_keyScale, next);
  }

  static void setJustify(bool value) {
    if (justify.value == value) return;
    justify.value = value;
    _persistBool(_keyJustify, value);
  }

  static Future<void> _persistDouble(String key, double value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (_) {
      // Ignored on purpose.
    }
  }

  static Future<void> _persistBool(String key, bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Ignored on purpose.
    }
  }
}
