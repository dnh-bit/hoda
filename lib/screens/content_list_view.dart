import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../utils/fa_search.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/motion.dart';
import '../widgets/search_field.dart';
import 'content_detail_screen.dart';

/// A browsing destination: instant search, topic filter chips, a live result
/// count and the card list itself.
///
/// The hadiths tab passes [familiesOf] so the list can offer chip filtering by
/// theme family (اخلاق، خانواده، آرامش و …); «همه» clears the filter. Other tabs
/// simply omit it and render without the bar.
class ContentListView extends StatefulWidget {
  const ContentListView({
    super.key,
    required this.items,
    required this.heading,
    required this.emptyText,
    required this.style,
    this.familiesOf,
  });

  final List<DailyContent> items;
  final String heading;
  final String emptyText;

  /// Visual family of this list (colour + icon + labels).
  final ContentStyle style;

  /// Returns the topic family of an item, or null when the list has no topic
  /// dimension (verses, martyrs, …). When provided, the filter bar shows.
  final String? Function(DailyContent item)? familiesOf;

  @override
  State<ContentListView> createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _debounce;
  String _query = '';

  /// Currently selected family; null = «همه».
  String? _selectedFamily;

  bool _showJumpTop = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool show = _scroll.hasClients && _scroll.offset > 700;
    if (show != _showJumpTop) setState(() => _showJumpTop = show);
  }

  /// Typing is debounced so a long list is filtered once per pause, not once
  /// per keystroke.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _query = value);
    });
  }

  /// Distinct families in the current items, in first-appearance order.
  List<String> get _families {
    if (widget.familiesOf == null) return const <String>[];
    final Set<String> seen = <String>{};
    for (final DailyContent item in widget.items) {
      final String? f = widget.familiesOf!(item);
      if (f != null && f.isNotEmpty) seen.add(f);
    }
    return seen.toList(growable: false);
  }

  List<DailyContent> _filtered() {
    final String? Function(DailyContent)? fam = widget.familiesOf;
    Iterable<DailyContent> out = widget.items;
    if (fam != null && _selectedFamily != null) {
      out = out.where((DailyContent item) => fam!(item) == _selectedFamily);
    }
    final List<DailyContent> list = out.toList(growable: false);
    if (_query.trim().isEmpty) return list;
    return FaSearch.filter(list, _query);
  }

  void _jumpTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.style.colorOf(context);

    if (widget.items.isEmpty) {
      return EmptyState(
        icon: widget.style.icon,
        title: widget.emptyText,
        message: 'محتوا با به‌روزرسانی برنامه اضافه می‌شود.',
        color: color,
      );
    }

    final List<String> families = _families;
    final List<DailyContent> shown = _filtered();
    final bool filtered =
        _selectedFamily != null || _query.trim().isNotEmpty;

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            _Header(
              heading: widget.heading,
              style: widget.style,
              color: color,
              total: widget.items.length,
              shown: shown.length,
              filtered: filtered,
              search: _search,
              onQueryChanged: _onQueryChanged,
              families: families,
              selectedFamily: _selectedFamily,
              onFamily: (String? value) =>
                  setState(() => _selectedFamily = value),
            ),
            Expanded(
              child: shown.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'نتیجه‌ای پیدا نشد',
                      message: 'عبارت دیگری را امتحان کنید یا فیلتر را بردارید.',
                      color: color,
                      action: OutlinedButton.icon(
                        onPressed: () {
                          _search.clear();
                          setState(() {
                            _query = '';
                            _selectedFamily = null;
                          });
                        },
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('پاک کردن فیلترها'),
                      ),
                    )
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (BuildContext context, int index) {
                        final DailyContent item = shown[index];
                        final Widget card = ContentCard(
                          content: item,
                          style: widget.style,
                          maxPersianLines: 4,
                          maxArabicLines: 3,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ContentDetailScreen(content: item),
                            ),
                          ),
                        );
                        // Only the first screenful animates in; recycled rows
                        // deeper down should appear instantly.
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
        PositionedDirectional(
          end: 16,
          bottom: 96,
          child: AnimatedSlide(
            duration: HodaMotion.medium,
            curve: HodaMotion.enter,
            offset: _showJumpTop ? Offset.zero : const Offset(0, 1.4),
            child: AnimatedOpacity(
              duration: HodaMotion.medium,
              opacity: _showJumpTop ? 1 : 0,
              child: FloatingActionButton.small(
                heroTag: 'jump_${widget.heading}',
                tooltip: 'برگشت به بالا',
                onPressed: _showJumpTop ? _jumpTop : null,
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.heading,
    required this.style,
    required this.color,
    required this.total,
    required this.shown,
    required this.filtered,
    required this.search,
    required this.onQueryChanged,
    required this.families,
    required this.selectedFamily,
    required this.onFamily,
  });

  final String heading;
  final ContentStyle style;
  final Color color;
  final int total;
  final int shown;
  final bool filtered;
  final TextEditingController search;
  final ValueChanged<String> onQueryChanged;
  final List<String> families;
  final String? selectedFamily;
  final ValueChanged<String?> onFamily;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: palette.tintGradient(color),
                  borderRadius: HodaRadius.all(HodaRadius.xs),
                  border: Border.all(color: color.withOpacity(0.30)),
                ),
                child: Icon(style.icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: palette.pill(color, opacity: 0.13),
                child: Text(
                  filtered
                      ? '${FaNum.number(shown)} از ${FaNum.number(total)}'
                      : '${FaNum.number(total)} مورد',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HodaSearchField(
            controller: search,
            onChanged: onQueryChanged,
            hint: 'جست‌وجو در ${style.plural}…',
          ),
          if (families.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            FilterChipsBar(
              color: color,
              labels: <String>['همه', ...families],
              selectedIndex: selectedFamily == null
                  ? 0
                  : families.indexOf(selectedFamily!) + 1,
              onSelected: (int index) =>
                  onFamily(index == 0 ? null : families[index - 1]),
            ),
          ],
        ],
      ),
    );
  }
}
