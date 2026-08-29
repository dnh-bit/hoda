import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_helper.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';

/// The dhikr counter itself: a selector for which dhikr to count, the Arabic
/// text, the big tap circle, per-dhikr lifetime totals and a details sheet
/// («توضیحات و منابع») with the benefits, the recitation instruction and the
/// sources of the chosen dhikr.
///
/// Kept separate from [SalawatScreen] so the exact same counter can be used
/// both as the «صلوات» bottom-navigation tab (inside the home shell) and as
/// the full-screen page opened from the AppBar badge.
///
/// The tallies live in [SalawatStore], so every instance — and the AppBar
/// badge — shows the same value and it survives app restarts.
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
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.06,
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

    if (SalawatStore.value.today % 100 == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _pressController.forward().then((_) => _pressController.reverse());
  }

  /// Clears the selected dhikr's lifetime total (and today's counter with it).
  Future<void> _resetTotal() async {
    final dhikr = SalawatStore.selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('صفر کردن شمارنده «${dhikr?.title ?? 'ذکر'}»'),
        content: const Text(
          'مجموع کل شمرده‌شده‌های این ذکر و شمارنده امروزش صفر می‌شود. '
          'این کار قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
    // Flush the debounced value so nothing is lost when leaving the counter.
    unawaited(SalawatStore.flush());
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _DhikrSelector(
                          dhikrs: dhikrs,
                          selectedId: selectedId,
                          counts: counts,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                dhikr.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (dhikr.hasDetails) ...[
                              const SizedBox(width: 8),
                              _DetailsButton(dhikr: dhikr),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        ArabicText(
                          dhikr.arabic,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 2.05,
                        ),
                        const SizedBox(height: 28),
                        _buildCounterButton(theme, tally.today),
                        const SizedBox(height: 28),
                        Text(
                          'مجموع کل: ${FaNum.number(tally.total)} بار',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.tertiary),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _resetTotal,
                          icon: const Icon(Icons.refresh),
                          label: const Text('صفر کردن شمارنده این ذکر'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: HodaColors.gold),
                            foregroundColor: theme.colorScheme.tertiary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
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

  Widget _buildCounterButton(ThemeData theme, int today) {
    return GestureDetector(
      onTap: _increment,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) => Transform.scale(
          scale: 1 - _pressController.value,
          child: child,
        ),
        child: Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [HodaColors.turquoise, HodaColors.forestGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: HodaColors.gold, width: 3),
            boxShadow: [
              BoxShadow(
                color: HodaColors.turquoise.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FaNum.number(today),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'برای شمارش لمس کنید',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dhikr picker: a horizontally scrollable row of chips, one per dhikr,
/// each showing its title and today's count. Selecting a chip switches the
/// counter, the Arabic text and the totals to that dhikr.
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
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selectedColor: HodaColors.turquoise.withOpacity(0.18),
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: selected ? HodaColors.turquoise : HodaColors.gold.withOpacity(0.5),
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

/// The «توضیحات و منابع» button: opens a modal bottom sheet with the dhikr's
/// benefits (خاصیت), recitation instruction (دستور) and sources (منابع).
class _DetailsButton extends StatelessWidget {
  final Dhikr dhikr;

  const _DetailsButton({required this.dhikr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: 'توضیحات و منابع',
      icon: const Icon(Icons.info_outline, size: 20),
      color: theme.colorScheme.tertiary,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _DhikrDetailsSheet(dhikr: dhikr),
      ),
    );
  }
}

/// The details sheet body: title, Arabic text, benefits, instruction, sources.
class _DhikrDetailsSheet extends StatelessWidget {
  final Dhikr dhikr;

  const _DhikrDetailsSheet({required this.dhikr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Icon(icon, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: theme.textTheme.bodyMedium),
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dhikr.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HodaColors.gold.withOpacity(0.55)),
            ),
            child: ArabicText(
              dhikr.arabic,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 2.0,
            ),
          ),
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 20),
            section(
              icon: Icons.auto_awesome_outlined,
              title: 'خاصیت و توضیحات',
              lines: benefits,
            ),
          ],
          if (dhikr.instruction.isNotEmpty) ...[
            const SizedBox(height: 16),
            section(
              icon: Icons.repeat_outlined,
              title: 'دستور تلاوت',
              lines: [dhikr.instruction],
            ),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            section(
              icon: Icons.menu_book_outlined,
              title: 'منابع',
              lines: sources,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen dhikr counter page, pushed from the home AppBar badge.
class SalawatScreen extends StatelessWidget {
  const SalawatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ذکرشمار')),
      body: const SalawatCounterView(),
    );
  }
}
