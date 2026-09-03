import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import 'arabic_text.dart';

/// Modern card component for displaying Quranic verses, Hadiths, Nahj wisdoms,
/// and martyr wills with polished islamic aesthetics.
class ContentCard extends StatelessWidget {
  final DailyContent content;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  /// When set, the Persian body is clipped to this many lines (list previews).
  final int? maxPersianLines;

  /// When set, the Arabic body is clipped to this many lines (list previews).
  final int? maxArabicLines;

  /// Optional badge/tag label to display in the header (e.g. 'آیه روز', 'حکمت').
  final String? categoryBadge;

  const ContentCard({
    super.key,
    required this.content,
    required this.borderColor,
    required this.icon,
    this.onTap,
    this.maxPersianLines,
    this.maxArabicLines,
    this.categoryBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? HodaColors.darkSurfaceCard : Colors.white;
    final accent = borderColor;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? HodaColors.darkBorder : accent.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : accent.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: accent.withOpacity(0.08),
          highlightColor: accent.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, color: accent, size: 19),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (categoryBadge != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                categoryBadge!,
                                style: TextStyle(
                                  fontFamily: HodaTheme.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          Text(
                            content.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? HodaColors.cream : HodaColors.deepGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : HodaColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                        ),
                      ),
                  ],
                ),

                // Arabic Script Banner
                if (content.hasArabic) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? HodaColors.darkSurface
                          : HodaColors.cream.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? HodaColors.darkBorder
                            : HodaColors.borderSubtle.withOpacity(0.7),
                      ),
                    ),
                    child: ArabicText(
                      content.arabic,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      maxLines: maxArabicLines,
                    ),
                  ),
                ],

                // Divider or Spacing
                if (content.hasArabic && content.hasPersian)
                  const SizedBox(height: 12)
                else if (content.hasPersian)
                  const SizedBox(height: 10),

                // Persian Translation / Text
                if (content.hasPersian)
                  Text(
                    content.persian,
                    textAlign: TextAlign.justify,
                    maxLines: maxPersianLines,
                    overflow:
                        maxPersianLines == null ? null : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.85,
                      color: isDark ? HodaColors.cream.withOpacity(0.9) : HodaColors.inkGreen,
                    ),
                  ),

                // Bottom Source / Meta Bar
                if (content.hasSource || (content.family != null && content.family!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (content.family != null && content.family!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            content.family!,
                            style: TextStyle(
                              fontFamily: HodaTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      if (content.hasSource)
                        Expanded(
                          flex: 3,
                          child: Text(
                            content.source,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
