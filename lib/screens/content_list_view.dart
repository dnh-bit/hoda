import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'content_detail_screen.dart';

/// Scrollable list of content cards used by the verses / hadiths / martyrs /
/// Nahj tabs. Tapping a card opens the full text in [ContentDetailScreen].
class ContentListView extends StatelessWidget {
  final List<DailyContent> items;
  final String heading;
  final String emptyText;
  final IconData icon;

  const ContentListView({
    super.key,
    required this.items,
    required this.heading,
    required this.emptyText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: icon,
        title: emptyText,
        message: 'محتوا با به‌روزرسانی برنامه اضافه می‌شود.',
      );
    }

    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    heading,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HodaColors.turquoise.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${FaNum.number(items.length)} مورد',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: HodaColors.turquoise),
                  ),
                ),
              ],
            ),
          );
        }

        final item = items[index - 1];
        return ContentCard(
          content: item,
          borderColor: index.isEven ? HodaColors.turquoise : HodaColors.gold,
          icon: icon,
          maxPersianLines: 5,
          maxArabicLines: 4,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContentDetailScreen(content: item),
            ),
          ),
        );
      },
    );
  }
}
