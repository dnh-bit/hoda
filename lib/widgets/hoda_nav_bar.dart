import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/hoda_theme.dart';

/// One destination of [HodaNavBar].
@immutable
class HodaNavItem {
  const HodaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Accent used when the item is selected — the same hue the destination uses
  /// for its content, so the nav bar teaches the colour language too.
  final Color color;
}

/// A floating pill navigation bar.
///
/// Replaces the stock [BottomNavigationBar]: rounded, detached from the screen
/// edge, with an animated tinted capsule behind the selected destination. Fully
/// RTL-safe because every item is a plain [Expanded] in a [Row] — no absolute
/// offsets to mirror.
class HodaNavBar extends StatelessWidget {
  const HodaNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<HodaNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: palette.isDark
                ? palette.surfaceHigh.withOpacity(0.96)
                : palette.surfaceHigh,
            borderRadius: HodaRadius.all(22),
            border: Border.all(color: palette.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow,
                blurRadius: 26,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () {
                        if (i != currentIndex) HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HodaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color color = selected ? item.color : palette.faint;

    return InkWell(
      onTap: onTap,
      borderRadius: HodaRadius.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: HodaMotion.medium,
            curve: HodaMotion.enter,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 14 : 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              gradient: selected ? palette.tintGradient(item.color) : null,
              borderRadius: HodaRadius.all(HodaRadius.pill),
              border: Border.all(
                color: selected ? item.color.withOpacity(0.32) : Colors.transparent,
              ),
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: selected ? 21 : 20,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: HodaMotion.medium,
            style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontSize: selected ? 10.5 : 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
