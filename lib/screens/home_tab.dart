import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../utils/jalali_date.dart';
import '../widgets/arabic_text.dart';
import '../widgets/content_card.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/quick_tile.dart';
import '../widgets/section_header.dart';
import 'content_detail_screen.dart';

/// Modern Home dashboard featuring dynamic spiritual hero banner, quick actions,
/// daily zekr highlight card, scripture cards, and streamlined category exploration.
class HomeTab extends StatelessWidget {
  final HodaContent content;
  final VoidCallback onOpenVerses;
  final VoidCallback onOpenHadiths;
  final VoidCallback onOpenMartyrs;
  final VoidCallback onOpenNahj;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onShuffle;
  final bool shuffling;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSalawat;

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
    required this.onOpenSalawat,
    this.shuffling = false,
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
    final isDark = theme.brightness == Brightness.dark;

    final verse = content.dailyVerse ?? _placeholder;
    final hadith = content.dailyHadith ?? _placeholder;
    final martyr = content.dailyMartyr ?? _placeholder;
    final nahj = content.dailyNahj;
    final zekr = content.dailyZekr;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: HodaColors.turquoise,
      backgroundColor: isDark ? HodaColors.darkSurfaceCard : Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // 1. Premium Hero Header Banner
          _buildHeroHeader(context, theme, isDark),
          const SizedBox(height: 18),

          // 2. Daily Dhikr Highlight Card (Featured Banner)
          if (zekr != null) ...[
            _buildDailyZekrBanner(context, theme, zekr, isDark),
            const SizedBox(height: 20),
          ],

          // 3. Quick Explore Grid Section
          SectionHeader(
            icon: Icons.grid_view_rounded,
            title: 'کاوش موضوعی',
            accentColor: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              QuickTile(
                icon: Icons.menu_book_rounded,
                title: 'قرآن کریم',
                subtitle: 'آیات نورانی',
                color: HodaColors.gold,
                onTap: onOpenVerses,
              ),
              QuickTile(
                icon: Icons.format_quote_rounded,
                title: 'احادیث',
                subtitle: 'کلام معصومین (ع)',
                color: HodaColors.turquoise,
                onTap: onOpenHadiths,
              ),
              QuickTile(
                icon: Icons.auto_stories_rounded,
                title: 'نهج‌البلاغه',
                subtitle: 'حکمت‌های علوی',
                color: HodaColors.emerald,
                onTap: onOpenNahj,
              ),
              QuickTile(
                icon: Icons.military_tech_rounded,
                title: 'شهدای والا',
                subtitle: 'وصایا و پیام‌ها',
                color: HodaColors.goldDark,
                onTap: onOpenMartyrs,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 4. Daily Feed Section Header with Refresh Action
          SectionHeader(
            icon: Icons.wb_sunny_rounded,
            title: 'میهمانی نور امروز',
            accentColor: isDark ? HodaColors.goldLight : HodaColors.goldDark,
            action: TextButton.icon(
              onPressed: shuffling ? null : onShuffle,
              icon: shuffling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cached_rounded, size: 18),
              label: const Text(
                'تغییر محتوا',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Daily Verse Card
          ContentCard(
            content: verse,
            borderColor: HodaColors.gold,
            icon: Icons.menu_book_rounded,
            categoryBadge: 'آیه مبارکه امروز',
            maxPersianLines: 5,
            onTap: () => _openDetail(context, verse),
          ),
          const SizedBox(height: 14),

          // Daily Hadith Card
          ContentCard(
            content: hadith,
            borderColor: HodaColors.turquoise,
            icon: Icons.format_quote_rounded,
            categoryBadge: 'حدیث شریف امروز',
            maxPersianLines: 5,
            onTap: () => _openDetail(context, hadith),
          ),
          const SizedBox(height: 14),

          // Daily Nahj Wisdom Card
          if (nahj != null) ...[
            ContentCard(
              content: nahj,
              borderColor: HodaColors.emerald,
              icon: Icons.auto_stories_rounded,
              categoryBadge: 'حکمت علوی امروز',
              maxPersianLines: 5,
              onTap: () => _openDetail(context, nahj),
            ),
            const SizedBox(height: 14),
          ],

          // Daily Martyr Card
          ContentCard(
            content: martyr,
            borderColor: HodaColors.goldDark,
            icon: Icons.military_tech_rounded,
            categoryBadge: 'فراز وصیت شهید',
            maxPersianLines: 5,
            onTap: () => _openDetail(context, martyr),
          ),
        ],
      ),
    );
  }

  /// Modern Hero Banner with subtle Islamic gradient, date chip, and quick actions.
  Widget _buildHeroHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0D382B),
                  const Color(0xFF09251D),
                ]
              : [
                  HodaColors.deepGreen,
                  HodaColors.forestGreen,
                ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : HodaColors.deepGreen).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative glow
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HodaColors.turquoise.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HodaColors.gold.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                // Top brand & date chip row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const HodaLogo(size: 38),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'هُدا',
                              style: TextStyle(
                                fontFamily: HodaTheme.displayFontFamily,
                                fontSize: 22,
                                color: HodaColors.goldLight,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'همراه روزانه معنوی',
                              style: TextStyle(
                                fontFamily: HodaTheme.fontFamily,
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Jalali date chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: HodaColors.goldLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: HodaColors.goldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            JalaliDate.fullFa(DateTime.now()),
                            style: const TextStyle(
                              fontFamily: HodaTheme.fontFamily,
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Greeting & inspirational verse snippet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: HodaColors.gold.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.light_mode_rounded,
                          size: 18,
                          color: HodaColors.goldLight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»',
                              style: TextStyle(
                                fontFamily: HodaTheme.arabicFontFamily,
                                fontSize: 15,
                                color: HodaColors.goldLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'آگاه باشید که با یاد خدا دل‌ها آرام می‌گیرد',
                              style: TextStyle(
                                fontFamily: HodaTheme.fontFamily,
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Action Bar inside Hero
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onOpenSalawat,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.touch_app_rounded, size: 16, color: HodaColors.goldLight),
                              SizedBox(width: 6),
                              Text(
                                'شمارش صلوات',
                                style: TextStyle(
                                  fontFamily: HodaTheme.fontFamily,
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: onOpenSettings,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.notifications_active_outlined, size: 16, color: HodaColors.turquoiseLight),
                              SizedBox(width: 6),
                              Text(
                                'تنظیم اعلان‌ها',
                                style: TextStyle(
                                  fontFamily: HodaTheme.fontFamily,
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Featured Daily Zekr Highlight Card
  Widget _buildDailyZekrBanner(
    BuildContext context,
    ThemeData theme,
    DailyContent zekr,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: HodaColors.turquoise.withOpacity(isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: HodaColors.turquoise.withOpacity(isDark ? 0.08 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openDetail(context, zekr),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [HodaColors.turquoise, HodaColors.forestGreen],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'ذکر اختصاصی امروز',
                            style: TextStyle(
                              fontFamily: HodaTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? HodaColors.darkSurface : HodaColors.cream.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ArabicText(
                    zekr.arabic,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  zekr.persian,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
