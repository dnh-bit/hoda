import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/content_card.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/quick_tile.dart';
import '../widgets/section_header.dart';
import 'content_detail_screen.dart';

/// Home dashboard: greeting header, today's content and quick shortcuts.
class HomeTab extends StatelessWidget {
  final HodaContent content;
  final int salawatToday;
  final VoidCallback onOpenVerses;
  final VoidCallback onOpenHadiths;
  final VoidCallback onOpenMartyrs;
  final VoidCallback onOpenNahj;
  final VoidCallback onOpenSalawat;
  final Future<void> Function() onRefresh;

  const HomeTab({
    super.key,
    required this.content,
    required this.salawatToday,
    required this.onOpenVerses,
    required this.onOpenHadiths,
    required this.onOpenMartyrs,
    required this.onOpenNahj,
    required this.onOpenSalawat,
    required this.onRefresh,
  });

  static const DailyContent _placeholder = DailyContent(
    title: 'محتوای امروز',
    persian: 'امروز محتوایی موجود نیست.',
  );

  void _openDetail(BuildContext context, DailyContent item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContentDetailScreen(content: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = content.dailyVerse ?? _placeholder;
    final hadith = content.dailyHadith ?? _placeholder;
    final martyr = content.dailyMartyr ?? _placeholder;
    final zekr = content.dailyZekr;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: HodaColors.turquoise,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 22),
          SectionHeader(
            icon: Icons.wb_sunny_outlined,
            title: 'محتوای امروز',
            action: Text(
              FaNum.weekDay(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ContentCard(
            content: verse,
            borderColor: HodaColors.gold,
            icon: Icons.menu_book,
            maxPersianLines: 6,
            onTap: () => _openDetail(context, verse),
          ),
          const SizedBox(height: 12),
          ContentCard(
            content: hadith,
            borderColor: HodaColors.turquoise,
            icon: Icons.format_quote,
            maxPersianLines: 6,
            onTap: () => _openDetail(context, hadith),
          ),
          if (zekr != null) ...[
            const SizedBox(height: 12),
            ContentCard(
              content: zekr,
              borderColor: HodaColors.turquoiseLight,
              icon: Icons.auto_awesome,
              maxPersianLines: 4,
              onTap: () => _openDetail(context, zekr),
            ),
          ],
          const SizedBox(height: 12),
          ContentCard(
            content: martyr,
            borderColor: HodaColors.gold,
            icon: Icons.volunteer_activism,
            maxPersianLines: 6,
            onTap: () => _openDetail(context, martyr),
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            icon: Icons.auto_awesome_outlined,
            title: 'کاوش سریع',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              QuickTile(
                icon: Icons.menu_book,
                title: 'آیات',
                subtitle: 'آیات نورانی قرآن',
                color: HodaColors.gold,
                onTap: onOpenVerses,
              ),
              QuickTile(
                icon: Icons.format_quote,
                title: 'احادیث',
                subtitle: 'سخنان اهل بیت (ع)',
                color: HodaColors.turquoise,
                onTap: onOpenHadiths,
              ),
              QuickTile(
                icon: Icons.volunteer_activism,
                title: 'وصایا',
                subtitle: 'پیام شهدا',
                color: HodaColors.gold,
                onTap: onOpenMartyrs,
              ),
              QuickTile(
                icon: Icons.auto_stories,
                title: 'حکمت',
                subtitle: 'نهج‌البلاغه',
                color: HodaColors.turquoise,
                onTap: onOpenNahj,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSalawatCard(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HodaColors.forestGreen, HodaColors.turquoise],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HodaColors.turquoise.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const HodaLogo(size: 92),
          const SizedBox(height: 14),
          Text(
            'به هُدا خوش آمدید',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'همراه معنوی روزانه شما',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'ذکر روز و هدایت معنوی',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalawatCard(ThemeData theme) {
    return InkWell(
      onTap: onOpenSalawat,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HodaColors.gold, width: 1.4),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: HodaColors.gold, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ذکر صلوات شمار',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'صلوات امروز شما',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              FaNum.number(salawatToday),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: HodaColors.turquoise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
