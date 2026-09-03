import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../services/favorites_store.dart';
import '../services/salawat_store.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../utils/jalali_date.dart';
import '../widgets/content_card.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/info_pill.dart';
import '../widgets/motion.dart';
import '../widgets/quick_tile.dart';
import '../widgets/section_header.dart';
import 'content_detail_screen.dart';

/// Home dashboard: a hero header with the greeting, date and search entry, a
/// live stat strip, today's content and the quick-explore grid.
///
/// The dhikr counter is intentionally *not* embedded here: it lives as a compact
/// badge in the app bar (reachable from every tab) and as its own destination.
class HomeTab extends StatelessWidget {
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
    required this.onOpenFavorites,
    required this.onOpenSearch,
    this.shuffling = false,
  });

  final HodaContent content;
  final VoidCallback onOpenVerses;
  final VoidCallback onOpenHadiths;
  final VoidCallback onOpenMartyrs;
  final VoidCallback onOpenNahj;
  final Future<void> Function() onRefresh;

  /// «تغییر محتوای امروز»: swaps every daily card for a fresh pick and re-arms
  /// the notifications with it.
  final Future<void> Function() onShuffle;

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSalawat;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenSearch;

  /// True while the parent re-picks content; the shuffle button shows a spinner.
  final bool shuffling;

  static const DailyContent _placeholder = DailyContent(
    title: 'محتوای امروز',
    persian: 'امروز محتوایی موجود نیست.',
  );

  /// Time-of-day greeting; small touch, big warmth.
  static String greeting(DateTime now) {
    final int h = now.hour;
    if (h >= 4 && h < 11) return 'صبح بخیر';
    if (h >= 11 && h < 15) return 'وقت بخیر';
    if (h >= 15 && h < 19) return 'عصر بخیر';
    return 'شب بخیر';
  }

  void _openDetail(BuildContext context, DailyContent item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContentDetailScreen(content: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    final DailyContent verse = content.dailyVerse ?? _placeholder;
    final DailyContent hadith = content.dailyHadith ?? _placeholder;
    final DailyContent martyr = content.dailyMartyr ?? _placeholder;
    final DailyContent? nahj = content.dailyNahj;
    final DailyContent? zekr = content.dailyZekr;

    int i = 0;
    Widget reveal(Widget child) =>
        Reveal(delay: Reveal.stagger(i++), child: child);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: HodaColors.turquoise,
      backgroundColor: palette.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
        children: <Widget>[
          reveal(_Hero(
            onOpenSearch: onOpenSearch,
            onOpenSalawat: onOpenSalawat,
            onOpenSettings: onOpenSettings,
          )),
          const SizedBox(height: 14),
          reveal(_StatStrip(
            content: content,
            onOpenSalawat: onOpenSalawat,
            onOpenFavorites: onOpenFavorites,
          )),
          const SizedBox(height: 22),
          reveal(SectionHeader(
            icon: Icons.wb_sunny_outlined,
            title: 'محتوای امروز',
            subtitle: JalaliDate.dateFa(DateTime.now()),
            color: palette.accent,
            action: _ShuffleButton(
              busy: shuffling,
              onTap: shuffling ? null : onShuffle,
            ),
          )),
          const SizedBox(height: 12),
          if (zekr != null) ...<Widget>[
            reveal(ContentCard(
              content: zekr,
              style: ContentStyle.zekr,
              badgeLabel: 'ذکر امروز',
              maxPersianLines: 4,
              maxArabicLines: 4,
              onTap: () => _openDetail(context, zekr),
            )),
            const SizedBox(height: 12),
          ],
          reveal(ContentCard(
            content: verse,
            style: ContentStyle.verse,
            badgeLabel: 'آیه روز',
            maxPersianLines: 5,
            maxArabicLines: 5,
            onTap: () => _openDetail(context, verse),
          )),
          const SizedBox(height: 12),
          reveal(ContentCard(
            content: hadith,
            style: ContentStyle.hadith,
            badgeLabel: 'حدیث روز',
            maxPersianLines: 5,
            maxArabicLines: 5,
            onTap: () => _openDetail(context, hadith),
          )),
          const SizedBox(height: 12),
          reveal(ContentCard(
            content: nahj ?? _placeholder,
            style: ContentStyle.nahj,
            badgeLabel: 'حکمت روز',
            maxPersianLines: 5,
            maxArabicLines: 5,
            onTap: () => _openDetail(context, nahj ?? _placeholder),
          )),
          const SizedBox(height: 12),
          reveal(ContentCard(
            content: martyr,
            style: ContentStyle.martyr,
            badgeLabel: 'وصیت شهید',
            maxPersianLines: 5,
            onTap: () => _openDetail(context, martyr),
          )),
          const SizedBox(height: 26),
          Center(child: reveal(const OrnamentDivider())),
          const SizedBox(height: 22),
          reveal(SectionHeader(
            icon: Icons.explore_outlined,
            title: 'کاوش در گنجینه',
            subtitle: 'همه محتوا، بدون نیاز به اینترنت',
            color: HodaColors.turquoise,
            action: InfoPill(
              label: 'جست‌وجو',
              icon: Icons.search,
              color: HodaColors.turquoise,
              dense: true,
              onTap: onOpenSearch,
            ),
          )),
          const SizedBox(height: 12),
          reveal(GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: <Widget>[
              QuickTile(
                icon: ContentStyle.verse.icon,
                title: 'آیات',
                subtitle: 'قرآن کریم',
                count: content.verses.length,
                color: ContentStyle.verse.colorOf(context),
                onTap: onOpenVerses,
              ),
              QuickTile(
                icon: ContentStyle.hadith.icon,
                title: 'احادیث',
                subtitle: 'سخنان اهل بیت (ع)',
                count: content.hadiths.length,
                color: ContentStyle.hadith.colorOf(context),
                onTap: onOpenHadiths,
              ),
              QuickTile(
                icon: ContentStyle.nahj.icon,
                title: 'حکمت‌ها',
                subtitle: 'نهج‌البلاغه',
                count: content.nahj.length,
                color: ContentStyle.nahj.colorOf(context),
                onTap: onOpenNahj,
              ),
              QuickTile(
                icon: ContentStyle.martyr.icon,
                title: 'وصایای شهدا',
                subtitle: 'پیام شهدا',
                count: content.martyrs.length,
                color: ContentStyle.martyr.colorOf(context),
                onTap: onOpenMartyrs,
              ),
            ],
          )),
          const SizedBox(height: 22),
          reveal(_NotificationCta(onTap: onOpenSettings)),
          const SizedBox(height: 24),
          reveal(const _Footer()),
        ],
      ),
    );
  }
}

/// The gradient hero: greeting, Jalali date, a search entry and two shortcuts.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.onOpenSearch,
    required this.onOpenSalawat,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSalawat;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final DateTime now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: HodaRadius.all(HodaRadius.xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: HodaColors.forestGreen.withOpacity(palette.isDark ? 0.5 : 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: Colors.white.withOpacity(0.07),
              tile: 62,
            ),
          ),
          PositionedDirectional(
            top: -40,
            end: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    HodaColors.goldLight.withOpacity(0.30),
                    HodaColors.goldLight.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const HodaLogo(size: 52, ring: true, glow: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            HomeTab.greeting(now),
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'همراه معنوی روزانه شما',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.onHeroMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InfoPill(
                        label: JalaliDate.fullFa(now),
                        icon: Icons.calendar_today_outlined,
                        onHero: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoPill(
                      label: FaNum.time(now.hour, now.minute),
                      icon: Icons.schedule,
                      onHero: true,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SearchEntry(onTap: onOpenSearch),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _HeroAction(
                        icon: Icons.ads_click,
                        label: 'ذکرشمار',
                        onTap: onOpenSalawat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroAction(
                        icon: Icons.notifications_active_outlined,
                        label: 'تنظیم اعلان',
                        onTap: onOpenSettings,
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
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: HodaRadius.all(HodaRadius.pill),
          border: Border.all(color: Colors.white.withOpacity(0.24)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.search, size: 19, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'جست‌وجو در آیات، احادیث، حکمت‌ها و وصایا',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white.withOpacity(0.85)),
              ),
            ),
            Icon(
              Icons.tune,
              size: 17,
              color: HodaColors.goldGlow.withOpacity(0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: HodaRadius.all(HodaRadius.sm),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 17, color: HodaColors.goldGlow),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three live numbers: today's dhikr, the lifetime tally and bookmarks.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.content,
    required this.onOpenSalawat,
    required this.onOpenFavorites,
  });

  final HodaContent content;
  final VoidCallback onOpenSalawat;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, SalawatCounts>>(
      valueListenable: SalawatStore.counts,
      builder: (BuildContext context, Map<int, SalawatCounts> counts, _) {
        return ValueListenableBuilder<int>(
          valueListenable: SalawatStore.selectedId,
          builder: (BuildContext context, int selectedId, __) {
            final SalawatCounts tally =
                counts[selectedId] ?? SalawatCounts.zero;
            return ValueListenableBuilder<Set<String>>(
              valueListenable: FavoritesStore.uids,
              builder: (BuildContext context, Set<String> favs, ___) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        icon: Icons.ads_click,
                        value: FaNum.number(tally.today),
                        label: 'ذکر امروز',
                        color: HodaColors.turquoise,
                        onTap: onOpenSalawat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.all_inclusive,
                        value: FaNum.number(tally.total),
                        label: 'مجموع ذکر',
                        color: HodaColors.gold,
                        onTap: onOpenSalawat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.bookmark_outline,
                        value: FaNum.number(favs.length),
                        label: 'نشان‌شده',
                        color: HodaColors.clay,
                        onTap: onOpenFavorites,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({required this.busy, required this.onTap});

  final bool busy;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return PressableScale(
      onTap: onTap == null ? null : () => onTap!(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: palette.pill(palette.accent, opacity: 0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (busy)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              )
            else
              Icon(Icons.autorenew, size: 16, color: palette.accent),
            const SizedBox(width: 7),
            Text(
              'محتوای تازه',
              style: theme.textTheme.labelSmall?.copyWith(color: palette.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single call-to-action card pointing at the notification manager.
class _NotificationCta extends StatelessWidget {
  const _NotificationCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: palette.card(accentColor: HodaColors.turquoise),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: palette.turquoiseGradient,
                borderRadius: HodaRadius.all(HodaRadius.sm),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('یادآور روزانه', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    'تا پنج اعلان در ساعت‌های دلخواه، با محتوای دلخواه',
                    maxLines: 2,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left,
              color: palette.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Column(
      children: <Widget>[
        const OrnamentDivider(width: 120),
        const SizedBox(height: 10),
        Text(
          'وَذَكِّرْ فَإِنَّ الذِّكْرَىٰ تَنفَعُ الْمُؤْمِنِينَ',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: HodaTheme.arabicFontFamily,
            fontFamilyFallback: HodaTheme.arabicFontFallback,
            fontSize: 15,
            height: 1.9,
            color: palette.accent.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'هُدا — گنجینه معنوی روزانه',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: palette.faint),
        ),
      ],
    );
  }
}
