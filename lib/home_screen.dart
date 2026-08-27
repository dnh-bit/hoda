import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _salawatCount = 0;
  Map<String, dynamic>? _daily;
  List<DailyContent> _hadiths = [];
  List<DailyContent> _martyrs = [];
  List<DailyContent> _nahj = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static String _s(Object? v) => v?.toString() ?? '';

  Future<void> _loadData() async {
    Map<String, dynamic>? daily;
    List<DailyContent> hadiths = [];
    List<DailyContent> martyrs = [];
    List<DailyContent> nahj = [];
    String? error;

    try {
      daily = await DatabaseHelper.getDailyContent();

      final hRows = await DatabaseHelper.getAllHadiths();
      hadiths = hRows
          .map((e) => DailyContent(
              title: 'حدیث',
              arabic: _s(e['arabic']),
              persian: _s(e['farsi']),
              source: _s(e['source'])))
          .toList();

      final mRows = await DatabaseHelper.getAllMartyrs();
      martyrs = mRows.map((e) {
        final excerpt = _s(e['excerpt']);
        final trimmed =
            excerpt.length > 400 ? '${excerpt.substring(0, 400)}...' : excerpt;
        return DailyContent(
            title: _s(e['name']).isEmpty ? 'وصیت شهید' : _s(e['name']),
            persian: trimmed,
            source: _s(e['name']));
      }).toList();

      final nRows = await DatabaseHelper.getAllNahj();
      nahj = nRows
          .map((e) => DailyContent(
              title: 'حکمت ${_s(e['number'])}',
              arabic: _s(e['arabic']),
              persian: _s(e['farsi']),
              source: 'نهج‌البلاغه'))
          .toList();
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _daily = daily;
      _hadiths = hadiths;
      _martyrs = martyrs;
      _nahj = nahj;
      _error = (daily == null || error != null) ? (error ?? 'دیتابیس خالی است') : null;
      _loading = false;
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: HodaColors.turquoise)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('هُدا')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: HodaColors.gold),
                const SizedBox(height: 16),
                const Text('خطا در بارگذاری محتوا',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadData();
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

    final v = _daily!['verse'];
    final h = _daily!['hadith'];
    final m = _daily!['martyr'];

    final verseCard = DailyContent(
        title: 'آیه روز',
        arabic: v != null ? _s(v['arabic']) : '',
        persian: v != null ? _s(v['farsi']) : 'امروز محتوایی موجود نیست.',
        source: v != null ? _s(v['ref']) : '');

    final hadithCard = DailyContent(
        title: 'حدیث روز',
        arabic: h != null ? _s(h['arabic']) : '',
        persian: h != null ? _s(h['farsi']) : 'امروز محتوایی موجود نیست.',
        source: h != null ? _s(h['source']) : '');

    final martyrExcerpt = m != null ? _s(m['excerpt']) : '';
    final martyrCard = DailyContent(
        title: 'وصیت شهید',
        persian: martyrExcerpt.isEmpty
            ? 'امروز محتوایی موجود نیست.'
            : (martyrExcerpt.length > 300
                ? '${martyrExcerpt.substring(0, 300)}...'
                : martyrExcerpt),
        source: m != null ? _s(m['name']) : '');

    final pages = <Widget>[
      _DailyCardsPage(
          verse: verseCard, hadith: hadithCard, martyr: martyrCard),
      _ListContentPage(items: _hadiths, heading: 'احادیث'),
      _ListContentPage(items: _martyrs, heading: 'وصایای شهدا'),
      _ListContentPage(items: _nahj, heading: 'حکمت‌های نهج‌البلاغه'),
      _SalawatPage(
        count: _salawatCount,
        onIncrement: () => setState(() => _salawatCount++),
        onReset: () => setState(() => _salawatCount = 0),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HodaLogo(size: 32),
            const SizedBox(width: 8),
            Text('هُدا', style: HodaTheme.appNameStyle(context, size: 26)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تنظیمات',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'آیه'),
          BottomNavigationBarItem(
              icon: Icon(Icons.format_quote_outlined),
              activeIcon: Icon(Icons.format_quote),
              label: 'حدیث'),
          BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'وصایا'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: 'حکمت'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'صلوات'),
        ],
      ),
    );
  }
}

class _HodaLogo extends StatelessWidget {
  final double size;
  const _HodaLogo({this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/brand/hoda-logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [HodaColors.turquoise, HodaColors.gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child:
              const Icon(Icons.flight, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  final DailyContent content;
  final Color borderColor;
  final IconData icon;

  const ContentCard(
      {super.key,
      required this.content,
      required this.borderColor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.6),
      ),
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
                  child: Text(content.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: borderColor)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (content.arabic.isNotEmpty) ...[
              Text(content.arabic,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(height: 1.9, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Divider(color: borderColor.withOpacity(0.4)),
              const SizedBox(height: 12),
            ],
            Text(content.persian,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge),
            if (content.source.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(content.source,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyCardsPage extends StatelessWidget {
  final DailyContent verse;
  final DailyContent hadith;
  final DailyContent martyr;

  const _DailyCardsPage(
      {required this.verse, required this.hadith, required this.martyr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Center(
          child: Column(
            children: [
              const _HodaLogo(size: 84),
              const SizedBox(height: 12),
              Text('به هُدا خوش آمدید',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('همراه معنوی روزانه شما',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ContentCard(content: verse, borderColor: HodaColors.gold, icon: Icons.menu_book),
        const SizedBox(height: 16),
        ContentCard(
            content: hadith,
            borderColor: HodaColors.turquoise,
            icon: Icons.format_quote),
        const SizedBox(height: 16),
        ContentCard(
            content: martyr,
            borderColor: HodaColors.gold,
            icon: Icons.volunteer_activism),
      ],
    );
  }
}

class _ListContentPage extends StatelessWidget {
  final List<DailyContent> items;
  final String heading;
  const _ListContentPage({required this.items, required this.heading});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text('محتوایی موجود نیست',
            style: Theme.of(context).textTheme.titleMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(heading,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          );
        }
        return ContentCard(
            content: items[index - 1],
            borderColor:
                index.isEven ? HodaColors.turquoise : HodaColors.gold,
            icon: Icons.auto_stories);
      },
    );
  }
}

class _SalawatPage extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  const _SalawatPage(
      {required this.count, required this.onIncrement, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('اللّهُمَّ صَلِّ عَلَی مُحَمَّدٍ وَ آلِ مُحَمَّد',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('ذکر صلوات', style: theme.textTheme.titleMedium),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [HodaColors.turquoise, HodaColors.forestGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  border: Border.all(color: HodaColors.gold, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: HodaColors.turquoise.withOpacity(0.35),
                        blurRadius: 24,
                        spreadRadius: 2),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$count',
                        style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    const Text('برای شمارش لمس کنید',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('صفر کردن شمارنده'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: HodaColors.gold),
                foregroundColor: theme.colorScheme.tertiary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تنظیمات',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text('حالت شب'),
                  subtitle: Text(isDark ? 'فعال' : 'غیرفعال'),
                  secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.tertiary),
                  value: isDark,
                  onChanged: (_) => ThemeController.toggle(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
