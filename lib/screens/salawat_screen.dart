import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_helper.dart';
import '../services/salawat_store.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';
import '../widgets/hoda_app_bar.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/info_pill.dart';
import '../widgets/motion.dart';

/// Persisted daily goal for the dhikr counter (0 = «آزاد», no goal).
class _GoalStore {
  _GoalStore._();

  static const String _key = 'hoda_dhikr_goal_v1';
  static const List<int> options = <int>[0, 14, 33, 100, 313, 1000];

  static final ValueNotifier<int> goal = ValueNotifier<int>(100);

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      goal.value = prefs.getInt(_key) ?? 100;
    } catch (_) {
      // Default goal is fine.
    }
    _loaded = true;
  }

  static void setGoal(int value) {
    goal.value = value;
    _persist(value);
  }

  static Future<void> _persist(int value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, value);
    } catch (_) {
      // Best-effort.
    }
  }

  static String label(int value) =>
      value == 0 ? 'آزاد' : FaNum.number(value);
}

/// The dhikr counter: a dhikr picker, the Arabic text, a big progress ring you
/// tap to count, live stats, the daily goal and the sources sheet.
///
/// Kept separate from [SalawatScreen] so the exact same counter can be used both
/// as the «ذکر» destination inside the shell and as the full-screen page opened
/// from the app bar badge. The tallies live in [SalawatStore], so every instance
/// — and the app bar badge — shows the same value and it survives restarts.
class SalawatCounterView extends StatefulWidget {
  const SalawatCounterView({super.key});

  @override
  State<SalawatCounterView> createState() => _SalawatCounterViewState();
}

class _SalawatCounterViewState extends State<SalawatCounterView>
    with TickerProviderStateMixin {
  bool _loading = true;

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0,
    upperBound: 0.045,
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _GoalStore.ensureLoaded();
    await SalawatStore.ensureLoaded();
    await SalawatStore.loadDhikrs(DatabaseHelper.getAllSalawat);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _increment() {
    SalawatStore.increment();

    final int today = SalawatStore.value.today;
    final int goal = _GoalStore.goal.value;
    if (goal > 0 && today == goal) {
      HapticFeedback.heavyImpact();
    } else if (today % 100 == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _press.forward().then((_) => _press.reverse());
    _pulse.forward(from: 0);
  }

  void _decrement() {
    SalawatStore.decrement();
    HapticFeedback.selectionClick();
  }

  /// Clears the selected dhikr's lifetime total (and today's counter with it).
  Future<void> _resetTotal() async {
    final Dhikr? dhikr = SalawatStore.selected;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('صفر کردن شمارنده «${dhikr?.title ?? 'ذکر'}»'),
        content: const Text(
          'مجموع کل شمرده‌شده‌های این ذکر و شمارنده امروزش صفر می‌شود. '
          'این کار قابل بازگشت نیست.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: HodaColors.danger),
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
    _press.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: HodaColors.turquoise),
      );
    }

    return ValueListenableBuilder<List<Dhikr>>(
      valueListenable: SalawatStore.dhikrs,
      builder: (BuildContext context, List<Dhikr> dhikrs, _) {
        if (dhikrs.isEmpty) {
          return const Center(child: Text('ذکری یافت نشد.'));
        }
        return ValueListenableBuilder<int>(
          valueListenable: SalawatStore.selectedId,
          builder: (BuildContext context, int selectedId, __) {
            final Dhikr dhikr = SalawatStore.selected ?? dhikrs.first;
            return ValueListenableBuilder<Map<int, SalawatCounts>>(
              valueListenable: SalawatStore.counts,
              builder: (
                BuildContext context,
                Map<int, SalawatCounts> counts,
                ___,
              ) {
                final SalawatCounts tally =
                    counts[dhikr.id] ?? SalawatCounts.zero;
                return ValueListenableBuilder<int>(
                  valueListenable: _GoalStore.goal,
                  builder: (BuildContext context, int goal, ____) {
                    final int remaining =
                        goal == 0 ? 0 : math.max(0, goal - tally.today);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
                      children: <Widget>[
                        _DhikrSelector(dhikrs: dhikrs, counts: counts),
                        const SizedBox(height: 16),
                        _DhikrHeader(dhikr: dhikr),
                        const SizedBox(height: 12),
                        _ArabicPanel(text: dhikr.arabic),
                        const SizedBox(height: 22),
                        Center(
                          child: _CounterRing(
                            today: tally.today,
                            goal: goal,
                            press: _press,
                            pulse: _pulse,
                            onTap: _increment,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            InfoPill(
                              label: 'اصلاح',
                              icon: Icons.undo_rounded,
                              color: palette.muted,
                              onTap: tally.today == 0 && tally.total == 0
                                  ? null
                                  : _decrement,
                            ),
                            const SizedBox(width: 10),
                            InfoPill(
                              label: goal == 0
                                  ? 'بدون هدف'
                                  : 'باقی‌مانده ${FaNum.number(remaining)}',
                              icon: Icons.flag_outlined,
                              color: HodaColors.turquoise,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatTile(
                                icon: Icons.today_outlined,
                                value: FaNum.number(tally.today),
                                label: 'امروز',
                                color: HodaColors.turquoise,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatTile(
                                icon: Icons.all_inclusive,
                                value: FaNum.number(tally.total),
                                label: 'مجموع کل',
                                color: HodaColors.gold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatTile(
                                icon: Icons.flag_outlined,
                                value: _GoalStore.label(goal),
                                label: 'هدف روزانه',
                                color: HodaColors.clay,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'هدف روزانه',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: palette.muted),
                        ),
                        const SizedBox(height: 8),
                        _GoalChips(goal: goal),
                        const SizedBox(height: 22),
                        OutlinedButton.icon(
                          onPressed: _resetTotal,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('صفر کردن شمارنده این ذکر'),
                        ),
                        const SizedBox(height: 18),
                        const Center(child: OrnamentDivider(width: 130)),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// The dhikr picker: horizontally scrollable cards, each with today's count.
class _DhikrSelector extends StatelessWidget {
  const _DhikrSelector({required this.dhikrs, required this.counts});

  final List<Dhikr> dhikrs;
  final Map<int, SalawatCounts> counts;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return SizedBox(
      height: 70,
      child: ValueListenableBuilder<int>(
        valueListenable: SalawatStore.selectedId,
        builder: (BuildContext context, int selectedId, _) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dhikrs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final Dhikr dhikr = dhikrs[index];
              final bool selected = dhikr.id == selectedId;
              final int today = counts[dhikr.id]?.today ?? 0;
              final Color color = dhikr.kind == 'salawat'
                  ? HodaColors.turquoise
                  : palette.accent;
              return PressableScale(
                onTap: () => SalawatStore.select(dhikr.id),
                child: AnimatedContainer(
                  duration: HodaMotion.fast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient:
                        selected ? palette.tintGradient(color) : null,
                    color: selected ? null : palette.surface,
                    borderRadius: HodaRadius.all(HodaRadius.md),
                    border: Border.all(
                      color: selected
                          ? color.withOpacity(0.55)
                          : palette.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            dhikr.kind == 'salawat'
                                ? Icons.favorite
                                : Icons.spa_outlined,
                            size: 13,
                            color: selected ? color : palette.faint,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              dhikr.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: selected ? color : palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        today > 0
                            ? 'امروز ${FaNum.number(today)} بار'
                            : 'شروع نشده',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.faint,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DhikrHeader extends StatelessWidget {
  const _DhikrHeader({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            dhikr.title,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (dhikr.hasDetails)
          InfoPill(
            label: 'توضیحات و منابع',
            icon: Icons.info_outline,
            color: palette.accent,
            dense: true,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _DhikrDetailsSheet(dhikr: dhikr),
            ),
          ),
      ],
    );
  }
}

class _ArabicPanel extends StatelessWidget {
  const _ArabicPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: palette.card(accentColor: palette.accent),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: palette.accent.withOpacity(0.05),
              tile: 56,
            ),
          ),
          ArabicText(
            text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 2.05,
          ),
        ],
      ),
    );
  }
}

/// The tap target: a gradient disc inside a progress ring, with a pulse that
/// radiates on every count.
class _CounterRing extends StatelessWidget {
  const _CounterRing({
    required this.today,
    required this.goal,
    required this.press,
    required this.pulse,
    required this.onTap,
  });

  final int today;
  final int goal;
  final AnimationController press;
  final AnimationController pulse;
  final VoidCallback onTap;

  static const double _size = 244;

  double get _progress {
    if (goal > 0) {
      final double p = today / goal;
      return p > 1 ? 1 : p;
    }
    // No goal: the ring fills once every hundred, as a rhythm marker.
    return (today % 100) / 100;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final bool done = goal > 0 && today >= goal;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Pulse.
            AnimatedBuilder(
              animation: pulse,
              builder: (BuildContext context, _) {
                final double t = pulse.value;
                if (t == 0) return const SizedBox.shrink();
                return Container(
                  width: _size * (0.78 + t * 0.30),
                  height: _size * (0.78 + t * 0.30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HodaColors.turquoiseLight
                          .withOpacity((1 - t) * 0.55),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            // Progress ring.
            CustomPaint(
              size: const Size(_size, _size),
              painter: _RingPainter(
                progress: _progress,
                track: palette.isDark
                    ? Colors.white.withOpacity(0.07)
                    : HodaColors.forestGreen.withOpacity(0.08),
                start: done ? HodaColors.goldLight : HodaColors.turquoiseLight,
                end: done ? HodaColors.gold : HodaColors.turquoise,
                tickColor: palette.accent.withOpacity(0.45),
              ),
            ),
            // The disc.
            AnimatedBuilder(
              animation: press,
              builder: (BuildContext context, Widget? child) => Transform.scale(
                scale: 1 - press.value,
                child: child,
              ),
              child: Container(
                width: _size * 0.72,
                height: _size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: done
                        ? const <Color>[
                            HodaColors.goldLight,
                            HodaColors.goldDeep,
                          ]
                        : const <Color>[
                            HodaColors.turquoise,
                            HodaColors.forestGreen,
                          ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (done
                              ? HodaColors.gold
                              : HodaColors.turquoise)
                          .withOpacity(0.38),
                      blurRadius: 28,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: PatternLayer(
                        color: Colors.white.withOpacity(0.09),
                        tile: 46,
                        drawGrid: false,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          FaNum.number(today),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal > 0
                              ? 'از ${FaNum.number(goal)}'
                              : 'برای شمارش لمس کنید',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (done) ...<Widget>[
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
    required this.tickColor,
  });

  final double progress;
  final Color track;
  final Color start;
  final Color end;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 12;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final Paint arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: <Color>[start, end, start],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }

    // Twelve subtle ticks, like a tasbih's beads.
    final Paint tick = Paint()
      ..color = tickColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final double a = -math.pi / 2 + i * (2 * math.pi / 12);
      final Offset p = Offset(
        center.dx + (radius + stroke * 0.95) * math.cos(a),
        center.dy + (radius + stroke * 0.95) * math.sin(a),
      );
      canvas.drawCircle(p, 1.6, tick);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.start != start ||
      old.end != end ||
      old.tickColor != tickColor;
}

class _GoalChips extends StatelessWidget {
  const _GoalChips({required this.goal});

  final int goal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final int option in _GoalStore.options)
          PressableScale(
            onTap: () => _GoalStore.setGoal(option),
            child: AnimatedContainer(
              duration: HodaMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: option == goal
                    ? palette.tintGradient(HodaColors.turquoise)
                    : null,
                color: option == goal ? null : palette.surface,
                borderRadius: HodaRadius.all(HodaRadius.pill),
                border: Border.all(
                  color: option == goal
                      ? HodaColors.turquoise.withOpacity(0.55)
                      : palette.border,
                ),
              ),
              child: Text(
                _GoalStore.label(option),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: option == goal ? HodaColors.turquoise : palette.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The «توضیحات و منابع» sheet: benefits (خاصیت), the recitation instruction
/// (دستور) and the sources (منابع) of the chosen dhikr.
class _DhikrDetailsSheet extends StatelessWidget {
  const _DhikrDetailsSheet({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    Widget section({
      required IconData icon,
      required String title,
      required List<String> lines,
    }) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: palette.card(elevated: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 16, color: palette.accent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: palette.accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (String line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accent.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        textAlign: TextAlign.justify,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<String> benefits = dhikr.benefits
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<String> sources = dhikr.source
        .split('•')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) =>
          ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: <Widget>[
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dhikr.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Center(child: OrnamentDivider(width: 120)),
          const SizedBox(height: 16),
          _ArabicPanel(text: dhikr.arabic),
          if (benefits.isNotEmpty)
            section(
              icon: Icons.auto_awesome_outlined,
              title: 'خاصیت و توضیحات',
              lines: benefits,
            ),
          if (dhikr.instruction.isNotEmpty)
            section(
              icon: Icons.repeat,
              title: 'دستور تلاوت',
              lines: <String>[dhikr.instruction],
            ),
          if (sources.isNotEmpty)
            section(
              icon: Icons.menu_book_outlined,
              title: 'منابع',
              lines: sources,
            ),
        ],
      ),
    );
  }
}

/// Full-screen dhikr counter page, pushed from the app bar badge.
class SalawatScreen extends StatelessWidget {
  const SalawatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HodaAppBar(titleText: 'ذکرشمار'),
      body: const HodaBackground(child: SalawatCounterView()),
    );
  }
}
