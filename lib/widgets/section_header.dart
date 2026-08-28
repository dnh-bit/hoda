import 'package:flutter/material.dart';

/// Small titled row used to separate sections on a page.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.tertiary),
        const SizedBox(width: 8),
        Text(
          title,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}
