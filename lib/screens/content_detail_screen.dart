import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../widgets/arabic_text.dart';

/// Full-text view for a single piece of content (nothing is truncated here).
class ContentDetailScreen extends StatefulWidget {
  final DailyContent content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  /// Whether the «مفهوم (تفسیر)» panel is expanded. Only meaningful when the
  /// content actually carries one ([DailyContent.hasTafsir]).
  bool _tafsirOpen = false;

  String get _plainText => [
        if (widget.content.hasArabic) widget.content.arabic,
        if (widget.content.hasPersian) widget.content.persian,
        if (widget.content.hasSource) widget.content.source,
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
    final content = widget.content;
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
          // «مفهوم (تفسیر)» — a collapsible panel behind its own button so the
          // card stays focused on the wisdom itself until the reader asks for
          // the explanation.
          if (content.hasTafsir) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => setState(() => _tafsirOpen = !_tafsirOpen),
              icon: Icon(
                _tafsirOpen
                    ? Icons.expand_less_outlined
                    : Icons.lightbulb_outline,
                size: 20,
              ),
              label: Text(_tafsirOpen ? 'بستن مفهوم' : 'مفهوم و تفسیر'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.tertiary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _tafsirOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HodaColors.gold.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HodaColors.gold.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          'مفهوم',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.tafsir!,
                      textAlign: TextAlign.justify,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (content.family != null && content.family!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HodaColors.turquoise.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sell_outlined,
                        size: 14, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Text(
                      content.family!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
