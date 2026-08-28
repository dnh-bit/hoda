import 'package:shared_preferences/shared_preferences.dart';

/// Counters for the salawat (dhikr) tally.
class SalawatCounts {
  final int today;
  final int total;

  const SalawatCounts({required this.today, required this.total});

  static const SalawatCounts zero = SalawatCounts(today: 0, total: 0);

  SalawatCounts incremented() =>
      SalawatCounts(today: today + 1, total: total + 1);

  SalawatCounts withTodayReset() => SalawatCounts(today: 0, total: total);
}

/// Persists the salawat counter so the tally survives app restarts.
/// The daily counter resets automatically when the calendar day changes.
class SalawatStore {
  SalawatStore._();

  static const String _keyTotal = 'hoda_salawat_total';
  static const String _keyToday = 'hoda_salawat_today';
  static const String _keyDay = 'hoda_salawat_day';

  static String _dayStamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<SalawatCounts> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final total = prefs.getInt(_keyTotal) ?? 0;
      final savedDay = prefs.getString(_keyDay);
      final today = savedDay == _dayStamp(DateTime.now())
          ? (prefs.getInt(_keyToday) ?? 0)
          : 0;
      return SalawatCounts(today: today, total: total);
    } catch (_) {
      return SalawatCounts.zero;
    }
  }

  static Future<void> save(SalawatCounts counts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotal, counts.total);
      await prefs.setInt(_keyToday, counts.today);
      await prefs.setString(_keyDay, _dayStamp(DateTime.now()));
    } catch (_) {
      // Persistence is best-effort; the in-memory counter still works.
    }
  }
}
