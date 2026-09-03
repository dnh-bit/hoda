import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import 'motion.dart';

/// Shortcut tile used on the home dashboard: tinted icon badge, title,
/// subtitle and an optional item count.
class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  /// How many items the destination holds; rendered as a small pill.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: palette.card(accentColor: color, radius: HodaRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              bottom: -26,
              end: -16,
              child: Icon(
                icon,
                size: 84,
                color: color.withOpacity(palette.isDark ? 0.07 : 0.06),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: palette.tintGradient(color),
                        borderRadius: HodaRadius.all(HodaRadius.xs),
                        border: Border.all(color: color.withOpacity(0.28)),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const Spacer(),
                    if (count != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: palette.pill(color, opacity: 0.14),
                        child: Text(
                          FaNum.number(count!),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: color),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: color.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
