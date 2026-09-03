import 'package:flutter/material.dart';
import '../theme/hoda_theme.dart';

/// Modern section header with an icon badge and optional trailing action.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? (isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? HodaColors.cream : HodaColors.inkGreen,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}
