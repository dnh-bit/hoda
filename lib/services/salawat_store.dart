import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable dhikr in the «ذکرشمار» section. Rows come from the
/// `salawat` table (title / arabic / benefits / instruction / source / kind).
@immutable
class Dhikr {
  final int id;
  final String title;
  final String arabic;
  final String benefits;
  final String instruction;
  final String source;

  /// `salawat` for the classic salawat, `dua` for the selected supplications.
  final String kind;

  const Dhikr({
    required this.id,
    required this.title,
    required this.arabic,
    this.benefits = '',
    this.instruction = '',
    this.source = '',
    this.kind = 'dua',
  });

  bool get hasDetails =>
      benefits.trim().isNotEmpty || instruction.trim().isNotEmpty ||
      source.trim().isNotEmpty;
}

/// Counters for the salawat (dhikr) tally, kept per dhikr.
@immutable
class SalawatCounts {
  /// Recited today; resets by itself when the calendar day changes.
  final int today;

  /// Lifetime tally; only the explicit reset clears it.
  final int total;

  const SalawatCounts({required this.today, required this.total});

  static const SalawatCounts zero = SalawatCounts(today: 0, total: 0);

  SalawatCounts incremented() =>
      SalawatCounts(today: today + 1, total: total + 1);

  // Value equality keeps [SalawatStore.counts] from notifying listeners (and
  // rebuilding the AppBar badge) when nothing actually changed.
  @override
  bool operator ==(Object other) =>
      other is SalawatCounts && other.today == today && other.total == total;

  @override
  int get hashCode => Object.hash(today, total);

  @override
  String toString() => 'SalawatCounts(today: $today, total: $total)';
}

/// Loads the dhikr list and persists per-dhikr tallies so counts survive app
/// restarts, and publishes them so several widgets can show the same value.
///
/// Design:
/// - [counts] holds a map of dhikrId → tally. The counter UI and the AppBar
///   badge listen to it; a tap anywhere is visible everywhere at once.
/// - Writes are debounced: tapping the big circle 100 times in a row touches
///   SharedPreferences a handful of times, not 100.
/// - [flush] forces the pending write, and is called when the counter screen is
///   disposed so nothing is lost if the app is killed right after.
/// - Daily counters are stored with a day stamp and read back as 0 once the
///   calendar day changes; lifetime totals are never cleared implicitly.
/// - The classic salawat tally is stored under the well-known legacy keys, so
///   users upgrading keep their existing numbers (dhikr id 1 = صلوات).
class SalawatStore {
  SalawatStore._();

  static const String _keyTotal = 'hoda_salawat_total';
  static const String _keyToday = 'hoda_salawat_today';
  static const String _keyDay = 'hoda_salawat_day';
  static const String _keyPerTotal = 'hoda_dhikr_totals_v2';
  static const String _keyPerToday = 'hoda_dhikr_today_v2';

  static const Duration _persistDelay = Duration(milliseconds: 400);

  /// Live tally per dhikr id, shared by every widget that displays it.
  static final ValueNotifier<Map<int, SalawatCounts>> counts =
      ValueNotifier<Map<int, SalawatCounts>>(<int, SalawatCounts>{});

  /// The dhikr rows, loaded from the bundled database.
  static final ValueNotifier<List<Dhikr>> dhikrs =
      ValueNotifier<List<Dhikr>>(const <Dhikr>[]);

  /// The currently selected dhikr id (defaults to صلوات, id 1).
  static final ValueNotifier<int> selectedId = ValueNotifier<int>(1);

  static bool _loaded = false;
  static Timer? _debounce;

  static SalawatCounts get value =>
      counts.value[selectedId.value] ?? SalawatCounts.zero;

  static String _dayStamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Dhikr? get selected {
    final id = selectedId.value;
    for (final d in dhikrs.value) {
      if (d.id == id) return d;
    }
    return dhikrs.value.isEmpty ? null : dhikrs.value.first;
  }

  /// Reads the persisted tallies into [counts] and returns them.
  static Future<Map<int, SalawatCounts>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stamp = _dayStamp(DateTime.now());
      final savedDay = prefs.getString(_keyDay);
      final bool sameDay = savedDay == stamp;

      final totals = prefs.getStringList(_keyPerTotal) ?? const <String>[];
      final todays = sameDay
          ? (prefs.getStringList(_keyPerToday) ?? const <String>[])
          : const <String>[];

      // Legacy single-salawat tally seeds dhikr id 1 when nothing is stored
      // there yet, so users upgrading keep their existing numbers.
      final int? legacyTotal = prefs.getInt(_keyTotal);
      final int legacyToday = sameDay ? (prefs.getInt(_keyToday) ?? 0) : 0;

      final Map<int, SalawatCounts> map = <int, SalawatCounts>{};
      for (final raw in totals) {
        final parts = raw.split(':');
        if (parts.length != 2) continue;
        final id = int.tryParse(parts[0]);
        final total = int.tryParse(parts[1]);
        if (id == null || total == null) continue;
        final today = int.tryParse(_find(todays, id)) ?? 0;
        map[id] = SalawatCounts(today: today, total: total);
      }
      if (!map.containsKey(1) && legacyTotal != null) {
        map[1] = SalawatCounts(today: legacyToday, total: legacyTotal);
      }

      counts.value = map;
    } catch (_) {
      // Keep whatever is in memory; counting still works for this session.
    }
    _loaded = true;
    return counts.value;
  }

  static String _find(List<String> entries, int id) {
    for (final e in entries) {
      final parts = e.split(':');
      if (parts.length == 2 && int.tryParse(parts[0]) == id) return parts[1];
    }
    return '0';
  }

  /// Loads the dhikr rows from the database into [dhikrs].
  static Future<List<Dhikr>> loadDhikrs(Future<List<Map<String, dynamic>>> Function() query) async {
    try {
      final rows = await query();
      final list = <Dhikr>[];
      for (final row in rows) {
        list.add(Dhikr(
          id: (row['id'] as num?)?.toInt() ?? 0,
          title: (row['title'] as String?)?.trim() ?? '',
          arabic: (row['arabic'] as String?)?.trim() ?? '',
          benefits: (row['benefits'] as String?)?.trim() ?? '',
          instruction: (row['instruction'] as String?)?.trim() ?? '',
          source: (row['source'] as String?)?.trim() ?? '',
          kind: (row['kind'] as String?)?.trim() ?? 'dua',
        ));
      }
      dhikrs.value = list;
      if (!selectedSetByUser && !list.any((d) => d.id == selectedId.value)) {
        selectedId.value = list.isEmpty ? 1 : list.first.id;
      }
    } catch (_) {
      // Leave the list empty; the UI shows a graceful fallback.
    }
    return dhikrs.value;
  }

  /// True once the user picked a dhikr themselves (do not override it later).
  static bool selectedSetByUser = false;

  static void select(int id) {
    selectedSetByUser = true;
    selectedId.value = id;
    _schedulePersist();
  }

  /// [load]s once per process; later calls are cheap.
  static Future<Map<int, SalawatCounts>> ensureLoaded() {
    if (_loaded) return Future<Map<int, SalawatCounts>>.value(counts.value);
    return load();
  }

  /// +1 on both counters of the selected dhikr, published immediately,
  /// persisted shortly after.
  static void increment() {
    final id = selectedId.value;
    final current = counts.value[id] ?? SalawatCounts.zero;
    final next = Map<int, SalawatCounts>.of(counts.value);
    next[id] = current.incremented();
    counts.value = next;
    _schedulePersist();
  }

  /// -1 on both counters of the selected dhikr (never below zero).
  ///
  /// Wired to the «اصلاح» button next to the counter: a mis-tap used to be
  /// permanent, which is a bad thing to do to someone counting a dhikr.
  static void decrement() {
    final id = selectedId.value;
    final current = counts.value[id] ?? SalawatCounts.zero;
    if (current.today == 0 && current.total == 0) return;
    final next = Map<int, SalawatCounts>.of(counts.value);
    next[id] = SalawatCounts(
      today: current.today > 0 ? current.today - 1 : 0,
      total: current.total > 0 ? current.total - 1 : 0,
    );
    counts.value = next;
    _schedulePersist();
  }

  static void _schedulePersist() {
    _debounce?.cancel();
    _debounce = Timer(_persistDelay, () {
      _debounce = null;
      unawaited(save(counts.value));
    });
  }

  /// Writes the current values right away (used when leaving the counter).
  static Future<void> flush() {
    _debounce?.cancel();
    _debounce = null;
    return save(counts.value);
  }

  /// Clears the lifetime total *and* today's counter of the selected dhikr.
  /// Wired to the «صفر کردن مجموع ذکرها» button.
  static Future<void> resetTotal() {
    final id = selectedId.value;
    final next = Map<int, SalawatCounts>.of(counts.value);
    next[id] = SalawatCounts.zero;
    counts.value = next;
    return flush();
  }

  static Future<void> save(Map<int, SalawatCounts> snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totals = <String>[];
      final todays = <String>[];
      snapshot.forEach((id, c) {
        totals.add('$id:${c.total}');
        todays.add('$id:${c.today}');
      });
      await prefs.setStringList(_keyPerTotal, totals);
      await prefs.setStringList(_keyPerToday, todays);
      await prefs.setString(_keyDay, _dayStamp(DateTime.now()));
      // Keep the legacy keys in sync for dhikr 1 so older builds (or a
      // rollback) still show a sane number.
      final one = snapshot[1];
      if (one != null) {
        await prefs.setInt(_keyTotal, one.total);
        await prefs.setInt(_keyToday, one.today);
      }
    } catch (_) {
      // Persistence is best-effort; the in-memory counter still works.
    }
  }
}
