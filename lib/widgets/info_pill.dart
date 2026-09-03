import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';
import 'motion.dart';

/// Small rounded label: icon + text, tinted with an accent colour.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.dense = false,
    this.onHero = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool dense;

  /// Set when the pill sits on top of the brand gradient (white treatment).
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color c = onHero ? Colors.white : (color ?? palette.accent);

    final Widget body = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: onHero
            ? Colors.white.withOpacity(0.16)
            : c.withOpacity(palette.isDark ? 0.16 : 0.11),
        borderRadius: HodaRadius.all(HodaRadius.pill),
        border: Border.all(
          color: onHero
              ? Colors.white.withOpacity(0.28)
              : c.withOpacity(palette.isDark ? 0.34 : 0.26),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: dense ? 13 : 15,
              color: onHero ? HodaColors.goldGlow : c,
            ),
            SizedBox(width: dense ? 5 : 7),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                  ?.copyWith(color: onHero ? Colors.white : c),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return body;
    return PressableScale(onTap: onTap, child: body);
  }
}

/// A compact stat card: big value, small label, tinted icon badge.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: palette.card(accentColor: color, radius: HodaRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: palette.tintGradient(color),
                borderRadius: HodaRadius.all(HodaRadius.xs),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
