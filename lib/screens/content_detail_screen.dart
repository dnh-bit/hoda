import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../widgets/arabic_text.dart';

/// Full-text view for a single piece of content (nothing is truncated here).
class ContentDetailScreen extends StatelessWidget {
  final DailyContent content;

  const ContentDetailScreen({super.key, required this.content});

  String get _plainText => [
        if (content.hasArabic) content.arabic,
        if (content.hasPersian) content.persian,
        if (content.hasSource) content.source,
      ].join('\n\n');

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _plainText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('متن کپی شد 🌿')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'کپی متن',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (content.hasArabic)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HodaColors.gold.withOpacity(0.55)),
              ),
              child: ArabicText(
                content.arabic,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 2.05,
              ),
            ),
          if (content.hasArabic && content.hasPersian)
            const SizedBox(height: 20),
          if (content.hasPersian)
            Text(
              content.persian,
              textAlign: TextAlign.justify,
              style: theme.textTheme.bodyLarge,
            ),
          if (content.hasNote) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HodaColors.turquoise.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.note,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          if (content.hasSource) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.label_outline,
                    size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    content.source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
