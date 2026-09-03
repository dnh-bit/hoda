import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------------
/// Hoda design system — colour tokens.
///
/// The palette of the original app is preserved (deep green / turquoise / gold
/// / cream); it is only *extended* with the intermediate steps a modern UI
/// needs: sunken surfaces, elevated surfaces, hairline borders, muted text and
/// glow colours for the ambient background.
/// ---------------------------------------------------------------------------
class HodaColors {
  HodaColors._();

  // Greens (brand core)
  static const Color inkGreen = Color(0xFF08261C);
  static const Color nightBase = Color(0xFF061E16);
  static const Color deepGreen = Color(0xFF0B3D2E);
  static const Color forestGreen = Color(0xFF10593F);
  static const Color midGreen = Color(0xFF146B4C);
  static const Color turquoise = Color(0xFF1F9E8E);
  static const Color turquoiseLight = Color(0xFF6FD3C4);
  static const Color turquoiseGlow = Color(0xFF9CE8DC);

  // Gold (accent)
  static const Color goldDeep = Color(0xFFA8871C);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE6C965);
  static const Color goldGlow = Color(0xFFF6E5AE);

  // Paper (light mode)
  static const Color cream = Color(0xFFF7F3E8);
  static const Color creamCard = Color(0xFFFFFDF6);
  static const Color creamSunken = Color(0xFFF1EBDB);

  // Night surfaces (dark mode)
  static const Color nightSurface = Color(0xFF0E3527);
  static const Color nightSurfaceHigh = Color(0xFF124532);
  static const Color nightSunken = Color(0xFF0A2C20);

  // Text
  static const Color mutedLight = Color(0xFF5E7A6E);
  static const Color mutedDark = Color(0xFF9FBDB0);

  // Category hues (earthy companions to the brand palette)
  static const Color clay = Color(0xFFA6603F);
  static const Color clayLight = Color(0xFFD79A78);
  static const Color mint = Color(0xFF62C79A);
  static const Color deepTurquoise = Color(0xFF12857A);

  // Semantic
  static const Color danger = Color(0xFFB3423B);
  static const Color dangerLight = Color(0xFFE98A83);
}

/// Corner radii used across the app. Consistency here is most of what makes a
/// UI feel designed rather than assembled.
class HodaRadius {
  HodaRadius._();
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Spacing scale (4pt based).
class HodaSpace {
  HodaSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

/// Motion tokens — one place to keep every animation feeling like one app.
class HodaMotion {
  HodaMotion._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration reveal = Duration(milliseconds: 520);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeOutBack;
}

/// ---------------------------------------------------------------------------
/// Theme extension carrying every semantic colour the widgets need.
///
/// Widgets read `HodaPalette.of(context)` instead of hard-coding light/dark
/// branches, which is what keeps both themes looking deliberate.
/// ---------------------------------------------------------------------------
@immutable
class HodaPalette extends ThemeExtension<HodaPalette> {
  const HodaPalette({
    required this.isDark,
    required this.pageTop,
    required this.pageBottom,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.brand,
    required this.brandAlt,
    required this.accent,
    required this.accentSoft,
    required this.shadow,
    required this.pattern,
    required this.glowA,
    required this.glowB,
    required this.onHero,
    required this.onHeroMuted,
  });

  final bool isDark;

  /// Ambient page background gradient stops.
  final Color pageTop;
  final Color pageBottom;

  /// Card / sheet surfaces.
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceSunken;

  /// Hairlines.
  final Color border;
  final Color borderStrong;

  /// Text ramp.
  final Color text;
  final Color muted;
  final Color faint;

  /// Brand greens used for gradients and primary emphasis.
  final Color brand;
  final Color brandAlt;

  /// Gold accent.
  final Color accent;
  final Color accentSoft;

  final Color shadow;

  /// Colour of the geometric ornament drawn behind content.
  final Color pattern;

  /// Ambient glow blobs.
  final Color glowA;
  final Color glowB;

  /// Foreground colours on top of the brand gradient (hero, app bar).
  final Color onHero;
  final Color onHeroMuted;

  static const HodaPalette light = HodaPalette(
    isDark: false,
    pageTop: Color(0xFFFBF8EF),
    pageBottom: Color(0xFFF1ECDC),
    surface: HodaColors.creamCard,
    surfaceHigh: Colors.white,
    surfaceSunken: HodaColors.creamSunken,
    border: Color(0x33C9A227),
    borderStrong: Color(0x66C9A227),
    text: HodaColors.inkGreen,
    muted: HodaColors.mutedLight,
    faint: Color(0xFF8FA79B),
    brand: HodaColors.forestGreen,
    brandAlt: HodaColors.turquoise,
    accent: HodaColors.goldDeep,
    accentSoft: Color(0x1FC9A227),
    shadow: Color(0x1A0B3D2E),
    pattern: Color(0x140B3D2E),
    glowA: Color(0x2A6FD3C4),
    glowB: Color(0x22E6C965),
    onHero: Colors.white,
    onHeroMuted: Color(0xCCFFFFFF),
  );

  static const HodaPalette dark = HodaPalette(
    isDark: true,
    pageTop: Color(0xFF0A2E22),
    pageBottom: HodaColors.nightBase,
    surface: HodaColors.nightSurface,
    surfaceHigh: HodaColors.nightSurfaceHigh,
    surfaceSunken: HodaColors.nightSunken,
    border: Color(0x2E6FD3C4),
    borderStrong: Color(0x66E6C965),
    text: HodaColors.cream,
    muted: HodaColors.mutedDark,
    faint: Color(0xFF7C9C90),
    brand: HodaColors.midGreen,
    brandAlt: HodaColors.turquoise,
    accent: HodaColors.goldLight,
    accentSoft: Color(0x24E6C965),
    shadow: Color(0x66000000),
    pattern: Color(0x146FD3C4),
    glowA: Color(0x331F9E8E),
    glowB: Color(0x1FC9A227),
    onHero: Colors.white,
    onHeroMuted: Color(0xCCFFFFFF),
  );

  static HodaPalette of(BuildContext context) =>
      Theme.of(context).extension<HodaPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Page background gradient (top to bottom).
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[pageTop, pageBottom],
      );

  /// The signature green/turquoise diagonal used by heroes and the app bar.
  LinearGradient get heroGradient => LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: isDark
            ? const <Color>[
                HodaColors.deepGreen,
                HodaColors.forestGreen,
                Color(0xFF157763),
              ]
            : const <Color>[
                HodaColors.deepGreen,
                HodaColors.forestGreen,
                HodaColors.turquoise,
              ],
      );

  /// Gold gradient for badges, rings and emphasis.
  LinearGradient get goldGradient => const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[HodaColors.goldLight, HodaColors.gold],
      );

  LinearGradient get turquoiseGradient => const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[HodaColors.turquoiseLight, HodaColors.turquoise],
      );

  /// A soft gradient tint of [color], used for chips and icon badges.
  LinearGradient tintGradient(Color color) => LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: <Color>[
          color.withOpacity(isDark ? 0.30 : 0.20),
          color.withOpacity(isDark ? 0.12 : 0.08),
        ],
      );

  /// Standard card surface: hairline border, soft double shadow.
  BoxDecoration card({
    Color? accentColor,
    double radius = HodaRadius.lg,
    bool elevated = true,
    bool high = false,
  }) {
    final Color line = accentColor == null
        ? border
        : accentColor.withOpacity(isDark ? 0.42 : 0.34);
    return BoxDecoration(
      color: high ? surfaceHigh : surface,
      borderRadius: HodaRadius.all(radius),
      border: Border.all(color: line, width: 1),
      boxShadow: elevated
          ? <BoxShadow>[
              BoxShadow(
                color: shadow,
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: shadow.withOpacity(isDark ? 0.22 : 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  /// Sunken inner panel (used for the Arabic scripture block).
  BoxDecoration inset({
    Color? accentColor,
    double radius = HodaRadius.md,
  }) {
    return BoxDecoration(
      color: isDark ? surfaceSunken : surfaceSunken.withOpacity(0.55),
      borderRadius: HodaRadius.all(radius),
      border: Border.all(
        color: (accentColor ?? accent).withOpacity(isDark ? 0.32 : 0.26),
      ),
    );
  }

  /// Small rounded label.
  BoxDecoration pill(Color color, {double opacity = 0.12}) => BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: HodaRadius.all(HodaRadius.pill),
        border: Border.all(color: color.withOpacity(opacity + 0.16)),
      );

  @override
  HodaPalette copyWith({
    bool? isDark,
    Color? pageTop,
    Color? pageBottom,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? muted,
    Color? faint,
    Color? brand,
    Color? brandAlt,
    Color? accent,
    Color? accentSoft,
    Color? shadow,
    Color? pattern,
    Color? glowA,
    Color? glowB,
    Color? onHero,
    Color? onHeroMuted,
  }) {
    return HodaPalette(
      isDark: isDark ?? this.isDark,
      pageTop: pageTop ?? this.pageTop,
      pageBottom: pageBottom ?? this.pageBottom,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      brand: brand ?? this.brand,
      brandAlt: brandAlt ?? this.brandAlt,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      shadow: shadow ?? this.shadow,
      pattern: pattern ?? this.pattern,
      glowA: glowA ?? this.glowA,
      glowB: glowB ?? this.glowB,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    );
  }

  @override
  HodaPalette lerp(ThemeExtension<HodaPalette>? other, double t) {
    if (other is! HodaPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return HodaPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      pageTop: c(pageTop, other.pageTop),
      pageBottom: c(pageBottom, other.pageBottom),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      brand: c(brand, other.brand),
      brandAlt: c(brandAlt, other.brandAlt),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      shadow: c(shadow, other.shadow),
      pattern: c(pattern, other.pattern),
      glowA: c(glowA, other.glowA),
      glowB: c(glowB, other.glowB),
      onHero: c(onHero, other.onHero),
      onHeroMuted: c(onHeroMuted, other.onHeroMuted),
    );
  }
}

/// ---------------------------------------------------------------------------
/// The two ThemeData objects.
/// ---------------------------------------------------------------------------
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

  /// Persian text needs tighter tracking than the Latin defaults and a generous
  /// line height; both are baked into the scale below.
  static TextTheme _textTheme(HodaPalette palette) {
    final Color color = palette.text;
    TextStyle s(
      double size,
      FontWeight weight, {
      double? height,
      Color? c,
      double tracking = 0,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: c ?? color,
        letterSpacing: tracking,
      );
    }

    return TextTheme(
      displayLarge: s(52, FontWeight.w700, height: 1.15),
      displayMedium: s(42, FontWeight.w700, height: 1.15),
      displaySmall: s(34, FontWeight.w700, height: 1.2),
      headlineLarge: s(30, FontWeight.w700, height: 1.3),
      headlineMedium: s(25, FontWeight.w700, height: 1.35),
      headlineSmall: s(21, FontWeight.w700, height: 1.4),
      titleLarge: s(19, FontWeight.w700, height: 1.45),
      titleMedium: s(16, FontWeight.w700, height: 1.5),
      titleSmall: s(14, FontWeight.w700, height: 1.5),
      bodyLarge: s(15.5, FontWeight.w400, height: 1.9),
      bodyMedium: s(14, FontWeight.w400, height: 1.8),
      bodySmall: s(12.5, FontWeight.w400, height: 1.7, c: palette.muted),
      labelLarge: s(14, FontWeight.w700, height: 1.4),
      labelMedium: s(12.5, FontWeight.w700, height: 1.4),
      labelSmall: s(11, FontWeight.w700, height: 1.4),
    );
  }

  static ThemeData light = _build(HodaPalette.light);
  static ThemeData dark = _build(HodaPalette.dark);

  static ThemeData _build(HodaPalette p) {
    final bool isDark = p.isDark;
    final ColorScheme scheme = isDark
        ? ColorScheme.dark(
            primary: HodaColors.turquoise,
            onPrimary: HodaColors.inkGreen,
            primaryContainer: HodaColors.forestGreen,
            onPrimaryContainer: HodaColors.cream,
            secondary: HodaColors.goldLight,
            onSecondary: HodaColors.inkGreen,
            tertiary: HodaColors.goldLight,
            onTertiary: HodaColors.inkGreen,
            surface: p.surface,
            onSurface: p.text,
            onSurfaceVariant: p.muted,
            outline: p.border,
            outlineVariant: p.border,
            error: HodaColors.dangerLight,
          )
        : ColorScheme.light(
            primary: HodaColors.forestGreen,
            onPrimary: Colors.white,
            primaryContainer: HodaColors.turquoiseLight,
            onPrimaryContainer: HodaColors.inkGreen,
            secondary: HodaColors.turquoise,
            onSecondary: Colors.white,
            tertiary: HodaColors.goldDeep,
            onTertiary: Colors.white,
            surface: p.surface,
            onSurface: p.text,
            onSurfaceVariant: p.muted,
            outline: p.border,
            outlineVariant: p.border,
            error: HodaColors.danger,
          );

    final TextTheme text = _textTheme(p);
    final Color barForeground = isDark ? HodaColors.cream : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[p],
      fontFamily: fontFamily,
      // The ambient gradient is painted by [HodaBackground]; the scaffold sits
      // on the mid tone so any screen without it still looks intentional.
      scaffoldBackgroundColor: p.pageBottom,
      canvasColor: p.pageBottom,
      textTheme: text,
      primaryTextTheme: text,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: barForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: barForeground),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(
          color: isDark ? HodaColors.goldGlow : Colors.white,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? HodaColors.goldGlow : Colors.white,
          size: 22,
        ),
      ),
      cardTheme: CardTheme(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.lg),
          side: BorderSide(color: p.border),
        ),
      ),
      iconTheme: IconThemeData(color: p.muted, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: p.accent,
        textColor: p.text,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: HodaColors.turquoise.withOpacity(isDark ? 0.28 : 0.16),
        side: BorderSide(color: p.border),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.pill),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              isDark ? HodaColors.turquoise : HodaColors.forestGreen,
          foregroundColor: isDark ? HodaColors.inkGreen : Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: HodaRadius.all(HodaRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.surfaceHigh,
          foregroundColor: p.text,
          elevation: 0,
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: HodaRadius.all(HodaRadius.md),
            side: BorderSide(color: p.border),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? HodaColors.goldLight : HodaColors.forestGreen,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.borderStrong),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: HodaRadius.all(HodaRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? HodaColors.goldLight : HodaColors.forestGreen,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: HodaRadius.all(HodaRadius.sm),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? HodaColors.goldGlow : Colors.white;
            }
            return isDark ? HodaColors.mutedDark : Colors.white;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? HodaColors.turquoise : HodaColors.forestGreen;
            }
            return p.surfaceSunken;
          },
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return p.borderStrong;
          },
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: HodaColors.turquoise,
        inactiveTrackColor: p.surfaceSunken,
        thumbColor: isDark ? HodaColors.goldGlow : HodaColors.forestGreen,
        overlayColor: HodaColors.turquoise.withOpacity(0.14),
        trackHeight: 5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HodaColors.turquoise,
        linearMinHeight: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: text.bodyMedium?.copyWith(color: p.faint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: HodaRadius.all(HodaRadius.pill),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: HodaRadius.all(HodaRadius.pill),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HodaRadius.all(HodaRadius.pill),
          borderSide: const BorderSide(color: HodaColors.turquoise, width: 1.6),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.lg),
          side: BorderSide(color: p.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? HodaColors.nightSurfaceHigh : HodaColors.deepGreen,
        contentTextStyle: text.bodyMedium?.copyWith(color: HodaColors.cream),
        actionTextColor: HodaColors.goldLight,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? HodaColors.nightSurfaceHigh : HodaColors.deepGreen,
          borderRadius: HodaRadius.all(HodaRadius.xs),
        ),
        textStyle: text.bodySmall?.copyWith(color: HodaColors.cream),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        dialBackgroundColor: p.surfaceSunken,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.lg),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? HodaColors.turquoise : HodaColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: HodaRadius.all(HodaRadius.md),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// The app name, in the decorative face.
  static TextStyle appNameStyle(
    BuildContext context, {
    double size = 30,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontSize: size,
      letterSpacing: 1.0,
      height: 1.25,
      color: color ??
          Theme.of(context).appBarTheme.foregroundColor ??
          Colors.white,
    );
  }
}
