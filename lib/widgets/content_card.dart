import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import 'arabic_text.dart';

/// Standard card used for every piece of content (verse, hadith, martyr will,
/// Nahj wisdom). Arabic and Persian bodies are styled separately.
class ContentCard extends StatelessWidget {
  final DailyContent content;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  /// When set, the Persian body is clipped to this many lines (list previews).
  final int? maxPersianLines;

  /// When set, the Arabic body is clipped to this many lines (list previews).
  final int? maxArabicLines;

  const ContentCard({
    super.key,
    required this.content,
    required this.borderColor,
    required this.icon,
    this.onTap,
    this.maxPersianLines,
    this.maxArabicLines,
  });

  // ───────────────────────── design tokens ─────────────────────────
  /// Card corner radius. Inner blocks step down by 2–4 for optical nesting.
  static const double _radius = 16;
  static const double _innerRadius = 13;
  static const EdgeInsets _cardMargin =
      EdgeInsets.symmetric(horizontal: 4, vertical: 7);
  static const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(20, 18, 20, 20);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(_radius);

    // The card surface picks up a whisper of the accent so each content type
    // feels tinted without ever looking coloured.
    final surface = Color.alphaBlend(
      borderColor.withOpacity(isDark ? 0.07 : 0.022),
      theme.cardColor,
    );

    return Semantics(
      button: onTap != null,
      child: Container(
        margin: _cardMargin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            // Wide, accent-tinted ambient glow — this carries the elevation.
            BoxShadow(
              color: borderColor.withOpacity(isDark ? 0.22 : 0.11),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
            // Tight neutral contact shadow keeps the card grounded.
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
              blurRadius: 5,
              spreadRadius: -1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: borderColor.withOpacity(0.07),
            highlightColor: borderColor.withOpacity(0.04),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                // Hairline border instead of the old heavy 1.6px stroke.
                border: Border.all(
                  color: borderColor.withOpacity(isDark ? 0.30 : 0.15),
                  width: 1,
                ),
                // Soft top-down sheen for a lit, glassy surface.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    borderColor.withOpacity(isDark ? 0.07 : 0.035),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAccentBar(),
                  Padding(
                    padding: _contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme, isDark),
                        if (content.hasArabic) ...[
                          const SizedBox(height: 16),
                          _buildArabicBlock(isDark),
                        ],
                        if (content.hasArabic && content.hasPersian) ...[
                          const SizedBox(height: 18),
                          _buildDivider(),
                          const SizedBox(height: 6),
                        ],
                        if (content.hasPersian) ...[
                          const SizedBox(height: 10),
                          _buildPersian(theme),
                        ],
                        if (content.hasSource) ...[
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildSource(theme, isDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Slim accent ribbon along the top edge — identifies the content type.
  Widget _buildAccentBar() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            borderColor.withOpacity(0.85),
            borderColor.withOpacity(0.45),
            borderColor.withOpacity(0.12),
          ],
        ),
      ),
    );
  }

  /// Badge + title + affordance chevron.
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: borderColor.withOpacity(isDark ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withOpacity(0.18)),
          ),
          child: Icon(icon, color: borderColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            content.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: borderColor,
              letterSpacing: 0.1,
              height: 1.25,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor.withOpacity(isDark ? 0.18 : 0.08),
            ),
            child: Icon(Icons.arrow_forward_ios, size: 11, color: borderColor),
          ),
        ],
      ],
    );
  }

  /// Arabic body sits in its own tinted, softly bordered well so the sacred
  /// text reads as the visual anchor of the card.
  Widget _buildArabicBlock(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_innerRadius),
        border: Border.all(color: borderColor.withOpacity(isDark ? 0.22 : 0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor.withOpacity(isDark ? 0.14 : 0.075),
            borderColor.withOpacity(isDark ? 0.06 : 0.025),
          ],
        ),
      ),
      child: ArabicText(
        content.arabic,
        fontWeight: FontWeight.w600,
        maxLines: maxArabicLines,
      ),
    );
  }

  /// Feathered hairline that fades at both ends — softer than a full Divider.
  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            borderColor.withOpacity(0.0),
            borderColor.withOpacity(0.35),
            borderColor.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  /// Persian translation: generous line height for comfortable RTL reading.
  Widget _buildPersian(ThemeData theme) {
    return Text(
      content.persian,
      textAlign: TextAlign.center,
      maxLines: maxPersianLines,
      overflow: maxPersianLines == null ? null : TextOverflow.ellipsis,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.9,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface.withOpacity(0.86),
      ),
    );
  }

  /// Attribution rendered as a quiet pill so it never competes with the body.
  Widget _buildSource(ThemeData theme, bool isDark) {
    final tertiary = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tertiary.withOpacity(isDark ? 0.16 : 0.075),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: tertiary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 13, color: tertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              content.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}