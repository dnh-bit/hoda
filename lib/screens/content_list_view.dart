import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'content_detail_screen.dart';

/// Scrollable list of content cards with an optional **topic filter bar**.
///
/// The hadiths tab passes [familiesOf] so the list can offer chip filtering by
/// theme family (اخلاق، خانواده، آرامش و …): rows whose family matches the
/// selected chip stay visible; «همه» clears the filter. Other tabs simply omit
/// [familiesOf] and render without the bar.
class ContentListView extends StatefulWidget {
  final List<DailyContent> items;
  final String heading;
  final String emptyText;
  final IconData icon;

  /// Returns the topic family of [item], or null when the list has no topic
  /// dimension (verses, martyrs, …). When provided, the filter bar shows.
  final String? Function(DailyContent item)? familiesOf;

  const ContentListView({
    super.key,
    required this.items,
    required this.heading,
    required this.emptyText,
    required this.icon,
    this.familiesOf,
  });

  @override
  State<ContentListView> createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  /// Currently selected family; null = «همه».
  String? _selectedFamily;

  late List<DailyContent> _filtered = List.of(widget.items);

  @override
  void didUpdateWidget(covariant ContentListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The items list is rebuilt on tab switches / content refreshes; re-apply
    // the active filter against the new list.
    if (!identical(widget.items, oldWidget.items)) {
      _applyFilter();
    }
  }

  /// Distinct families in the current items, in first-appearance order.
  List<String> get _families {
    if (widget.familiesOf == null) return const <String>[];
    final seen = <String>{};
    for (final item in widget.items) {
      final f = widget.familiesOf!(item);
      if (f != null && f.isNotEmpty) seen.add(f);
    }
    return seen.toList(growable: false);
  }

  void _applyFilter() {
    final fam = widget.familiesOf;
    if (fam == null || _selectedFamily == null) {
      _filtered = List.of(widget.items);
      return;
    }
    _filtered = widget.items
        .where((item) => fam(item) == _selectedFamily)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return EmptyState(
        icon: widget.icon,
        title: widget.emptyText,
        message: 'محتوا با به‌روزرسانی برنامه اضافه می‌شود.',
      );
    }

    final theme = Theme.of(context);
    final families = _families;
    _applyFilter();
    final shown = _filtered;

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(widget.icon, size: 22, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.heading,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HodaColors.turquoise.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              // When filtered, show «x از y» so the filter is visible in numbers.
              _selectedFamily == null
                  ? '${FaNum.number(widget.items.length)} مورد'
                  : '${FaNum.number(shown.length)} از ${FaNum.number(widget.items.length)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: HodaColors.turquoise),
            ),
          ),
        ],
      ),
    );

    final filterBar = families.isEmpty
        ? null
        : SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: families.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == 0
                    ? _selectedFamily == null
                    : _selectedFamily == families[index - 1];
                final label =
                    index == 0 ? 'همه' : families[index - 1];
                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() =>
                      _selectedFamily = index == 0 ? null : families[index - 1]),
                  label: Text(label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                  selectedColor: HodaColors.turquoise.withOpacity(0.18),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? HodaColors.turquoise
                        : HodaColors.gold.withOpacity(0.5),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: shown.length + (filterBar == null ? 1 : 2),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) return header;
        if (filterBar != null && index == 1) return filterBar;
        final itemIndex =
            index - (filterBar == null ? 1 : 2);
        final item = shown[itemIndex];
        return ContentCard(
          content: item,
          borderColor:
              itemIndex.isEven ? HodaColors.turquoise : HodaColors.gold,
          icon: widget.icon,
          maxPersianLines: 5,
          maxArabicLines: 4,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContentDetailScreen(content: item),
            ),
          ),
        );
      },
    );
  }
}
