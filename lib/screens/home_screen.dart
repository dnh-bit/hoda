import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import '../services/content_repository.dart';
import '../services/favorites_store.dart';
import '../services/notification_service.dart';
import '../services/salawat_store.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/hoda_app_bar.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/hoda_wordmark.dart';
import '../widgets/hoda_nav_bar.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/motion.dart';
import 'content_detail_screen.dart';
import 'content_list_view.dart';
import 'favorites_screen.dart';
import 'home_tab.dart';
import 'salawat_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// App shell: owns the navigation (خانه، آیات، حدیث، وصایا، حکمت، ذکر) and the
/// loaded content snapshot.
///
/// The salawat tally lives in [SalawatStore]; it is shown as a compact badge in
/// the AppBar corner (the `leading` slot, i.e. the visual top-right in this RTL
/// UI) which opens the full-screen counter, and as the «ذکر» destination which
/// embeds the very same counter widget. Search, favourites and settings are
/// pushed as routes so the nav bar always reflects the visible tab.
///
/// It is also the target of notification tap routing, in two steps:
/// 1. [NotificationService.onNotificationTap] carries the content *type* and
///    switches to the matching tab (see [_applyPayloadType]).
/// 2. [NotificationService.onNotificationOpen] carries the content *uid* and
///    pushes [ContentDetailScreen] for that exact item shortly after.
///
/// Both work on a cold start too: the launch payload is replayed after the first
/// frame, and a uid that arrives while the database is still loading is parked
/// in [_pendingUid] and honoured once [_load] finishes.
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

  /// Waiting period between the tab switch and the detail push, so the
  /// [IndexedStack] swap and the nav-bar animation settle first and the pushed
  /// route animates over a finished frame.
  static const Duration _openDelay = Duration(milliseconds: 350);

  int _currentIndex = tabHome;
  HodaContent _content = const HodaContent();
  bool _loading = true;
  String? _error;

  /// A uid that arrived before the database finished loading (the cold-start
  /// case). Honoured at the end of [_load].
  String? _pendingUid;

  /// Pending detail push, cancelled on dispose and superseded by a newer tap.
  Timer? _openTimer;

  bool _shuffling = false;

  @override
  void initState() {
    super.initState();
    _load();

    // A cold start can emit the launch payload before these listeners are
    // attached, so the current values are applied once up-front.
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

  /// Switches to the tab matching a notification payload type.
  ///
  /// The service resets its notifier to null before every emission, so a null
  /// value simply means «nothing to route».
  void _applyPayloadType(String? type, {bool viaSetState = true}) {
    if (type == null) return;
    final int target = _tabForPayloadType[type] ?? tabHome;
    if (!viaSetState) {
      _currentIndex = target;
      return;
    }
    if (!mounted || _currentIndex == target) return;
    setState(() => _currentIndex = target);
  }

  /// Entry point for [NotificationService.onNotificationOpen]: remembers the
  /// uid while the content is still loading, otherwise arms the delayed push.
  void _requestOpen(String? uid) {
    if (uid == null || uid.isEmpty) return;
    if (_loading) {
      _pendingUid = uid;
      return;
    }
    _scheduleOpen(uid);
  }

  /// Pushes [ContentDetailScreen] for [uid] after [_openDelay].
  ///
  /// An unknown uid (content removed, or a payload from another database
  /// revision) is silently ignored: the user simply stays on the tab that
  /// [_applyPayloadType] selected.
  void _scheduleOpen(String uid) {
    _openTimer?.cancel();
    _openTimer = Timer(_openDelay, () {
      if (!mounted) return;
      final DailyContent? item = _content.findByUid(uid);
      if (item == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ContentDetailScreen(content: item),
        ),
      );
    });
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

    // Fills SalawatStore.counts and the bookmark set; the app bar badge and
    // every bookmark button listen to them directly.
    await SalawatStore.ensureLoaded();
    await FavoritesStore.ensureLoaded();

    if (!mounted) return;
    setState(() {
      _content = content;
      _error = error;
      _loading = false;
      _shuffling = false;
    });

    // Cold start: the notification uid arrived while this load was running.
    final String? pending = _pendingUid;
    _pendingUid = null;
    if (pending != null && error == null) _scheduleOpen(pending);
  }

  /// The «محتوای تازه» action: re-picks every daily card from a fresh no-repeat
  /// shuffle and re-arms the daily notifications so their bodies match the new
  /// picks the next time they fire.
  Future<void> _shuffleDaily() async {
    if (_shuffling) return;
    setState(() => _shuffling = true);
    try {
      await ContentRepository.shuffleDaily();
      await NotificationService.restoreSchedule();
    } catch (_) {
      // Never let the refresh button break the shell.
    }
    await _load();
  }

  void _openSalawat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SalawatScreen()),
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesScreen(content: _content),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(content: _content),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingShell();
    if (_error != null) return _buildErrorScaffold(_error!);

    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(),
      body: HodaBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            HomeTab(
              content: _content,
              onOpenVerses: () => _selectTab(tabVerses),
              onOpenHadiths: () => _selectTab(tabHadiths),
              onOpenMartyrs: () => _selectTab(tabMartyrs),
              onOpenNahj: () => _selectTab(tabNahj),
              onRefresh: _load,
              onShuffle: _shuffleDaily,
              onOpenSettings: _openSettings,
              onOpenSalawat: _openSalawat,
              onOpenFavorites: _openFavorites,
              onOpenSearch: _openSearch,
              shuffling: _shuffling,
            ),
            ContentListView(
              items: _content.verses,
              heading: 'آیات نورانی قرآن',
              emptyText: 'آیه‌ای یافت نشد',
              style: ContentStyle.verse,
            ),
            ContentListView(
              items: _content.hadiths,
              heading: 'احادیث معصومین (ع)',
              emptyText: 'حدیثی یافت نشد',
              style: ContentStyle.hadith,
              familiesOf: (DailyContent item) => item.family,
            ),
            ContentListView(
              items: _content.martyrs,
              heading: 'وصایای شهدا',
              emptyText: 'وصیتی یافت نشد',
              style: ContentStyle.martyr,
            ),
            ContentListView(
              items: _content.nahj,
              heading: 'حکمت‌های نهج‌البلاغه',
              emptyText: 'حکمتی یافت نشد',
              style: ContentStyle.nahj,
            ),
            // Same counter widget as the full-screen page opened from the badge;
            // both read and write the shared SalawatStore tally.
            const SalawatCounterView(),
          ],
        ),
      ),
      bottomNavigationBar: HodaNavBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        items: <HodaNavItem>[
          HodaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'خانه',
            color: HodaColors.turquoise,
          ),
          HodaNavItem(
            icon: ContentStyle.verse.iconOutlined,
            activeIcon: ContentStyle.verse.icon,
            label: 'آیات',
            color: ContentStyle.verse.colorOf(context),
          ),
          HodaNavItem(
            icon: ContentStyle.hadith.iconOutlined,
            activeIcon: ContentStyle.hadith.icon,
            label: 'حدیث',
            color: ContentStyle.hadith.colorOf(context),
          ),
          HodaNavItem(
            icon: ContentStyle.martyr.iconOutlined,
            activeIcon: ContentStyle.martyr.icon,
            label: 'وصایا',
            color: ContentStyle.martyr.colorOf(context),
          ),
          HodaNavItem(
            icon: ContentStyle.nahj.iconOutlined,
            activeIcon: ContentStyle.nahj.icon,
            label: 'حکمت',
            color: ContentStyle.nahj.colorOf(context),
          ),
          const HodaNavItem(
            icon: Icons.touch_app_outlined,
            activeIcon: Icons.touch_app,
            label: 'ذکر',
            color: HodaColors.turquoise,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return HodaAppBar(
      leadingWidth: 78,
      leading: _SalawatBadge(onTap: _openSalawat),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HodaLogo(size: 30),
          const SizedBox(width: 8),
          const HodaWordmark(height: 34),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'جست‌وجو',
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 40),
          icon: const Icon(Icons.search),
          onPressed: _openSearch,
        ),
        _FavoritesAction(onTap: _openFavorites),
        IconButton(
          tooltip: 'تنظیمات',
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 40),
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildErrorScaffold(String message) {
    final HodaPalette palette = HodaPalette.of(context);
    return Scaffold(
      appBar: const HodaAppBar(titleText: 'هُدا'),
      body: HodaBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: palette.card(accentColor: HodaColors.gold),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: palette.tintGradient(HodaColors.gold),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 32,
                      color: HodaColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطا در بارگذاری محتوا',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
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
        ),
      ),
    );
  }
}

/// Compact dhikr counter for the AppBar corner: a tap icon plus the persisted
/// total of the selected dhikr in Persian digits, tappable to open the
/// full-screen counter.
///
/// Rebuilds itself from [SalawatStore.counts] and the selection, so a tap on the
/// counter screen is reflected here without the shell reloading anything.
class _SalawatBadge extends StatelessWidget {
  const _SalawatBadge({required this.onTap});

  final VoidCallback onTap;

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
            return Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Tooltip(
                  message: 'ذکرشمار — مجموع ${FaNum.number(tally.total)} بار',
                  child: PressableScale(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: HodaRadius.all(HodaRadius.pill),
                        border: Border.all(
                          color: HodaColors.goldLight.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.ads_click,
                            size: 16,
                            color: HodaColors.goldGlow,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 34),
                            child: Text(
                              FaNum.number(tally.total),
                              maxLines: 1,
                              softWrap: false,
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
}

/// Bookmark action with a live count dot.
class _FavoritesAction extends StatelessWidget {
  const _FavoritesAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesStore.uids,
      builder: (BuildContext context, Set<String> uids, _) {
        return IconButton(
          tooltip: 'نشان‌شده‌ها',
          padding: const EdgeInsets.symmetric(horizontal: 6),
          constraints: const BoxConstraints(minWidth: 40),
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Icon(uids.isEmpty ? Icons.bookmark_outline : Icons.bookmark),
              if (uids.isNotEmpty)
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: HodaColors.goldLight,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmering placeholder shell shown while the database loads — the app looks
/// like itself from the very first frame.
class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HodaAppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const HodaLogo(size: 30),
            const SizedBox(width: 8),
            const HodaWordmark(height: 34),
          ],
        ),
      ),
      body: HodaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: const <Widget>[
            SkeletonBox(height: 190, radius: HodaRadius.xl),
            SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: SkeletonBox(height: 86, radius: HodaRadius.md)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 86, radius: HodaRadius.md)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 86, radius: HodaRadius.md)),
              ],
            ),
            SizedBox(height: 22),
            SkeletonCard(),
            SizedBox(height: 14),
            SkeletonCard(lines: 2),
          ],
        ),
      ),
    );
  }
}
