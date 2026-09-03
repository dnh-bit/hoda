import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/favorites_store.dart';
import '../services/reader_settings.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/content_actions.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/motion.dart';

/// Full-text reading view for a single item — nothing is truncated here.
///
/// Reading is the whole point of the app, so this screen is built around it: a
/// collapsing gradient header, the scripture in a framed panel, the translation
/// in a comfortable measure, the «مفهوم» panel behind a toggle, and a persistent
/// text-size control (remembered forever via [ReaderSettings]).
class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({super.key, required this.content});

  final DailyContent content;

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  /// Whether the «مفهوم (تفسیر)» panel is expanded. Only meaningful when the
  /// content actually carries one ([DailyContent.hasTafsir]).
  bool _tafsirOpen = false;

  @override
  void initState() {
    super.initState();
    ReaderSettings.ensureLoaded();
  }

  void _openReaderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReaderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DailyContent content = widget.content;
    final ContentStyle cs = ContentStyle.forContent(content);
    final Color color = cs.colorOf(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Scaffold(
      body: HodaBackground(
        child: ValueListenableBuilder<double>(
          valueListenable: ReaderSettings.scale,
          builder: (BuildContext context, double scale, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: ReaderSettings.justify,
              builder: (BuildContext context, bool justify, __) {
                return CustomScrollView(
                  slivers: <Widget>[
                    _DetailAppBar(
                      content: content,
                      style: cs,
                      color: color,
                      onReader: _openReaderSheet,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(<Widget>[
                          if (content.hasArabic)
                            Reveal(
                              child: _ScripturePanel(
                                text: content.arabic,
                                color: color,
                                scale: scale,
                              ),
                            ),
                          if (content.hasPersian) ...<Widget>[
                            SizedBox(height: content.hasArabic ? 16 : 0),
                            Reveal(
                              delay: Reveal.stagger(1),
                              child: _TranslationCard(
                                text: content.persian,
                                color: color,
                                scale: scale,
                                justify: justify,
                                label: content.hasArabic ? 'ترجمه' : 'متن',
                              ),
                            ),
                          ],
                          if (content.hasTafsir) ...<Widget>[
                            const SizedBox(height: 14),
                            Reveal(
                              delay: Reveal.stagger(2),
                              child: _TafsirPanel(
                                text: content.tafsir!,
                                open: _tafsirOpen,
                                scale: scale,
                                onToggle: () => setState(
                                  () => _tafsirOpen = !_tafsirOpen,
                                ),
                              ),
                            ),
                          ],
                          if (content.hasNote) ...<Widget>[
                            const SizedBox(height: 14),
                            Reveal(
                              delay: Reveal.stagger(3),
                              child: _NoteCard(text: content.note),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Reveal(
                            delay: Reveal.stagger(4),
                            child: _MetaCard(
                              content: content,
                              style: cs,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Reveal(
                            delay: Reveal.stagger(5),
                            child: _ActionBar(
                              content: content,
                              color: color,
                              onReader: _openReaderSheet,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Center(
                            child: OrnamentDivider(
                              width: 140,
                              color: palette.accent,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Collapsing gradient header carrying the title and the family label.
class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.content,
    required this.style,
    required this.color,
    required this.onReader,
  });

  final DailyContent content;
  final ContentStyle style;
  final Color color;
  final VoidCallback onReader;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    const BorderRadius radius = BorderRadius.only(
      bottomLeft: Radius.circular(26),
      bottomRight: Radius.circular(26),
    );

    return SliverAppBar(
      pinned: true,
      expandedHeight: 152,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: <Widget>[
        IconButton(
          tooltip: 'اندازه متن',
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 42),
          icon: const Icon(Icons.format_size),
          onPressed: onReader,
        ),
        IconButton(
          tooltip: 'کپی متن',
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 42),
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => ContentActions.copy(context, content),
        ),
        ValueListenableBuilder<Set<String>>(
          valueListenable: FavoritesStore.uids,
          builder: (BuildContext context, Set<String> uids, _) {
            final bool saved =
                content.uid != null && uids.contains(content.uid);
            return IconButton(
              tooltip: saved ? 'حذف از نشان‌شده‌ها' : 'نشان‌گذاری',
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(minWidth: 42),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
              onPressed: () => ContentActions.toggleFavorite(context, content),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: palette.heroGradient,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: PatternLayer(
                      color: Colors.white.withOpacity(0.06),
                      tile: 60,
                    ),
                  ),
                  PositionedDirectional(
                    top: -28,
                    end: -18,
                    child: Icon(
                      style.icon,
                      size: 130,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 18,
              end: 18,
              bottom: 14,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  style.plural,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: HodaColors.goldGlow.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Arabic scripture, framed like a manuscript panel.
class _ScripturePanel extends StatelessWidget {
  const _ScripturePanel({
    required this.text,
    required this.color,
    required this.scale,
  });

  final String text;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: palette.card(accentColor: color, radius: HodaRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: color.withOpacity(palette.isDark ? 0.055 : 0.05),
              tile: 58,
            ),
          ),
          Column(
            children: <Widget>[
              _CornerRow(color: color),
              const SizedBox(height: 14),
              ArabicText(
                text,
                fontSize: 23 * scale,
                fontWeight: FontWeight.w600,
                height: 2.1,
              ),
              const SizedBox(height: 14),
              _CornerRow(color: color, flip: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tiny ornament row that closes the scripture panel top and bottom.
class _CornerRow extends StatelessWidget {
  const _CornerRow({required this.color, this.flip = false});

  final Color color;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Container(
            height: 1,
            color: color.withOpacity(0.22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            flip ? Icons.star_border : Icons.star,
            size: 13,
            color: color.withOpacity(0.55),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: color.withOpacity(0.22),
          ),
        ),
      ],
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.text,
    required this.color,
    required this.scale,
    required this.justify,
    required this.label,
  });

  final String text;
  final Color color;
  final double scale;
  final bool justify;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: palette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.translate, size: 15, color: palette.accent),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: palette.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text.trim(),
            textAlign: justify ? TextAlign.justify : TextAlign.start,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15.5 * scale,
              height: 1.95,
            ),
          ),
        ],
      ),
    );
  }
}

/// «مفهوم (تفسیر)» — collapsible so the page stays focused on the wisdom itself
/// until the reader asks for the explanation.
class _TafsirPanel extends StatelessWidget {
  const _TafsirPanel({
    required this.text,
    required this.open,
    required this.scale,
    required this.onToggle,
  });

  final String text;
  final bool open;
  final double scale;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      decoration: palette.card(accentColor: palette.accent),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PressableScale(
            onTap: onToggle,
            scale: 0.99,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: palette.tintGradient(palette.accent),
                      borderRadius: HodaRadius.all(HodaRadius.xs),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 17,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'مفهوم و تفسیر',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  AnimatedRotation(
                    duration: HodaMotion.medium,
                    turns: open ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: HodaMotion.medium,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: palette.inset(accentColor: palette.accent),
                child: Text(
                  text.trim(),
                  textAlign: TextAlign.justify,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14 * scale,
                    height: 1.9,
                  ),
                ),
              ),
            ),
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.card(accentColor: HodaColors.turquoise),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.notes,
            size: 17,
            color: HodaColors.turquoise,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.trim(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Source + family metadata, rendered as pills.
class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.content,
    required this.style,
    required this.color,
  });

  final DailyContent content;
  final ContentStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    final List<Widget> pills = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: palette.pill(color, opacity: 0.13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(style.icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              style.plural,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
      if (content.family != null && content.family!.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: palette.pill(HodaColors.turquoise, opacity: 0.13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.sell_outlined,
                size: 14,
                color: HodaColors.turquoise,
              ),
              const SizedBox(width: 6),
              Text(
                content.family!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: HodaColors.turquoise),
              ),
            ],
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.card(elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (content.hasSource) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: palette.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    content.source.trim(),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: palette.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(spacing: 8, runSpacing: 8, children: pills),
        ],
      ),
    );
  }
}

/// Three large, obvious actions at the end of the page.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.content,
    required this.color,
    required this.onReader,
  });

  final DailyContent content;
  final Color color;
  final VoidCallback onReader;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesStore.uids,
      builder: (BuildContext context, Set<String> uids, _) {
        final bool saved = content.uid != null && uids.contains(content.uid);
        return Row(
          children: <Widget>[
            Expanded(
              child: _ActionButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_outline,
                label: saved ? 'نشان‌شده' : 'نشان‌گذاری',
                active: saved,
                onTap: () => ContentActions.toggleFavorite(context, content),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.copy_outlined,
                label: 'کپی متن',
                onTap: () => ContentActions.copy(context, content),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.format_size,
                label: 'اندازه متن',
                onTap: onReader,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color c = active ? palette.accent : palette.muted;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: palette.card(
          accentColor: active ? palette.accent : null,
          radius: HodaRadius.md,
          elevated: false,
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reading preferences sheet: text size and justification, applied live.
class _ReaderSheet extends StatelessWidget {
  const _ReaderSheet();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: ValueListenableBuilder<double>(
          valueListenable: ReaderSettings.scale,
          builder: (BuildContext context, double scale, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.format_size,
                      size: 18,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('اندازه متن',
                          style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      '${FaNum.number((scale * 100).round())}٪',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: palette.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: 'کوچک‌تر',
                      onPressed:
                          ReaderSettings.canShrink ? ReaderSettings.shrink : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Slider(
                        min: ReaderSettings.minScale,
                        max: ReaderSettings.maxScale,
                        divisions: 7,
                        value: scale.clamp(
                          ReaderSettings.minScale,
                          ReaderSettings.maxScale,
                        ),
                        onChanged: ReaderSettings.setScale,
                      ),
                    ),
                    IconButton(
                      tooltip: 'بزرگ‌تر',
                      onPressed:
                          ReaderSettings.canGrow ? ReaderSettings.grow : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: palette.inset(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ArabicText(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        fontSize: 21 * scale,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'به نام خداوند بخشنده مهربان',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 14 * scale),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: ReaderSettings.justify,
                  builder: (BuildContext context, bool justify, __) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('چینش هم‌تراز پاراگراف'),
                      subtitle: Text(
                        justify ? 'مثل صفحه کتاب' : 'چینش از راست',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: justify,
                      onChanged: ReaderSettings.setJustify,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
