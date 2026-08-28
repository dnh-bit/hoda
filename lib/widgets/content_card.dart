import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import 'arabic_text.dart';

/// Standard card used for every piece of content (verse, hadith, martyr will,
/// Nahj wisdom). Arabic and Persian bodies are styled separately.
class ContentCard extends StatelessWidget {
  final DailyContent content;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  /// When set, the Persian body is clipped to this many lines (list previews).
  final int? maxPersianLines;

  /// When set, the Arabic body is clipped to this many lines (list previews).
  final int? maxArabicLines;

  const ContentCard({
    super.key,
    required this.content,
    required this.borderColor,
    required this.icon,
    this.onTap,
    this.maxPersianLines,
    this.maxArabicLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.6),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: borderColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 14, color: borderColor),
                ],
              ),
              if (content.hasArabic) ...[
                const SizedBox(height: 14),
                ArabicText(
                  content.arabic,
                  fontWeight: FontWeight.w600,
                  maxLines: maxArabicLines,
                ),
              ],
              if (content.hasArabic && content.hasPersian) ...[
                const SizedBox(height: 12),
                Divider(color: borderColor.withOpacity(0.4)),
                const SizedBox(height: 4),
              ],
              if (content.hasPersian) ...[
                const SizedBox(height: 8),
                Text(
                  content.persian,
                  textAlign: TextAlign.center,
                  maxLines: maxPersianLines,
                  overflow:
                      maxPersianLines == null ? null : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              if (content.hasSource) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content.source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
