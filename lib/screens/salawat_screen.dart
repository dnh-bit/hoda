import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';

/// The salawat (dhikr) counter itself: the Arabic text, the big tap circle, the
/// lifetime total and the reset button.
///
/// Kept separate from [SalawatScreen] so the exact same counter can be used both
/// as the «صلوات» bottom-navigation tab (inside the home shell) and as the
/// full-screen page opened from the AppBar badge.
///
/// The tally lives in [SalawatStore], so every instance — and the AppBar badge —
/// shows the same value and it survives app restarts.
class SalawatCounterView extends StatefulWidget {
  const SalawatCounterView({super.key});

  @override
  State<SalawatCounterView> createState() => _SalawatCounterViewState();
}

class _SalawatCounterViewState extends State<SalawatCounterView>
    with SingleTickerProviderStateMixin {
  static const String salawatText =
      'اللّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَعَجِّلْ فَرَجَهُمْ';

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

  /// Clears the lifetime total (and today's counter with it).
  Future<void> _resetTotal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صفر کردن مجموع صلوات‌ها'),
        content: const Text(
          'مجموع کل صلوات‌های شمرده‌شده و شمارنده امروز صفر می‌شود. '
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

    return ValueListenableBuilder<SalawatCounts>(
      valueListenable: SalawatStore.counts,
      builder: (context, counts, _) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const ArabicText(
                salawatText,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 2.05,
              ),
              const SizedBox(height: 28),
              _buildCounterButton(theme, counts.today),
              const SizedBox(height: 28),
              Text(
                'مجموع کل: ${FaNum.number(counts.total)} صلوات',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.tertiary),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _resetTotal,
                icon: const Icon(Icons.refresh),
                label: const Text('صفر کردن مجموع صلوات‌ها'),
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
      ),
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

/// Full-screen salawat counter page, pushed from the home AppBar badge.
class SalawatScreen extends StatelessWidget {
  const SalawatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ذکر صلوات')),
      body: const SalawatCounterView(),
    );
  }
}
