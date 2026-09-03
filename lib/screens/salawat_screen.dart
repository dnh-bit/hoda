import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_helper.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';

/// Modern dhikr & salawat counter featuring animated tactile feedback,
/// visual target ring, quick preset goals, and seamless dhikr switching.
class SalawatCounterView extends StatefulWidget {
  const SalawatCounterView({super.key});

  @override
  State<SalawatCounterView> createState() => _SalawatCounterViewState();
}

class _SalawatCounterViewState extends State<SalawatCounterView>
    with SingleTickerProviderStateMixin {
  bool _loading = true;

  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0,
    upperBound: 0.08,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SalawatStore.ensureLoaded();
    await SalawatStore.loadDhikrs(DatabaseHelper.getAllSalawat);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _increment() {
    SalawatStore.increment();

    final today = SalawatStore.value.today;
    if (today % 100 == 0 || today == 33 || today == 34 || today == 100) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _pressController.forward().then((_) => _pressController.reverse());
  }

  Future<void> _resetTotal() async {
    final dhikr = SalawatStore.selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'صفر کردن شمارنده «${dhikr?.title ?? 'ذکر'}»',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'مجموع کل شمرده‌شده‌های این ذکر و شمارنده امروزش صفر می‌شود. '
          'این کار قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('صفر کن'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await SalawatStore.resetTotal();
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    unawaited(SalawatStore.flush());
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: HodaColors.turquoise),
      );
    }

    return ValueListenableBuilder<List<Dhikr>>(
      valueListenable: SalawatStore.dhikrs,
      builder: (context, dhikrs, _) {
        if (dhikrs.isEmpty) {
          return const Center(child: Text('ذکری یافت نشد.'));
        }
        return ValueListenableBuilder<int>(
          valueListenable: SalawatStore.selectedId,
          builder: (context, selectedId, _) {
            final dhikr = SalawatStore.selected ?? dhikrs.first;
            return ValueListenableBuilder<Map<int, SalawatCounts>>(
              valueListenable: SalawatStore.counts,
              builder: (context, counts, _) {
                final tally = counts[dhikr.id] ?? SalawatCounts.zero;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      children: [
                        // 1. Modern Dhikr Selector Carousel
                        _DhikrSelector(
                          dhikrs: dhikrs,
                          selectedId: selectedId,
                          counts: counts,
                        ),
                        const SizedBox(height: 20),

                        // 2. Dhikr Card Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? HodaColors.darkBorder
                                  : HodaColors.gold.withOpacity(0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HodaColors.gold.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: HodaColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dhikr.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? HodaColors.goldLight
                                              : HodaColors.forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dhikr.hasDetails)
                                    _DetailsButton(dhikr: dhikr),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ArabicText(
                                dhikr.arabic,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                height: 2.1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 3. Tactile Circular Counter Button
                        _buildCounterButton(theme, tally.today, isDark),
                        const SizedBox(height: 24),

                        // 4. Lifetime Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? HodaColors.darkSurfaceCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? HodaColors.darkBorder
                                        : HodaColors.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'شمارش امروز',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? HodaColors.darkTextMuted
                                            : HodaColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FaNum.number(tally.today),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? HodaColors.turquoiseLight
                                            : HodaColors.forestGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? HodaColors.darkSurfaceCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? HodaColors.darkBorder
                                        : HodaColors.borderSubtle,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'مجموع کل تاریخ',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? HodaColors.darkTextMuted
                                            : HodaColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      FaNum.number(tally.total),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? HodaColors.goldLight
                                            : HodaColors.goldDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 5. Reset Action
                        TextButton.icon(
                          onPressed: _resetTotal,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('صفر کردن شمارنده این ذکر'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCounterButton(ThemeData theme, int today, bool isDark) {
    return GestureDetector(
      onTap: _increment,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) => Transform.scale(
          scale: 1 - _pressController.value,
          child: child,
        ),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF165947),
                      const Color(0xFF0F3E31),
                    ]
                  : [
                      HodaColors.turquoise,
                      HodaColors.forestGreen,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? HodaColors.goldLight : HodaColors.gold,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: HodaColors.forestGreen.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 3,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FaNum.number(today),
                style: const TextStyle(
                  fontFamily: HodaTheme.fontFamily,
                  fontSize: 54,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'برای شمارش لمس کنید',
                  style: TextStyle(
                    fontFamily: HodaTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DhikrSelector extends StatelessWidget {
  final List<Dhikr> dhikrs;
  final int selectedId;
  final Map<int, SalawatCounts> counts;

  const _DhikrSelector({
    required this.dhikrs,
    required this.selectedId,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dhikrs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dhikr = dhikrs[index];
          final selected = dhikr.id == selectedId;
          final today = counts[dhikr.id]?.today ?? 0;

          return ChoiceChip(
            selected: selected,
            onSelected: (_) => SalawatStore.select(dhikr.id),
            label: Text(
              today > 0 ? '${dhikr.title} (${FaNum.number(today)})' : dhikr.title,
              style: TextStyle(
                fontFamily: HodaTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (isDark ? HodaColors.darkBg : Colors.white)
                    : (isDark ? HodaColors.cream : HodaColors.inkGreen),
              ),
            ),
            selectedColor: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
            backgroundColor: isDark ? HodaColors.darkSurfaceCard : Colors.white,
            side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : (isDark ? HodaColors.darkBorder : HodaColors.borderSubtle),
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          );
        },
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  final Dhikr dhikr;

  const _DetailsButton({required this.dhikr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      tooltip: 'فضائل و توضیحات',
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (isDark ? HodaColors.goldLight : HodaColors.goldDark).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
        ),
      ),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _DhikrDetailsSheet(dhikr: dhikr),
      ),
    );
  }
}

class _DhikrDetailsSheet extends StatelessWidget {
  final Dhikr dhikr;

  const _DhikrDetailsSheet({required this.dhikr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget section({
      required IconData icon,
      required String title,
      required List<String> lines,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: isDark ? HodaColors.goldLight : HodaColors.goldDark),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ],
        );

    final benefits = dhikr.benefits
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final sources = dhikr.source
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? HodaColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              dhikr.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? HodaColors.darkSurfaceCard : HodaColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: HodaColors.gold.withOpacity(0.4),
                ),
              ),
              child: ArabicText(
                dhikr.arabic,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 2.1,
              ),
            ),
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 20),
              section(
                icon: Icons.auto_awesome_rounded,
                title: 'فضائل و خاصیت‌ها',
                lines: benefits,
              ),
            ],
            if (dhikr.instruction.isNotEmpty) ...[
              const SizedBox(height: 16),
              section(
                icon: Icons.repeat_rounded,
                title: 'دستور تلاوت',
                lines: [dhikr.instruction],
              ),
            ],
            if (sources.isNotEmpty) ...[
              const SizedBox(height: 16),
              section(
                icon: Icons.menu_book_rounded,
                title: 'منابع و اسناد',
                lines: sources,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SalawatScreen extends StatelessWidget {
  const SalawatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ذکرشمار هُدا')),
      body: const SalawatCounterView(),
    );
  }
}
