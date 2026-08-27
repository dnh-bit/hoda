import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HodaColors {
  static const Color deepGreen = Color(0xFF0B3D2E);
  static const Color forestGreen = Color(0xFF10593F);
  static const Color turquoise = Color(0xFF1F9E8E);
  static const Color turquoiseLight = Color(0xFF6FD3C4);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE6C965);
  static const Color cream = Color(0xFFF7F3E8);
  static const Color creamCard = Color(0xFFFFFDF6);
  static const Color inkGreen = Color(0xFF08261C);
}

class HodaTheme {
  HodaTheme._();

  static TextTheme _textTheme(TextTheme base, Color color) {
    return GoogleFonts.vazirmatnTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    const scheme = ColorScheme.light(
      primary: HodaColors.forestGreen,
      onPrimary: HodaColors.cream,
      secondary: HodaColors.turquoise,
      onSecondary: Colors.white,
      surface: HodaColors.creamCard,
      onSurface: HodaColors.inkGreen,
      tertiary: HodaColors.gold,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.cream,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, HodaColors.inkGreen),
      appBarTheme: const AppBarTheme(
        backgroundColor: HodaColors.forestGreen,
        foregroundColor: HodaColors.cream,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: HodaColors.creamCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HodaColors.creamCard,
        selectedItemColor: HodaColors.turquoise,
        unselectedItemColor: Color(0xFF7A8A82),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    const scheme = ColorScheme.dark(
      primary: HodaColors.turquoise,
      onPrimary: HodaColors.inkGreen,
      secondary: HodaColors.goldLight,
      onSecondary: HodaColors.inkGreen,
      surface: HodaColors.forestGreen,
      onSurface: HodaColors.cream,
      tertiary: HodaColors.goldLight,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.deepGreen,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, HodaColors.cream),
      appBarTheme: const AppBarTheme(
        backgroundColor: HodaColors.deepGreen,
        foregroundColor: HodaColors.goldLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: HodaColors.forestGreen,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HodaColors.deepGreen,
        selectedItemColor: HodaColors.goldLight,
        unselectedItemColor: Color(0xFF6E8B80),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextStyle appNameStyle(BuildContext context, {double size = 30}) {
    return GoogleFonts.lalezar(
      fontSize: size,
      letterSpacing: 1.0,
      color: Theme.of(context).appBarTheme.foregroundColor,
    );
  }
}

class ThemeController {
  ThemeController._();
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static const String _prefsKey = 'hoda_theme_is_dark';

  static Future<void> load() async {}

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
