import 'package:flutter/material.dart';

class HodaColors {
  // Primary brand palette
  static const Color deepGreen = Color(0xFF092E23);      // Deep spiritual emerald
  static const Color forestGreen = Color(0xFF0F4B38);    // Rich Islamic green
  static const Color emerald = Color(0xFF13674E);        // Vibrant primary accent
  static const Color turquoise = Color(0xFF1E8C7A);      // Bright teal
  static const Color turquoiseLight = Color(0xFF52C4B3); // Fresh mint highlight
  static const Color turquoiseSoft = Color(0xFFE3F5F1);  // Gentle teal tint

  // Gold accent palette
  static const Color goldDark = Color(0xFF9E7B15);       // Rich antique gold
  static const Color gold = Color(0xFFD4AF37);           // Classic Islamic gold
  static const Color goldLight = Color(0xFFF2D974);      // Shimmering soft gold
  static const Color goldWarm = Color(0xFFFFF9E6);       // Warm parchment gold tint

  // Neutral & background palette (Light)
  static const Color cream = Color(0xFFF8F6F0);          // Soft luxury cream
  static const Color creamCard = Color(0xFFFFFFFF);      // Crisp pure white surface
  static const Color surfaceMuted = Color(0xFFF2EEE4);   // Secondary container
  static const Color borderSubtle = Color(0xFFE5DECF);   // Gentle dividing line
  static const Color inkGreen = Color(0xFF0A221A);       // Near-black deep green
  static const Color textMuted = Color(0xFF5D7068);      // Elegant secondary text

  // Dark palette
  static const Color darkBg = Color(0xFF071B14);         // Midnight emerald
  static const Color darkSurface = Color(0xFF0E2C22);    // Elevated dark surface
  static const Color darkSurfaceCard = Color(0xFF143B2E);// Higher card layer
  static const Color darkBorder = Color(0xFF1E4F3E);     // Dark card border
  static const Color darkTextMuted = Color(0xFF94ABA0);  // Subtle dark text
}

class HodaTheme {
  HodaTheme._();

  /// Persian (Farsi) UI font.
  static const String fontFamily = 'Vazirmatn';

  /// Decorative font used for titles and brand identity.
  static const String displayFontFamily = 'Lalezar';

  /// Naskh font used for Arabic scripture (Quran, Hadith, Nahj al-Balagha).
  static const String arabicFontFamily = 'Amiri';
  static const List<String> arabicFontFallback = <String>[fontFamily];

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 52, fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -0.5),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 40, fontWeight: FontWeight.w700, color: primaryText),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: primaryText),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: primaryText),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: primaryText),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: primaryText),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: primaryText),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, color: primaryText, height: 1.85),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 13.5, fontWeight: FontWeight.w400, color: secondaryText, height: 1.75),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: secondaryText, height: 1.6),
      labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 13.5, fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 11.5, fontWeight: FontWeight.w600, color: secondaryText),
      labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: secondaryText),
    );
  }

  static ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    const scheme = ColorScheme.light(
      primary: HodaColors.forestGreen,
      onPrimary: Colors.white,
      primaryContainer: HodaColors.turquoiseSoft,
      onPrimaryContainer: HodaColors.deepGreen,
      secondary: HodaColors.turquoise,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD6F3ED),
      onSecondaryContainer: HodaColors.deepGreen,
      tertiary: HodaColors.goldDark,
      onTertiary: Colors.white,
      tertiaryContainer: HodaColors.goldWarm,
      onTertiaryContainer: Color(0xFF5F4700),
      surface: HodaColors.creamCard,
      onSurface: HodaColors.inkGreen,
      surfaceVariant: HodaColors.surfaceMuted,
      onSurfaceVariant: HodaColors.textMuted,
      outline: HodaColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.cream,
      textTheme: _textTheme(HodaColors.inkGreen, HodaColors.textMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: HodaColors.forestGreen,
        foregroundColor: HodaColors.cream,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: HodaColors.cream,
        ),
      ),
      cardTheme: CardTheme(
        color: HodaColors.creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: HodaColors.borderSubtle, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HodaColors.surfaceMuted,
        selectedColor: HodaColors.forestGreen,
        secondarySelectedColor: HodaColors.forestGreen,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(
        color: HodaColors.borderSubtle,
        thickness: 1,
        space: 20,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: HodaColors.forestGreen,
        unselectedItemColor: Color(0xFF8A9C94),
        selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    const scheme = ColorScheme.dark(
      primary: HodaColors.turquoiseLight,
      onPrimary: HodaColors.darkBg,
      primaryContainer: HodaColors.darkSurfaceCard,
      onPrimaryContainer: HodaColors.turquoiseLight,
      secondary: HodaColors.goldLight,
      onSecondary: HodaColors.darkBg,
      secondaryContainer: Color(0xFF283F34),
      onSecondaryContainer: HodaColors.goldLight,
      tertiary: HodaColors.goldLight,
      onTertiary: HodaColors.darkBg,
      surface: HodaColors.darkSurface,
      onSurface: HodaColors.cream,
      surfaceVariant: HodaColors.darkSurfaceCard,
      onSurfaceVariant: HodaColors.darkTextMuted,
      outline: HodaColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: HodaColors.darkBg,
      textTheme: _textTheme(HodaColors.cream, HodaColors.darkTextMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: HodaColors.darkBg,
        foregroundColor: HodaColors.goldLight,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: HodaColors.goldLight,
        ),
      ),
      cardTheme: CardTheme(
        color: HodaColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: HodaColors.darkBorder, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HodaColors.darkSurfaceCard,
        selectedColor: HodaColors.turquoise,
        secondarySelectedColor: HodaColors.turquoise,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(
        color: HodaColors.darkBorder,
        thickness: 1,
        space: 20,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HodaColors.darkSurface,
        selectedItemColor: HodaColors.turquoiseLight,
        unselectedItemColor: Color(0xFF6B8A7E),
        selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
