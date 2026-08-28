import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';

/// Salawat (dhikr) counter with haptic feedback and persisted tally.
class SalawatScreen extends StatefulWidget {
  const SalawatScreen({super.key});

  @override
  State<SalawatScreen> createState() => _SalawatScreenState();
}

class _SalawatScreenState extends State<SalawatScreen>
    with SingleTickerProviderStateMixin {
  static const String salawatText =
      'اللّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَعَجِّلْ فَرَجَهُمْ';

  SalawatCounts _counts = SalawatCounts.zero;
  bool _loading = true;
  Timer? _saveTimer;

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
    final counts = await SalawatStore.load();
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _loading = false;
    });
  }

  void _schedulePersist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 400),
      () => SalawatStore.save(_counts),
    );
  }

  void _increment() {
    setState(() => _counts = _counts.incremented());

    if (_counts.today % 100 == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _pressController.forward().then((_) => _pressController.reverse());
    _schedulePersist();
  }

  Future<void> _resetToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صفر کردن شمارنده'),
        content: const Text(
            'شمارنده امروز صفر می‌شود. مجموع کل صلوات‌های شما حفظ خواهد شد.'),
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
    setState(() => _counts = _counts.withTodayReset());
    await SalawatStore.save(_counts);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Flush the latest value so nothing is lost when leaving the screen.
    SalawatStore.save(_counts);
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ذکر صلوات')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: HodaColors.turquoise))
          : SingleChildScrollView(
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
                    _buildCounterButton(theme),
                    const SizedBox(height: 28),
                    Text(
                      'مجموع کل: ${FaNum.number(_counts.total)} صلوات',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.tertiary),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _resetToday,
                      icon: const Icon(Icons.refresh),
                      label: const Text('صفر کردن شمارنده امروز'),
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
            ),
    );
  }

  Widget _buildCounterButton(ThemeData theme) {
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
                FaNum.number(_counts.today),
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
