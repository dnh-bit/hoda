import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../utils/fa_search.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/hoda_app_bar.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/motion.dart';
import '../widgets/search_field.dart';
import 'content_detail_screen.dart';

/// One search result: the item plus the family it came from.
@immutable
class _Hit {
  const _Hit(this.item, this.style);
  final DailyContent item;
  final ContentStyle style;
}

/// Unified search across the whole library — verses, hadiths, wisdoms and wills
/// at once, entirely offline.
///
/// Matching is diacritic- and orthography-insensitive (see [FaSearch]), so
/// «نماز» finds «نَماز» and «الله» finds «اللّٰه».
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.content});

  final HodaContent content;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const int _maxResults = 80;

  /// Starter taps for an empty search box.
  static const List<String> _suggestions = <String>[
    'نماز',
    'صبر',
    'توکل',
    'شکر',
    'خانواده',
    'شهادت',
    'دعا',
    'اخلاق',
  ];

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';

  /// 0 = همه, otherwise index+1 of [ContentStyle.all].
  int _kindIndex = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _useSuggestion(String value) {
    _controller.text = value;
    _controller.selection =
        TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
  }

  /// The searchable pools, in the order results are listed.
  List<MapEntry<ContentStyle, List<DailyContent>>> get _pools =>
      <MapEntry<ContentStyle, List<DailyContent>>>[
        MapEntry<ContentStyle, List<DailyContent>>(
            ContentStyle.verse, widget.content.verses),
        MapEntry<ContentStyle, List<DailyContent>>(
            ContentStyle.hadith, widget.content.hadiths),
        MapEntry<ContentStyle, List<DailyContent>>(
            ContentStyle.nahj, widget.content.nahj),
        MapEntry<ContentStyle, List<DailyContent>>(
            ContentStyle.martyr, widget.content.martyrs),
      ];

  List<_Hit> _results() {
    if (_query.trim().isEmpty) return const <_Hit>[];
    final List<_Hit> hits = <_Hit>[];
    for (final MapEntry<ContentStyle, List<DailyContent>> pool in _pools) {
      if (_kindIndex != 0 &&
          ContentStyle.all[_kindIndex - 1].kind != pool.key.kind) {
        continue;
      }
      for (final DailyContent item
          in FaSearch.filter(pool.value, _query, limit: _maxResults)) {
        hits.add(_Hit(item, pool.key));
        if (hits.length >= _maxResults) return hits;
      }
    }
    return hits;
  }

  int get _libraryTotal =>
      widget.content.verses.length +
      widget.content.hadiths.length +
      widget.content.nahj.length +
      widget.content.martyrs.length;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final List<_Hit> hits = _results();
    final bool searching = _query.trim().isNotEmpty;

    // «همه» plus the four browsable families (the dhikr of the day has no list).
    final List<ContentStyle> kinds = ContentStyle.all
        .where((ContentStyle s) => s.kind != ContentKind.zekr)
        .toList(growable: false);

    return Scaffold(
      appBar: const HodaAppBar(titleText: 'جست‌وجو'),
      body: HodaBackground(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  HodaSearchField(
                    controller: _controller,
                    onChanged: _onChanged,
                    autofocus: true,
                    hint: 'در ${FaNum.number(_libraryTotal)} متن بگردید…',
                  ),
                  const SizedBox(height: 10),
                  FilterChipsBar(
                    color: HodaColors.turquoise,
                    selectedIndex: _kindIndex,
                    onSelected: (int index) =>
                        setState(() => _kindIndex = index),
                    labels: <String>[
                      'همه',
                      for (final ContentStyle s in kinds) s.label,
                    ],
                    icons: <IconData>[
                      Icons.apps,
                      for (final ContentStyle s in kinds) s.icon,
                    ],
                  ),
                  if (searching) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.format_list_bulleted,
                          size: 15,
                          color: palette.muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          hits.isEmpty
                              ? 'نتیجه‌ای پیدا نشد'
                              : '${FaNum.number(hits.length)} نتیجه'
                                  '${hits.length >= _maxResults ? ' (اولین‌ها)' : ''}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: palette.muted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: !searching
                  ? _Suggestions(
                      suggestions: _suggestions,
                      onTap: _useSuggestion,
                    )
                  : hits.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'چیزی پیدا نشد',
                          message:
                              'شاید نگارش دیگری از کلمه را امتحان کنید، یا فیلتر نوع محتوا را بردارید.',
                          color: HodaColors.turquoise,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          itemCount: hits.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (BuildContext context, int index) {
                            final _Hit hit = hits[index];
                            final Widget card = ContentCard(
                              content: hit.item,
                              style: hit.style,
                              compact: true,
                              maxPersianLines: 3,
                              maxArabicLines: 2,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ContentDetailScreen(
                                    content: hit.item,
                                  ),
                                ),
                              ),
                            );
                            if (index > 5) return card;
                            return Reveal(
                              delay: Reveal.stagger(index),
                              child: card,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty-state suggestions: eight one-tap starting points.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              border: Border.all(color: palette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: PatternLayer(
                    color: HodaColors.turquoise.withOpacity(0.12),
                    tile: 44,
                    drawGrid: false,
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.explore_outlined,
                    size: 40,
                    color: HodaColors.turquoise,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'در کل گنجینه بگردید',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'اعراب و نگارش مهم نیست؛ «نماز»، «نَماز» و «نماز خواندن» همه نتیجه می‌دهند.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'جست‌وجوهای پیشنهادی',
            style: theme.textTheme.labelMedium?.copyWith(color: palette.accent),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final String s in suggestions)
              PressableScale(
                onTap: () => onTap(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: palette.card(radius: HodaRadius.pill),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.search,
                        size: 13,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(s, style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
