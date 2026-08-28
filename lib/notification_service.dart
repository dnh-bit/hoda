import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'database_helper.dart';

/// Real notification engine for Hoda:
/// - requests Android 13+ POST_NOTIFICATIONS permission on first enable
/// - schedules daily local notifications at the chosen time
/// - picks content type: verse / hadith / martyr / nahj / random
class NotificationService {
  NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _tzReady = false;

  static const String _keyEnabled = 'hoda_notif_enabled';
  static const String _keyHour = 'hoda_notif_hour';
  static const String _keyMinute = 'hoda_notif_minute';
  static const String _keyType = 'hoda_notif_type'; // verse, hadith, martyr, nahj, random
  static const int _dailyNotificationId = 1001;
  static const String _channelId = 'hoda_daily';
  static const String _channelName = 'محتوای روزانه هُدا';

  // ---------------- prefs API (kept for compatibility) ----------------

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_keyHour) ?? 8;
    final m = prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<String> getType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyType) ?? 'random';
  }

  static Future<void> saveSettings({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
    await prefs.setString(_keyType, type);

    if (enabled) {
      final granted = await ensurePermission();
      if (!granted) {
        // user denied system permission -> store as disabled so UI reflects reality
        await prefs.setBool(_keyEnabled, false);
        await _cancelDaily();
        return;
      }
      await _scheduleDaily(time, type);
    } else {
      await _cancelDaily();
    }
  }

  /// Returns true if system permission is (now) granted.
  static Future<bool> ensurePermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Whether the OS-level permission is currently granted (for UI status display).
  static Future<bool> hasSystemPermission() async {
    return (await Permission.notification.status).isGranted;
  }

  // ---------------- scheduling engine ----------------

  static void _initTimezones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    } catch (_) {
      // fallback: UTC
      tz.setLocalLocation(tz.UTC);
    }
    _tzReady = true;
  }

  static Future<void> _ensurePlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  static Future<void> _scheduleDaily(TimeOfDay time, String type) async {
    _initTimezones();
    await _ensurePlugin();
    await _cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = await _pickBody(type);
    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'هُدا 🌿',
      body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: type,
    );
  }

  static Future<void> _cancelDaily() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Immediately show a test notification (used by settings UI).
  static Future<void> showTestNotification(String type) async {
    _initTimezones();
    await _ensurePlugin();
    final body = await _pickBody(type);
    await _plugin.show(_dailyNotificationId + 1, 'هُدا 🌿 (تست)', body,
        _details());
  }

  // ---------------- content picking ----------------

  static Future<String> _pickBody(String type) async {
    try {
      // Deferred import to avoid a circular dependency with database_helper.
      final content = await _fetchContent(type);
      return content;
    } catch (_) {
      return 'امروز هم همراه تو هستیم 🌿';
    }
  }

  static Future<String> _fetchContent(String type) async {
    // Uses the same daily-rotation logic as the app home page.
    final db = await DatabaseHelper.database;
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    Future<String?> pick(
        String table, String Function(Map<String, dynamic>) fmt) async {
      final rows = await db.query(table);
      if (rows.isEmpty) return null;
      return fmt(rows[dayOfYear % rows.length]);
    }

    switch (type) {
      case 'verse':
        final s = await pick('verses', (r) =>
            '${r['arabic']}\n${r['farsi']}\n${r['ref']}');
        return s ?? 'آیه امروز آماده نیست';
      case 'hadith':
        final s = await pick('hadiths', (r) =>
            '${r['arabic']}\n${r['farsi']}');
        return s ?? 'حدیث امروز آماده نیست';
      case 'martyr':
        final s = await pick('martyrs', (r) {
          final t = (r['excerpt'] ?? '').toString();
          return '${r['name']}\n${t.length > 120 ? t.substring(0, 120) : t}...';
        });
        return s ?? 'وصیت امروز آماده نیست';
      case 'nahj':
        final s = await pick('nahj_wisdoms', (r) =>
            '${r['arabic']}\n${r['farsi']}');
        return s ?? 'حکمت امروز آماده نیست';
      default:
        // random across all four
        final all = <String>[];
        final v = await pick('verses', (r) =>
            '${r['arabic']}\n${r['farsi']}');
        if (v != null) all.add(v);
        final h = await pick('hadiths', (r) =>
            '${r['arabic']}\n${r['farsi']}');
        if (h != null) all.add(h);
        final m = await pick('martyrs', (r) {
          final t = (r['excerpt'] ?? '').toString();
          return '${r['name']}\n${t.length > 120 ? t.substring(0, 120) : t}...';
        });
        if (m != null) all.add(m);
        final n = await pick('nahj_wisdoms', (r) =>
            '${r['arabic']}\n${r['farsi']}');
        if (n != null) all.add(n);
        if (all.isEmpty) return 'امروز هم همراه تو هستیم 🌿';
        return all[dayOfYear % all.length];
    }
  }
}
