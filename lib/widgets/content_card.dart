import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../services/favorites_store.dart';
import '../utils/content_actions.dart';
import 'arabic_text.dart';
import 'hoda_pattern.dart';
import 'motion.dart';

/// The card every piece of content is shown in — verse, hadith, martyr will,
/// Nahj wisdom or the dhikr of the day.
///
/// Anatomy:
/// * a coloured accent strip and a watermark icon that identify the family at a
///   glance (colours come from [ContentStyle], never hard-coded by callers),
/// * a header with a tinted icon badge, the title and an optional badge label
///   («آیه روز»),
/// * the Arabic scripture in a sunken, framed panel (Naskh face, RTL, generous
///   leading),
/// * the Persian body, clipped to [maxPersianLines] in previews,
/// * a footer with the source and the copy / bookmark actions.
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.content,
    this.style,
    this.onTap,
    this.maxPersianLines,
    this.maxArabicLines,
    this.badgeLabel,
    this.showActions = true,
    this.compact = false,
  });

  final DailyContent content;

  /// Overrides the family resolved from the content uid (placeholders, daily
  /// cards built by hand).
  final ContentStyle? style;

  final VoidCallback? onTap;
  final int? maxPersianLines;
  final int? maxArabicLines;

  /// Small pill in the header, e.g. «آیه روز».
  final String? badgeLabel;

  final bool showActions;

  /// Tighter paddings and type, for carousels and dense lists.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final ContentStyle cs = style ?? ContentStyle.forContent(content);
    final Color color = cs.colorOf(context);
    final double pad = compact ? 16 : 18;

    return PressableScale(
      onTap: onTap,
      onLongPress: () => ContentActions.copy(context, content),
      child: Container(
        decoration: palette.card(accentColor: color),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            // Family watermark — pure texture, sits under everything.
            PositionedDirectional(
              top: -22,
              end: -18,
              child: Icon(
                cs.icon,
                size: 116,
                color: color.withOpacity(palette.isDark ? 0.06 : 0.05),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Accent strip.
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        color.withOpacity(0.85),
                        color.withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad - 2, pad, pad - 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _header(theme, palette, cs, color),
                      if (content.hasArabic) ...<Widget>[
                        SizedBox(height: compact ? 12 : 14),
                        _arabicPanel(palette, color),
                      ],
                      if (content.hasPersian) ...<Widget>[
                        SizedBox(height: content.hasArabic ? 14 : 12),
                        Text(
                          content.persian.trim(),
                          textAlign: TextAlign.justify,
                          maxLines: maxPersianLines,
                          overflow: maxPersianLines == null
                              ? null
                              : TextOverflow.ellipsis,
                          style: compact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge,
                        ),
                      ],
                      SizedBox(height: compact ? 8 : 12),
                      _footer(context, theme, palette, color),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    ThemeData theme,
    HodaPalette palette,
    ContentStyle cs,
    Color color,
  ) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: palette.tintGradient(color),
            borderRadius: HodaRadius.all(HodaRadius.xs),
            border: Border.all(color: color.withOpacity(0.30)),
          ),
          child: Icon(cs.icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                content.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
              if (badgeLabel == null && content.hasNote)
                Text(
                  content.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (badgeLabel != null) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: palette.pill(color, opacity: 0.14),
            child: Text(
              badgeLabel!,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
        if (onTap != null) ...<Widget>[
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_left,
            size: 22,
            color: color.withOpacity(0.75),
          ),
        ],
      ],
    );
  }

  Widget _arabicPanel(HodaPalette palette, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 12 : 16,
      ),
      decoration: palette.inset(accentColor: color),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: color.withOpacity(palette.isDark ? 0.05 : 0.045),
              tile: 54,
              drawGrid: false,
            ),
          ),
          ArabicText(
            content.arabic,
            fontSize: compact ? 19 : 21,
            fontWeight: FontWeight.w600,
            maxLines: maxArabicLines,
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    ThemeData theme,
    HodaPalette palette,
    Color color,
  ) {
    return Row(
      children: <Widget>[
        if (content.hasSource)
          Expanded(
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.local_offer_outlined,
                  size: 13,
                  color: palette.accent.withOpacity(0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    content.source.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        if (showActions) ...<Widget>[
          _CardAction(
            icon: Icons.copy_outlined,
            tooltip: 'کپی متن',
            color: palette.muted,
            onTap: () => ContentActions.copy(context, content),
          ),
          _BookmarkAction(content: content),
        ],
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        scale: 0.88,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// Bookmark toggle that keeps itself in sync with [FavoritesStore].
class _BookmarkAction extends StatelessWidget {
  const _BookmarkAction({required this.content});

  final DailyContent content;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesStore.uids,
      builder: (BuildContext context, Set<String> uids, _) {
        final bool saved = content.uid != null && uids.contains(content.uid);
        return _CardAction(
          icon: saved ? Icons.bookmark : Icons.bookmark_outline,
          tooltip: saved ? 'حذف از نشان‌شده‌ها' : 'نشان‌گذاری',
          color: saved ? palette.accent : palette.muted,
          onTap: () => ContentActions.toggleFavorite(context, content),
        );
      },
    );
  }
}
