import 'package:flutter/material.dart';

import '../services/content_repository.dart';
import '../services/notification_service.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/hoda_logo.dart';
import 'content_list_view.dart';
import 'favorites_screen.dart';
import 'home_tab.dart';
import 'salawat_screen.dart';
import 'settings_screen.dart';

/// App shell: owns the bottom navigation (خانه، آیات، حدیث، وصایا، حکمت، صلوات)
/// and the loaded content snapshot.
///
/// The salawat tally lives in [SalawatStore]; it is shown as a compact badge in
/// the AppBar corner (the `leading` slot, i.e. the visual top-right in this RTL
/// UI) which opens the full-screen counter, and as the «صلوات» tab which embeds
/// the very same counter widget. Favorites and settings are pushed as routes so
/// the bottom bar always reflects the visible tab.
///
/// It is also the target of notification tap routing: it listens to
/// [NotificationService.onNotificationTap] and switches to the tab that matches
/// the tapped notification's content type.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int tabHome = 0;
  static const int tabVerses = 1;
  static const int tabHadiths = 2;
  static const int tabMartyrs = 3;
  static const int tabNahj = 4;
  static const int tabSalawat = 5;

  /// Notification payload type -> tab. Anything missing (including `random`
  /// when the concrete type could not be resolved) falls back to [tabHome].
  static const Map<String, int> _tabForPayloadType = <String, int>{
    'verse': tabVerses,
    'hadith': tabHadiths,
    'martyr': tabMartyrs,
    'nahj': tabNahj,
  };

  int _currentIndex = tabHome;
  HodaContent _content = const HodaContent();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();

    // A cold start can emit the launch payload before this listener is
    // attached, so the current value is applied once up-front.
    NotificationService.onNotificationTap.addListener(_onNotificationTap);
    _applyPayloadType(
      NotificationService.onNotificationTap.value,
      viaSetState: false,
    );
  }

  @override
  void dispose() {
    NotificationService.onNotificationTap.removeListener(_onNotificationTap);
    super.dispose();
  }

  void _onNotificationTap() {
    _applyPayloadType(NotificationService.onNotificationTap.value);
  }

  /// Switches to the tab matching a notification payload type.
  ///
  /// The service resets its notifier to null before every emission, so a null
  /// value simply means «nothing to route».
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

  Future<void> _load() async {
    HodaContent content = const HodaContent();
    String? error;

    try {
      content = await ContentRepository.loadAll();
      if (content.isEmpty) error = 'محتوایی در دیتابیس یافت نشد';
    } catch (e) {
      error = e.toString();
    }

    // Fills SalawatStore.counts; the AppBar badge listens to it directly.
    await SalawatStore.ensureLoaded();

    if (!mounted) return;
    setState(() {
      _content = content;
      _error = error;
      _loading = false;
    });
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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: HodaColors.turquoise),
        ),
      );
    }

    if (_error != null) return _buildErrorScaffold(_error!);

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            content: _content,
            onOpenVerses: () => _selectTab(tabVerses),
            onOpenHadiths: () => _selectTab(tabHadiths),
            onOpenMartyrs: () => _selectTab(tabMartyrs),
            onOpenNahj: () => _selectTab(tabNahj),
            onRefresh: _load,
          ),
          ContentListView(
            items: _content.verses,
            heading: 'آیات نورانی قرآن',
            emptyText: 'آیه‌ای یافت نشد',
            icon: Icons.menu_book,
          ),
          ContentListView(
            items: _content.hadiths,
            heading: 'احادیث معصومین (ع)',
            emptyText: 'حدیثی یافت نشد',
            icon: Icons.format_quote,
          ),
          ContentListView(
            items: _content.martyrs,
            heading: 'وصایای شهدا',
            emptyText: 'وصیتی یافت نشد',
            icon: Icons.volunteer_activism,
          ),
          ContentListView(
            items: _content.nahj,
            heading: 'حکمت‌های نهج‌البلاغه',
            emptyText: 'حکمتی یافت نشد',
            icon: Icons.auto_stories,
          ),
          // Same counter widget as the full-screen page opened from the badge;
          // both read and write the shared SalawatStore tally.
          const SalawatCounterView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'آیات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote_outlined),
            activeIcon: Icon(Icons.format_quote),
            label: 'حدیث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism),
            label: 'وصایا',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_outlined),
            activeIcon: Icon(Icons.auto_stories),
            label: 'حکمت',
          ),
          BottomNavigationBarItem(
            // The nav bar pairs an outlined icon with a filled active one;
            // touch_app is the counting-gesture icon that has both variants.
            icon: Icon(Icons.touch_app_outlined),
            activeIcon: Icon(Icons.touch_app),
            label: 'صلوات',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      // The UI is RTL (fa_IR), so the *leading* slot is the visual top-right
      // corner — that is where the salawat badge belongs. The bookmark and
      // settings actions stay in the opposite corner.
      leadingWidth: 88,
      leading: _buildSalawatBadge(),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HodaLogo(size: 32),
          const SizedBox(width: 8),
          Text('هُدا', style: HodaTheme.appNameStyle(context, size: 26)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'نشان‌شده‌ها',
          icon: const Icon(Icons.bookmark_outline),
          onPressed: _openFavorites,
        ),
        IconButton(
          tooltip: 'تنظیمات',
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  /// Compact salawat counter for the AppBar corner: a tap icon + the persisted
  /// total in Persian digits, tappable to open the full-screen counter.
  /// Rebuilds itself from [SalawatStore.counts], so a tap on the counter screen
  /// is reflected here without the shell having to reload anything.
  Widget _buildSalawatBadge() {
    final foreground = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;

    return ValueListenableBuilder<SalawatCounts>(
      valueListenable: SalawatStore.counts,
      builder: (context, counts, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Tooltip(
              message: 'صلوات‌شمار — مجموع ${FaNum.number(counts.total)} صلوات',
              child: Material(
                color: foreground.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openSalawat,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A tap/count icon, deliberately not a heart.
                        const Icon(
                          Icons.ads_click,
                          size: 17,
                          color: HodaColors.goldLight,
                        ),
                        const SizedBox(width: 5),
                        // Clamped so a five/six-digit tally cannot overflow the
                        // fixed leading slot of the AppBar.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 40),
                          child: Text(
                            FaNum.number(counts.total),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontFamily: HodaTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
              const Icon(Icons.error_outline, size: 64, color: HodaColors.gold),
              const SizedBox(height: 16),
              const Text(
                'خطا در بارگذاری محتوا',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
