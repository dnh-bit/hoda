import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// The pill search input used by the search screen and every browsing list.
class HodaSearchField extends StatelessWidget {
  const HodaSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'جست‌وجو…',
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: HodaRadius.all(HodaRadius.pill),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withOpacity(palette.isDark ? 0.4 : 0.5),
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -6,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyMedium,
        cursorColor: HodaColors.turquoise,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: palette.muted,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'پاک کردن',
                icon: Icon(Icons.close, size: 18, color: palette.muted),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Horizontal, single-line chip selector used for topic filters.
class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.color,
    this.icons,
  });

  /// Chip labels, index 0 being the «همه» reset entry.
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color color;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          final IconData? icon =
              icons != null && index < icons!.length ? icons![index] : null;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: HodaMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: selected ? palette.tintGradient(color) : null,
                color: selected ? null : palette.surface,
                borderRadius: HodaRadius.all(HodaRadius.pill),
                border: Border.all(
                  color: selected ? color.withOpacity(0.55) : palette.border,
                ),
              ),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? color : palette.muted,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labels[index],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? color : palette.muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
