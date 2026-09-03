import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../widgets/arabic_text.dart';

/// Modern immersive reading screen for individual Quran verses, hadiths,
/// Nahj al-Balagha wisdoms, and martyr wills. Includes font-size zoom slider,
/// copy to clipboard, and expandable commentary.
class ContentDetailScreen extends StatefulWidget {
  final DailyContent content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _tafsirOpen = true;
  double _fontSizeDelta = 0.0;

  String get _plainText => [
        if (widget.content.hasArabic) widget.content.arabic,
        if (widget.content.hasPersian) widget.content.persian,
        if (widget.content.hasSource) widget.content.source,
      ].join('\n\n');

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _plainText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('متن کامل در حافظه کپی شد'),
          ],
        ),
        backgroundColor: HodaColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFontSizeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اندازه قلم متن',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('کوچک', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Slider(
                            value: _fontSizeDelta,
                            min: -4.0,
                            max: 8.0,
                            divisions: 6,
                            activeColor: HodaColors.turquoise,
                            onChanged: (val) {
                              setModalState(() => _fontSizeDelta = val);
                              setState(() => _fontSizeDelta = val);
                            },
                          ),
                        ),
                        const Text('بزرگ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            tooltip: 'اندازه متن',
            icon: const Icon(Icons.format_size_rounded),
            onPressed: _showFontSizeDialog,
          ),
          IconButton(
            tooltip: 'کپی متن',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Arabic Scripture Container
          if (content.hasArabic)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? HodaColors.darkBorder
                      : HodaColors.gold.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: HodaColors.gold.withOpacity(isDark ? 0.05 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isDark ? HodaColors.goldLight : HodaColors.gold).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 20,
                        color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ArabicText(
                    content.arabic,
                    fontSize: 24 + _fontSizeDelta,
                    fontWeight: FontWeight.w700,
                    height: 2.15,
                  ),
                ],
              ),
            ),

          if (content.hasArabic && content.hasPersian)
            const SizedBox(height: 20),

          // 2. Persian Translation Card
          if (content.hasPersian)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HodaColors.turquoise.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ترجمه فارسی',
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
                  const SizedBox(height: 12),
                  Text(
                    content.persian,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15 + _fontSizeDelta,
                      height: 1.9,
                      color: isDark ? HodaColors.cream : HodaColors.inkGreen,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Tafsir / Commentary Box
          if (content.hasTafsir) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: (isDark ? HodaColors.goldDark : HodaColors.goldLight).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? HodaColors.goldLight : HodaColors.goldDark).withOpacity(0.3),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _tafsirOpen,
                  onExpansionChanged: (v) => setState(() => _tafsirOpen = v),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: HodaColors.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                    ),
                  ),
                  title: Text(
                    'شرح، مفهوم و تفسیر',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Text(
                        content.tafsir!,
                        textAlign: TextAlign.justify,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5 + _fontSizeDelta * 0.7,
                          height: 1.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 4. Topic Family Badge
          if (content.family != null && content.family!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? HodaColors.darkSurfaceCard : HodaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_rounded,
                          size: 14, color: isDark ? HodaColors.turquoiseLight : HodaColors.turquoise),
                      const SizedBox(width: 8),
                      Text(
                        'موضوع: ${content.family!}',
                        style: TextStyle(
                          fontFamily: HodaTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? HodaColors.cream : HodaColors.inkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // 5. Source Reference Box
          if (content.hasSource) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.source_rounded,
                      size: 16, color: isDark ? HodaColors.goldLight : HodaColors.goldDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'منبع و سند: ${content.source}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
