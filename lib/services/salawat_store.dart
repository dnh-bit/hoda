import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counters for the salawat (dhikr) tally.
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

/// Persists the salawat counter so the tally survives app restarts, and
/// publishes it so several widgets can show the same live value.
///
/// Design:
/// - [counts] is the single in-memory source of truth. The home AppBar badge
///   and the full-screen counter both listen to it, so a tap on the counter is
///   visible in the AppBar the moment the user goes back.
/// - Writes are debounced ([_persistDelay]): tapping the big circle 100 times
///   in a row touches SharedPreferences a handful of times, not 100.
/// - [flush] forces the pending write, and is called when the counter screen is
///   disposed so nothing is lost if the app is killed right after.
/// - The daily counter is stored with a day stamp and read back as 0 once the
///   calendar day changes; the lifetime total is never cleared implicitly.
class SalawatStore {
  SalawatStore._();

  static const String _keyTotal = 'hoda_salawat_total';
  static const String _keyToday = 'hoda_salawat_today';
  static const String _keyDay = 'hoda_salawat_day';

  static const Duration _persistDelay = Duration(milliseconds: 400);

  /// Live tally, shared by every widget that displays it.
  static final ValueNotifier<SalawatCounts> counts =
      ValueNotifier<SalawatCounts>(SalawatCounts.zero);

  static bool _loaded = false;
  static Timer? _debounce;

  static SalawatCounts get value => counts.value;

  static String _dayStamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Reads the persisted tally into [counts] and returns it.
  static Future<SalawatCounts> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final total = prefs.getInt(_keyTotal) ?? 0;
      final savedDay = prefs.getString(_keyDay);
      final today = savedDay == _dayStamp(DateTime.now())
          ? (prefs.getInt(_keyToday) ?? 0)
          : 0;
      counts.value = SalawatCounts(today: today, total: total);
    } catch (_) {
      // Keep whatever is in memory; counting still works for this session.
    }
    _loaded = true;
    return counts.value;
  }

  /// [load]s once per process; later calls are cheap.
  static Future<SalawatCounts> ensureLoaded() {
    if (_loaded) return Future<SalawatCounts>.value(counts.value);
    return load();
  }

  /// +1 on both counters, published immediately, persisted shortly after.
  static void increment() {
    counts.value = counts.value.incremented();
    _schedulePersist();
  }

  static void _schedulePersist() {
    _debounce?.cancel();
    _debounce = Timer(_persistDelay, () {
      _debounce = null;
      unawaited(save(counts.value));
    });
  }

  /// Writes the current value right away (used when leaving the counter).
  static Future<void> flush() {
    _debounce?.cancel();
    _debounce = null;
    return save(counts.value);
  }

  /// Clears the lifetime total *and* today's counter.
  /// Wired to the «صفر کردن مجموع صلوات‌ها» button.
  static Future<void> resetTotal() {
    counts.value = SalawatCounts.zero;
    return flush();
  }

  static Future<void> save(SalawatCounts snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotal, snapshot.total);
      await prefs.setInt(_keyToday, snapshot.today);
      await prefs.setString(_keyDay, _dayStamp(DateTime.now()));
    } catch (_) {
      // Persistence is best-effort; the in-memory counter still works.
    }
  }
}
