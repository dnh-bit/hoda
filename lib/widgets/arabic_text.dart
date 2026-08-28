import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Renders Arabic scripture (Quran, hadith, Nahj al-Balagha, adhkar) with a
/// proper Naskh face and RTL-safe typography.
///
/// Why this widget exists: Arabic scripture used to inherit the Persian UI
/// text theme (Vazirmatn, line height ~1.7, no explicit text direction).
/// Vazirmatn is a Latin/Persian sans face, so vocalised Quranic text came out
/// cramped, with clipped tashkeel and wrong-looking joins, and lines that
/// start with punctuation or digits could flip to LTR. Arabic text must
/// therefore always be rendered through this widget:
/// * [HodaTheme.arabicFontFamily] (Amiri, a Naskh face with full Quranic
///   mark coverage) with Vazirmatn as a fallback,
/// * `textDirection: TextDirection.rtl`,
/// * generous line height (1.8–2.1) so tashkeel is never clipped,
/// * `letterSpacing: 0`, which is mandatory for cursive Arabic joins.
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
  static const double defaultHeight = 1.95;
  static const double defaultFontSize = 22;

  /// Arabic text style, reusable outside of this widget (spans, rich text...).
  static TextStyle style(
    BuildContext context, {
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    final theme = Theme.of(context);
    return TextStyle(
      fontFamily: HodaTheme.arabicFontFamily,
      fontFamilyFallback: HodaTheme.arabicFontFallback,
      fontSize: fontSize ?? defaultFontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? theme.textTheme.titleLarge?.color,
      height: height ?? defaultHeight,
      // Cursive Arabic breaks apart with any letter spacing.
      letterSpacing: 0,
      wordSpacing: 1.5,
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
        leading: 0.2,
        forceStrutHeight: false,
      ),
    );
  }
}
