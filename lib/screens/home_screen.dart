import 'package:flutter/material.dart';

import '../services/content_repository.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../widgets/hoda_logo.dart';
import 'content_list_view.dart';
import 'favorites_screen.dart';
import 'home_tab.dart';
import 'salawat_screen.dart';
import 'settings_screen.dart';

/// App shell: owns the bottom navigation, the loaded content snapshot and the
/// salawat tally. Secondary pages (favorites, settings, salawat) are pushed as
/// routes so the bottom bar always reflects the visible tab.
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

  int _currentIndex = tabHome;
  HodaContent _content = const HodaContent();
  SalawatCounts _salawat = SalawatCounts.zero;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

    final counts = await SalawatStore.load();

    if (!mounted) return;
    setState(() {
      _content = content;
      _salawat = counts;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _openSalawat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SalawatScreen()),
    );
    final counts = await SalawatStore.load();
    if (!mounted) return;
    setState(() => _salawat = counts);
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
            salawatToday: _salawat.today,
            onOpenVerses: () => _selectTab(tabVerses),
            onOpenHadiths: () => _selectTab(tabHadiths),
            onOpenMartyrs: () => _selectTab(tabMartyrs),
            onOpenNahj: () => _selectTab(tabNahj),
            onOpenSalawat: _openSalawat,
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
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
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
          tooltip: 'ذکر صلوات',
          icon: const Icon(Icons.favorite_outline),
          onPressed: _openSalawat,
        ),
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
