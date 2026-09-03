import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Section title with a gradient icon badge, optional subtitle and a trailing
/// action. Used to structure every long page in the app.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color c = color ?? palette.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: palette.tintGradient(c),
            borderRadius: HodaRadius.all(HodaRadius.xs),
            border: Border.all(color: c.withOpacity(0.28)),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (action != null) ...<Widget>[
          const SizedBox(width: 8),
          action!,
        ],
      ],
    );
  }
}
