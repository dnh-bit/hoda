import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Renders Arabic scripture (Quran, hadith, Nahj al-Balagha, adhkar) with a
/// proper Naskh face (Amiri) and RTL-safe typography.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.height,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final double? height;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Comfortable reading height for vocalised Arabic.
  static const double defaultHeight = 2.05;
  static const double defaultFontSize = 21;

  /// Arabic text style, reusable outside of this widget (spans, rich text...).
  static TextStyle style(
    BuildContext context, {
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextStyle(
      fontFamily: HodaTheme.arabicFontFamily,
      fontFamilyFallback: HodaTheme.arabicFontFallback,
      fontSize: fontSize ?? defaultFontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? HodaColors.goldLight : HodaColors.deepGreen),
      height: height ?? defaultHeight,
      // Cursive Arabic breaks apart with any letter spacing.
      letterSpacing: 0,
      wordSpacing: 1.8,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Collapses stray spaces/tabs while keeping intentional line breaks.
  static String normalize(String input) =>
      input.trim().replaceAll(RegExp(r'[ \t]+'), ' ');

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style(
      context,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );

    return Text(
      normalize(text),
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines == null ? null : TextOverflow.ellipsis),
      style: effectiveStyle,
      strutStyle: StrutStyle(
        fontFamily: HodaTheme.arabicFontFamily,
        fontSize: effectiveStyle.fontSize,
        height: effectiveStyle.height,
        leading: 0.25,
        forceStrutHeight: false,
      ),
    );
  }
}
