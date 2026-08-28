import 'package:flutter/material.dart';

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

  /// Persian (Farsi) UI font.
  static const String fontFamily = 'Vazirmatn';

  /// Decorative font used for the app name only.
  static const String displayFontFamily = 'Lalezar';

  /// Naskh font used for Arabic scripture (Quran, hadith, Nahj al-Balagha).
  /// Vazirmatn is kept as a fallback so no glyph can ever render as tofu.
  static const String arabicFontFamily = 'Amiri';
  static const List<String> arabicFontFallback = <String>[fontFamily];

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w400, color: color),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w400, color: color),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w400, color: color),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w600, color: color),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600, color: color),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: color),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600, color: color),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.8),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.7),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.6),
      labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: color),
      labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: color),
      labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.cream,
      textTheme: _textTheme(HodaColors.inkGreen),
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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.deepGreen,
      textTheme: _textTheme(HodaColors.cream),
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
    return TextStyle(
      fontFamily: displayFontFamily,
      fontSize: size,
      letterSpacing: 1.0,
      color: Theme.of(context).appBarTheme.foregroundColor,
    );
  }
}
