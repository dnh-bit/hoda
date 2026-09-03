import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../services/notification_service.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/hoda_logo.dart';
import 'content_detail_screen.dart';
import 'content_list_view.dart';
import 'favorites_screen.dart';
import 'home_tab.dart';
import 'salawat_screen.dart';
import 'settings_screen.dart';

/// App shell: manages bottom navigation, content snapshots, notification deep links,
/// and AppBar with integrated spiritual badge and quick actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int tabHome = 0;
  static const int tabVerses = 1;
  static const int tabHadiths = 2;
  static const int tabNahj = 3;
  static const int tabMartyrs = 4;
  static const int tabSalawat = 5;

  static const Map<String, int> _tabForPayloadType = <String, int>{
    'verse': tabVerses,
    'hadith': tabHadiths,
    'martyr': tabMartyrs,
    'nahj': tabNahj,
  };

  static const Duration _openDelay = Duration(milliseconds: 350);

  int _currentIndex = tabHome;
  HodaContent _content = const HodaContent();
  bool _loading = true;
  String? _error;
  String? _pendingUid;
  Timer? _openTimer;

  @override
  void initState() {
    super.initState();
    _load();

    NotificationService.onNotificationTap.addListener(_onNotificationTap);
    NotificationService.onNotificationOpen.addListener(_onNotificationOpen);
    _applyPayloadType(
      NotificationService.onNotificationTap.value,
      viaSetState: false,
    );
    _requestOpen(NotificationService.onNotificationOpen.value);
  }

  @override
  void dispose() {
    NotificationService.onNotificationTap.removeListener(_onNotificationTap);
    NotificationService.onNotificationOpen.removeListener(_onNotificationOpen);
    _openTimer?.cancel();
    super.dispose();
  }

  void _onNotificationTap() {
    _applyPayloadType(NotificationService.onNotificationTap.value);
  }

  void _onNotificationOpen() {
    _requestOpen(NotificationService.onNotificationOpen.value);
  }

  void _applyPayloadType(String? type, {bool viaSetState = true}) {
    if (type == null) return;
    final target = _tabForPayloadType[type] ?? tabHome;
    if (!viaSetState) {
      _currentIndex = target;
      return;
    }
    if (!mounted || _currentIndex == target) return;
    setState(() => _currentIndex = target);
  }

  void _requestOpen(String? uid) {
    if (uid == null || uid.isEmpty) return;
    if (_loading) {
      _pendingUid = uid;
      return;
    }
    _scheduleOpen(uid);
  }

  void _scheduleOpen(String uid) {
    _openTimer?.cancel();
    _openTimer = Timer(_openDelay, () {
      if (!mounted) return;
      final DailyContent? item = _content.findByUid(uid);
      if (item == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContentDetailScreen(content: item)),
      );
    });
  }

  Future<void> _load() async {
    HodaContent content = const HodaContent();
    String? error;

    try {
      content = await ContentRepository.loadAll();
      if (content.isEmpty) error = 'محتوایی در پایگاه داده یافت نشد';
    } catch (e) {
      error = e.toString();
    }

    await SalawatStore.ensureLoaded();

    if (!mounted) return;
    setState(() {
      _content = content;
      _error = error;
      _loading = false;
      _shuffling = false;
    });

    final pending = _pendingUid;
    _pendingUid = null;
    if (pending != null && error == null) _scheduleOpen(pending);
  }

  bool _shuffling = false;

  Future<void> _shuffleDaily() async {
    if (_shuffling) return;
    setState(() => _shuffling = true);
    try {
      await ContentRepository.shuffleDaily();
      await NotificationService.restoreSchedule();
    } catch (_) {}
    await _load();
  }

  void _openSalawat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SalawatScreen()),
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _selectTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: HodaColors.turquoise),
        ),
      );
    }

    if (_error != null) return _buildErrorScaffold(_error!);

    return Scaffold(
      appBar: _buildAppBar(theme, isDark),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            content: _content,
            onOpenVerses: () => _selectTab(tabVerses),
            onOpenHadiths: () => _selectTab(tabHadiths),
            onOpenNahj: () => _selectTab(tabNahj),
            onOpenMartyrs: () => _selectTab(tabMartyrs),
            onRefresh: _load,
            onShuffle: _shuffleDaily,
            onOpenSettings: _openSettings,
            onOpenSalawat: () => _selectTab(tabSalawat),
            shuffling: _shuffling,
          ),
          ContentListView(
            items: _content.verses,
            heading: 'آیات نورانی قرآن مجید',
            emptyText: 'آیه‌ای یافت نشد',
            icon: Icons.menu_book_rounded,
          ),
          ContentListView(
            items: _content.hadiths,
            heading: 'احادیث معصومین (علیهم‌السلام)',
            emptyText: 'حدیثی یافت نشد',
            icon: Icons.format_quote_rounded,
            familiesOf: (item) => item.family,
          ),
          ContentListView(
            items: _content.nahj,
            heading: 'حکمت‌های نهج‌البلاغه',
            emptyText: 'حکمتی یافت نشد',
            icon: Icons.auto_stories_rounded,
          ),
          ContentListView(
            items: _content.martyrs,
            heading: 'فرازهایی از وصایای شهدا',
            emptyText: 'وصیتی یافت نشد',
            icon: Icons.military_tech_rounded,
          ),
          const SalawatCounterView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectTab,
          backgroundColor: isDark ? HodaColors.darkSurface : Colors.white,
          indicatorColor: (isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen).withOpacity(0.18),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: HodaColors.forestGreen),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded, color: HodaColors.forestGreen),
              label: 'آیات',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_quote_outlined),
              selectedIcon: Icon(Icons.format_quote_rounded, color: HodaColors.forestGreen),
              label: 'حدیث',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded, color: HodaColors.forestGreen),
              label: 'حکمت',
            ),
            NavigationDestination(
              icon: Icon(Icons.military_tech_outlined),
              selectedIcon: Icon(Icons.military_tech_rounded, color: HodaColors.forestGreen),
              label: 'وصایا',
            ),
            NavigationDestination(
              icon: Icon(Icons.touch_app_outlined),
              selectedIcon: Icon(Icons.touch_app_rounded, color: HodaColors.forestGreen),
              label: 'صلوات',
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HodaLogo(size: 26),
          const SizedBox(width: 8),
          Text(
            'هُدا',
            style: TextStyle(
              fontFamily: HodaTheme.displayFontFamily,
              fontSize: 22,
              color: isDark ? HodaColors.goldLight : HodaColors.cream,
            ),
          ),
        ],
      ),
      leading: _buildSalawatBadge(),
      leadingWidth: 84,
      actions: [
        IconButton(
          tooltip: 'تنظیمات',
          icon: const Icon(Icons.settings_outlined, size: 22),
          onPressed: _openSettings,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSalawatBadge() {
    return ValueListenableBuilder<Map<int, SalawatCounts>>(
      valueListenable: SalawatStore.counts,
      builder: (context, counts, _) {
        return ValueListenableBuilder<int>(
          valueListenable: SalawatStore.selectedId,
          builder: (context, selectedId, _) {
            final tally = counts[selectedId] ?? SalawatCounts.zero;
            return Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Material(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _openSalawat,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 15,
                            color: HodaColors.goldLight,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 42),
                            child: Text(
                              FaNum.number(tally.today),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                fontFamily: HodaTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('هُدا')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 60, color: HodaColors.gold),
              const SizedBox(height: 16),
              const Text(
                'خطا در بارگذاری محتوا',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش دوباره'),
                style: FilledButton.styleFrom(backgroundColor: HodaColors.forestGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
