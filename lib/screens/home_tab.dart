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
///
/// The salawat counter is intentionally *not* here: it lives as a compact badge
/// in the home AppBar (see HomeScreen) so it is reachable from every tab.
class HomeTab extends StatelessWidget {
  final HodaContent content;
  final VoidCallback onOpenVerses;
  final VoidCallback onOpenHadiths;
  final VoidCallback onOpenMartyrs;
  final VoidCallback onOpenNahj;
  final Future<void> Function() onRefresh;

  const HomeTab({
    super.key,
    required this.content,
    required this.onOpenVerses,
    required this.onOpenHadiths,
    required this.onOpenMartyrs,
    required this.onOpenNahj,
    required this.onRefresh,
    required this.onShuffle,
    required this.onOpenSettings,
    this.shuffling = false,
  });

  static const DailyContent _placeholder = DailyContent(
    title: 'محتوای امروز',
    persian: 'امروز محتوایی موجود نیست.',
  );

  /// The «تغییر محتوا» action: swaps every daily card for a fresh random pick
  /// (and re-arms the notifications with the new picks).
  final Future<void> Function() onShuffle;

  /// True while the parent is re-picking content; swaps the reload icon for a
  /// small spinner so the tap is visibly acknowledged.
  final bool shuffling;

  /// Opens the settings screen (notification manager lives there).
  final VoidCallback onOpenSettings;

  Widget? get _shufflingIndicator =>
      shuffling
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null;

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
    final nahj = content.dailyNahj;
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
            action: TextButton.icon(
              onPressed: onShuffle,
              icon: _shufflingIndicator ?? const Icon(
                Icons.refresh,
                size: 20,
              ),
              label: const Text(
                'تغییر محتوای امروز',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.tertiary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (zekr != null) ...[
            ContentCard(
              content: zekr,
              borderColor: HodaColors.turquoiseLight,
              icon: Icons.auto_awesome,
              maxPersianLines: 4,
              onTap: () => _openDetail(context, zekr),
            ),
            const SizedBox(height: 12),
          ],
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
          const SizedBox(height: 12),
          ContentCard(
            content: nahj ?? _placeholder,
            borderColor: HodaColors.gold,
            icon: Icons.auto_stories,
            maxPersianLines: 6,
            onTap: () => _openDetail(context, nahj ?? _placeholder),
          ),
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
                title: 'وصایای شهدا',
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
          // «تنظیم اعلان» — turns the decorative sun-chip into the main entry
          // point to the notification manager, so users can find it without
          // digging through the AppBar menu.
          Material(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onOpenSettings,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'تنظیم اعلان',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
