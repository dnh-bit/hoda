import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'content_detail_screen.dart';

/// Modern scrollable list view for scriptures & wisdoms with search bar,
/// family filters, and count badges.
class ContentListView extends StatefulWidget {
  final List<DailyContent> items;
  final String heading;
  final String emptyText;
  final IconData icon;

  /// Returns the topic family of [item], or null when not applicable.
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
  String? _selectedFamily;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _families {
    if (widget.familiesOf == null) return const <String>[];
    final seen = <String>{};
    for (final item in widget.items) {
      final f = widget.familiesOf!(item);
      if (f != null && f.isNotEmpty) seen.add(f);
    }
    return seen.toList(growable: false);
  }

  List<DailyContent> _getFilteredItems() {
    final fam = widget.familiesOf;
    return widget.items.where((item) {
      final matchesFamily = fam == null || _selectedFamily == null || fam(item) == _selectedFamily;
      if (!matchesFamily) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(q) ||
          item.persian.toLowerCase().contains(q) ||
          (item.hasArabic && item.arabic.toLowerCase().contains(q)) ||
          (item.hasSource && item.source.toLowerCase().contains(q));
    }).toList(growable: false);
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
    final isDark = theme.brightness == Brightness.dark;
    final families = _families;
    final filtered = _getFilteredItems();

    return Column(
      children: [
        // 1. Top Bar Header & Search Box
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            color: isDark ? HodaColors.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Title & Counter Row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: HodaColors.forestGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 18, color: HodaColors.forestGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.heading,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? HodaColors.darkSurfaceCard
                          : HodaColors.turquoiseSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: HodaColors.turquoise.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '${FaNum.number(filtered.length)} مورد',
                      style: TextStyle(
                        fontFamily: HodaTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? HodaColors.turquoiseLight : HodaColors.turquoise,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search TextField
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? HodaColors.darkSurfaceCard : HodaColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontFamily: HodaTheme.fontFamily, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'جستجو در متن یا عنوان...',
                    hintStyle: TextStyle(
                      fontFamily: HodaTheme.fontFamily,
                      fontSize: 12.5,
                      color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Family Filter Bar if available
              if (families.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: families.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final isSelected = index == 0
                          ? _selectedFamily == null
                          : _selectedFamily == families[index - 1];
                      final label = index == 0 ? 'همه موضوعات' : families[index - 1];

                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (_) => setState(() =>
                            _selectedFamily = index == 0 ? null : families[index - 1]),
                        label: Text(
                          label,
                          style: TextStyle(
                            fontFamily: HodaTheme.fontFamily,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? HodaColors.darkBg : Colors.white)
                                : (isDark ? HodaColors.cream : HodaColors.inkGreen),
                          ),
                        ),
                        selectedColor: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
                        backgroundColor: isDark ? HodaColors.darkSurfaceCard : HodaColors.cream,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? HodaColors.darkBorder : HodaColors.borderSubtle),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Filtered Content List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'موردی مطابق با جستجوی شما یافت نشد',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ContentCard(
                      content: item,
                      borderColor: index.isEven ? HodaColors.turquoise : HodaColors.gold,
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
                ),
        ),
      ],
    );
  }
}
