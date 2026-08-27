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
  List<DailyContent> _verses = [];
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
    List<DailyContent> verses = [];
    List<DailyContent> hadiths = [];
    List<DailyContent> martyrs = [];
    List<DailyContent> nahj = [];
    String? error;

    try {
      daily = await DatabaseHelper.getDailyContent();

      final vRows = await DatabaseHelper.getAllVerses();
      verses = vRows
          .map((e) => DailyContent(
              title: 'آیه ${_s(e['ayah'])}',
              arabic: _s(e['arabic']),
              persian: _s(e['farsi']),
              source: _s(e['ref'])))
          .toList();

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
      _verses = verses;
      _hadiths = hadiths;
      _martyrs = martyrs;
      _nahj = nahj;
      _error =
          (daily == null || error != null) ? (error ?? 'دیتابیس خالی است') : null;
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

    final v = _daily?['verse'];
    final h = _daily?['hadith'];
    final m = _daily?['martyr'];

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
      // Index 0 = خانه (Home) — no longer the آیه page
      _HomePage(
        verse: verseCard,
        hadith: hadithCard,
        martyr: martyrCard,
        salawatCount: _salawatCount,
        onSalawatTap: () => setState(() {
          _salawatCount++;
        }),
        onBrowseVerses: () => setState(() => _currentIndex = 1),
        onBrowseHadiths: () => setState(() => _currentIndex = 2),
        onBrowseMartyrs: () => setState(() => _currentIndex = 3),
        onBrowseNahj: () => setState(() => _currentIndex = 4),
      ),
      _ListContentPage(
          items: _verses,
          heading: 'آیات',
          emptyText: 'آیه‌ای یافت نشد',
          icon: Icons.menu_book),
      _ListContentPage(
          items: _hadiths,
          heading: 'احادیث',
          emptyText: 'حدیثی یافت نشد',
          icon: Icons.format_quote),
      _ListContentPage(
          items: _martyrs,
          heading: 'وصایای شهدا',
          emptyText: 'وصیتی یافت نشد',
          icon: Icons.volunteer_activism),
      _ListContentPage(
          items: _nahj,
          heading: 'حکمت‌های نهج‌البلاغه',
          emptyText: 'حکمتی یافت نشد',
          icon: Icons.auto_stories),
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'خانه'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'آیات'),
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
        'assets/brand/app-profile.png',
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

/// The new, welcoming "خانه" (Home) page — the real landing tab.
class _HomePage extends StatelessWidget {
  final DailyContent verse;
  final DailyContent hadith;
  final DailyContent martyr;
  final int salawatCount;
  final VoidCallback onSalawatTap;
  final VoidCallback onBrowseVerses;
  final VoidCallback onBrowseHadiths;
  final VoidCallback onBrowseMartyrs;
  final VoidCallback onBrowseNahj;

  const _HomePage({
    required this.verse,
    required this.hadith,
    required this.martyr,
    required this.salawatCount,
    required this.onSalawatTap,
    required this.onBrowseVerses,
    required this.onBrowseHadiths,
    required this.onBrowseMartyrs,
    required this.onBrowseNahj,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Greeting hero
        Container(
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
              const _HodaLogo(size: 92),
              const SizedBox(height: 14),
              Text('به هُدا خوش آمدید',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 6),
              Text('همراه معنوی روزانه شما',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  )),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text('برای نمایش امروز، لمس کنید',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // "Content of the day" section header
        _SectionHeader(
          icon: Icons.wb_sunny_outlined,
          title: 'محتوای امروز',
          action: Text(
            _todayFa(),
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        ContentCard(
            content: verse,
            borderColor: HodaColors.gold,
            icon: Icons.menu_book,
            onTap: onBrowseVerses),
        const SizedBox(height: 12),
        ContentCard(
            content: hadith,
            borderColor: HodaColors.turquoise,
            icon: Icons.format_quote,
            onTap: onBrowseHadiths),
        const SizedBox(height: 12),
        ContentCard(
            content: martyr,
            borderColor: HodaColors.gold,
            icon: Icons.volunteer_activism,
            onTap: onBrowseMartyrs),
        const SizedBox(height: 20),

        // Quick actions grid
        _SectionHeader(
            icon: Icons.auto_awesome_outlined, title: 'کاوش کنید'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _QuickTile(
              icon: Icons.menu_book,
              title: 'آیات',
              subtitle: '${verseCountHint()} آیه',
              color: HodaColors.gold,
              onTap: onBrowseVerses,
            ),
            _QuickTile(
              icon: Icons.format_quote,
              title: 'احادیث',
              subtitle: '${hadithCountHint()} حدیث',
              color: HodaColors.turquoise,
              onTap: onBrowseHadiths,
            ),
            _QuickTile(
              icon: Icons.volunteer_activism,
              title: 'وصایا',
              subtitle: 'وصایای شهدا',
              color: HodaColors.gold,
              onTap: onBrowseMartyrs,
            ),
            _QuickTile(
              icon: Icons.auto_stories,
              title: 'حکمت',
              subtitle: 'نهج‌البلاغه',
              color: HodaColors.turquoise,
              onTap: onBrowseNahj,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Salawat quick shortcut
        InkWell(
          onTap: onSalawatTap,
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
                const Icon(Icons.favorite,
                    color: HodaColors.gold, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ذکر صلوات',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('تسبیح برای آرامش قلب',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Text('$salawatCount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: HodaColors.turquoise)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static String _todayFa() {
    const week = [
      'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه',
      'چهارشنبه', 'پنجشنبه', 'جمعه'
    ];
    return week[DateTime.now().weekday % 7];
  }

  static int verseCountHint() => 130;
  static int hadithCountHint() => 40;
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;
  const _SectionHeader({required this.icon, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.tertiary),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary)),
          ],
        ),
      ),
    );
  }
}

class ContentCard extends StatelessWidget {
  final DailyContent content;
  final Color borderColor;
  final IconData icon;
  final VoidCallback? onTap;

  const ContentCard(
      {super.key,
      required this.content,
      required this.borderColor,
      required this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.6),
      ),
      child: InkWell(
        onTap: onTap,
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
                            fontWeight: FontWeight.bold,
                            color: borderColor)),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: borderColor),
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
      ),
    );
  }
}

class _ListContentPage extends StatelessWidget {
  final List<DailyContent> items;
  final String heading;
  final String emptyText;
  final IconData icon;
  const _ListContentPage(
      {required this.items,
      required this.heading,
      required this.emptyText,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText,
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
            icon: icon);
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
            const SizedBox(height: 8),
            const Text('نسخه ۰.۰.۴',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
