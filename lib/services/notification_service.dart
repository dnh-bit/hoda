import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_content.dart';
import '../utils/fa_num.dart';
import 'content_repository.dart';

/// A notification payload ready to be handed to the plugin.
class _Message {
  final String title;
  final String body;
  const _Message(this.title, this.body);
}

/// Real notification engine for Hoda.
///
/// Responsibilities:
/// - request the Android 13+ POST_NOTIFICATIONS runtime permission,
/// - schedule a repeating daily notification at the time the user picked,
///   using *exact* alarms when the OS allows it and degrading gracefully to
///   inexact alarms when it does not,
/// - re-arm the schedule on every app start (covers reboot, app update and
///   the case where the OEM battery manager dropped the alarm),
/// - report what is actually armed through [scheduleStatus] so the UI can
///   prove to the user that the notification is set.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _tzReady = false;
  static bool _pluginReady = false;
  static String _zoneName = 'UTC';

  static const String _keyEnabled = 'hoda_notif_enabled';
  static const String _keyHour = 'hoda_notif_hour';
  static const String _keyMinute = 'hoda_notif_minute';
  // verse, hadith, martyr, nahj, random
  static const String _keyType = 'hoda_notif_type';

  static const int _dailyNotificationId = 1001;
  static const int _testNotificationId = 1002;
  static const String _channelId = 'hoda_daily';
  static const String _channelName = 'محتوای روزانه هُدا';
  static const String _channelDescription =
      'آیه، حدیث، حکمت یا وصیت شهید — یک بار در روز';

  static const _Message _fallbackMessage =
      _Message('هُدا 🌿', 'امروز هم همراه تو هستیم 🌿');

  /// Zones tried when resolving the device timezone, ordered by likelihood for
  /// this app's audience. The first one whose *current* UTC offset equals the
  /// device offset wins, so `Asia/Tehran` is used for every Iranian device.
  static const List<String> _candidateZones = <String>[
    'Asia/Tehran', // +03:30
    'Asia/Baghdad', // +03:00
    'Asia/Dubai', // +04:00
    'Asia/Kabul', // +04:30
    'Asia/Karachi', // +05:00
    'Asia/Kolkata', // +05:30
    'Europe/Istanbul', // +03:00
    'Europe/London', // +00:00 / +01:00
    'Europe/Berlin', // +01:00 / +02:00
    'Africa/Cairo', // +02:00 / +03:00
    'Asia/Shanghai', // +08:00
    'Asia/Tokyo', // +09:00
    'America/New_York', // -05:00 / -04:00
    'America/Los_Angeles', // -08:00 / -07:00
    'Australia/Sydney', // +10:00 / +11:00
    'UTC',
  ];

  // ---------------- prefs API ----------------

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    // `%` on ints is euclidean in Dart, so a corrupt negative value still maps
    // into a valid range instead of throwing inside TimeOfDay.
    final h = (prefs.getInt(_keyHour) ?? 8) % 24;
    final m = (prefs.getInt(_keyMinute) ?? 0) % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<String> getType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyType) ?? 'random';
  }

  /// Persists the user's choice and (re)arms or cancels the daily schedule.
  ///
  /// Returns the resulting [scheduleStatus] so callers can show the next fire
  /// time without a second round-trip.
  static Future<Map<String, dynamic>> saveSettings({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
    await prefs.setString(_keyType, type);

    if (!enabled) {
      await _cancelDaily();
      return scheduleStatus();
    }

    final granted = await ensurePermission();
    if (!granted) {
      // The user denied the system permission -> store as disabled so the UI
      // reflects reality instead of promising notifications that cannot show.
      await prefs.setBool(_keyEnabled, false);
      await _cancelDaily();
      return scheduleStatus();
    }

    // Ask for exact alarms once; scheduling still succeeds (inexact) if denied.
    if (!await canScheduleExact()) {
      await requestExactAlarmPermission();
    }

    await _scheduleDaily(time, type);
    return scheduleStatus();
  }

  /// Re-arms the daily notification on app start.
  ///
  /// Needed because AlarmManager alarms are dropped on reboot (the boot
  /// receiver in AndroidManifest.xml restores them, but only for alarms the
  /// plugin still knows about) and because aggressive OEM battery managers
  /// cancel alarms of apps that were force-stopped. Safe to call on every
  /// launch: it cancels and re-creates the same single notification id, and it
  /// also refreshes the body with today's content.
  static Future<void> restoreSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_keyEnabled) ?? false)) return;
      if (!await hasSystemPermission()) {
        // Permission was revoked from system settings; leave the pref alone so
        // the settings screen can explain the situation to the user.
        return;
      }
      await _scheduleDaily(await getTime(), await getType());
    } catch (_) {
      // Never let notification plumbing break app start-up.
    }
  }

  // ---------------- permissions ----------------

  /// Returns true if the notification permission is (now) granted.
  static Future<bool> ensurePermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Whether the OS-level notification permission is currently granted.
  static Future<bool> hasSystemPermission() async {
    return (await Permission.notification.status).isGranted;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Whether the OS currently lets us schedule *exact* alarms.
  ///
  /// Android 12/13: `SCHEDULE_EXACT_ALARM` is granted by default but the user
  /// can revoke it. Android 14+: it must be granted in
  /// «Settings > Apps > Hoda > Alarms & reminders». Non-Android platforms
  /// report true because they do not have the concept.
  static Future<bool> canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system «Alarms & reminders» screen (Android 12+).
  static Future<bool> requestExactAlarmPermission() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's system settings page (used when notifications are denied).
  static Future<void> openSystemSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // Ignore: nothing else we can do from inside the app.
    }
  }

  // ---------------- timezone ----------------

  /// Initialises the timezone database and picks a local location whose
  /// current UTC offset matches the device, so a time the user picked on the
  /// clock fires at that same wall-clock time.
  static void _initTimezones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    final location = _resolveLocalLocation();
    tz.setLocalLocation(location);
    _zoneName = location.name;
    _tzReady = true;
  }

  static tz.Location _resolveLocalLocation() {
    final deviceOffset = DateTime.now().timeZoneOffset;

    // 1) The id the platform reports. Some Android builds return a real IANA id
    //    such as "Asia/Tehran", others an abbreviation like "IRST" (which is
    //    not in the database and simply fails the lookup).
    final reported = _tryLocation(DateTime.now().timeZoneName);
    if (reported != null && _offsetOf(reported) == deviceOffset) {
      return reported;
    }

    // 2) A known zone whose *current* offset matches the device. Matching the
    //    offset (not just the name) keeps the daily repeat on the same
    //    wall-clock time even when the device is not actually in Iran.
    for (final name in _candidateZones) {
      final location = _tryLocation(name);
      if (location != null && _offsetOf(location) == deviceOffset) {
        return location;
      }
    }

    // 3) Last resort: Tehran if present, otherwise UTC. The first fire is still
    //    correct because it is scheduled from an absolute instant (see
    //    [_nextInstanceOf]); only the repeat could drift, and `scheduleStatus`
    //    exposes the resolved zone so the situation is diagnosable.
    return _tryLocation('Asia/Tehran') ?? tz.UTC;
  }

  static tz.Location? _tryLocation(String name) {
    if (name.isEmpty) return null;
    try {
      return tz.getLocation(name);
    } catch (_) {
      return null;
    }
  }

  static Duration _offsetOf(tz.Location location) =>
      tz.TZDateTime.now(location).timeZoneOffset;

  /// Next occurrence of [time] on the *device* wall clock, strictly after now.
  ///
  /// Built with the plain [DateTime] constructor so day/month overflow and DST
  /// shifts normalise the way the user's clock does. `!isAfter` also skips a
  /// candidate equal to now, which AlarmManager treats as already passed.
  static DateTime _nextLocalInstanceOf(TimeOfDay time, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
  }

  /// The same instant expressed in the timezone package's local location.
  ///
  /// [tz.TZDateTime.from] preserves the absolute instant, so the first fire is
  /// correct even if zone resolution had to fall back to a zone with a
  /// different offset; only the daily repeat depends on the zone being right.
  static tz.TZDateTime _nextInstanceOf(TimeOfDay time, {DateTime? from}) {
    return tz.TZDateTime.from(_nextLocalInstanceOf(time, from: from), tz.local);
  }

  // ---------------- plugin plumbing ----------------

  static Future<void> _ensurePlugin() async {
    if (_pluginReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _android?.createNotificationChannel(androidChannel);

    _pluginReady = true;
  }

  static Future<void> _ensureReady() async {
    _initTimezones();
    await _ensurePlugin();
  }

  static NotificationDetails _details(_Message message) {
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      // Without an explicit bigText the expanded notification is empty, which
      // truncated long Arabic passages to a single line.
      styleInformation: BigTextStyleInformation(
        message.body,
        contentTitle: message.title,
      ),
    );
    const ios = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: ios);
  }

  // ---------------- scheduling engine ----------------

  static Future<void> _scheduleDaily(TimeOfDay time, String type) async {
    await _ensureReady();
    await _cancelDaily();

    final scheduled = _nextInstanceOf(time);
    final message = await _message(type);
    final exact = await canScheduleExact();

    try {
      await _zonedSchedule(scheduled, message, type, exact: exact);
    } on PlatformException catch (_) {
      // `exact_alarms_not_permitted` can still be thrown if the permission was
      // revoked between the check and the call. Retry inexact so the user gets
      // *something* rather than nothing.
      if (exact) {
        await _zonedSchedule(scheduled, message, type, exact: false);
      } else {
        rethrow;
      }
    }
  }

  static Future<void> _zonedSchedule(
    tz.TZDateTime scheduled,
    _Message message,
    String type, {
    required bool exact,
  }) {
    return _plugin.zonedSchedule(
      _dailyNotificationId,
      message.title,
      message.body,
      scheduled,
      _details(message),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeats every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: type,
    );
  }

  static Future<void> _cancelDaily() async {
    await _ensurePlugin();
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Immediately show a test notification (used by the settings UI).
  static Future<void> showTestNotification(String type) async {
    await _ensureReady();
    final message = await _message(type);
    await _plugin.show(
      _testNotificationId,
      '${message.title} (تست)',
      message.body,
      _details(message),
      payload: type,
    );
  }

  // ---------------- self check ----------------

  /// Everything the settings screen needs to prove the schedule is armed:
  /// permission state, alarm precision, pending request count, resolved
  /// timezone and the next fire time (also pre-formatted in Persian).
  static Future<Map<String, dynamic>> scheduleStatus() async {
    final enabled = await isEnabled();
    final time = await getTime();
    final type = await getType();

    var notificationsAllowed = false;
    var exactAllowed = false;
    var pendingCount = 0;
    var armed = false;
    String? error;

    try {
      await _ensureReady();
      notificationsAllowed = await hasSystemPermission();
      exactAllowed = await canScheduleExact();
      final pending = await _plugin.pendingNotificationRequests();
      pendingCount = pending.length;
      armed = pending.any((r) => r.id == _dailyNotificationId);
    } catch (e) {
      error = e.toString();
    }

    // Label the next fire on the device's own clock — that is what the user
    // compares against when checking whether the notification is armed.
    final next = armed ? _nextLocalInstanceOf(time) : null;
    final nextLabel = next == null
        ? null
        : '${FaNum.relativeDay(next)} ${FaNum.time(next.hour, next.minute)}';

    return <String, dynamic>{
      'enabled': enabled,
      'armed': armed,
      'pendingCount': pendingCount,
      'notificationsAllowed': notificationsAllowed,
      'exactAllowed': exactAllowed,
      'mode': exactAllowed ? 'exact' : 'inexact',
      'timeZone': _zoneName,
      'type': type,
      'time': FaNum.time(time.hour, time.minute),
      'nextFire': next?.toIso8601String(),
      'nextFireLabel': nextLabel,
      'summaryFa': _summaryFa(
        enabled: enabled,
        armed: armed,
        notificationsAllowed: notificationsAllowed,
        exactAllowed: exactAllowed,
        nextLabel: nextLabel,
        error: error,
      ),
      if (error != null) 'error': error,
    };
  }

  static String _summaryFa({
    required bool enabled,
    required bool armed,
    required bool notificationsAllowed,
    required bool exactAllowed,
    required String? nextLabel,
    required String? error,
  }) {
    if (error != null) {
      return 'بررسی وضعیت اعلان ممکن نشد.';
    }
    if (!enabled) {
      return 'اعلان روزانه خاموش است.';
    }
    if (!notificationsAllowed) {
      return 'اجازه اعلان از سیستم گرفته نشده است.';
    }
    if (!armed || nextLabel == null) {
      return 'اعلان روشن است اما زمان‌بندی ثبت نشده؛ یک بار خاموش و روشنش کنید.';
    }
    final precision = exactAllowed
        ? 'زمان‌بندی دقیق'
        : 'زمان‌بندی تقریبی — ممکن است با کمی تأخیر برسد';
    return 'اعلان بعدی: $nextLabel ($precision)';
  }

  // ---------------- content picking ----------------

  static Future<_Message> _message(String type) async {
    try {
      final content = await ContentRepository.loadDaily();
      final item = _select(content, type);
      if (item == null) return _fallbackMessage;

      final parts = <String>[
        if (item.hasArabic) item.arabic.trim(),
        if (item.hasPersian) item.persian.trim(),
      ];
      if (parts.isEmpty) return _fallbackMessage;

      final body = _clip(parts.join('\n'), 260);
      final title = item.title.trim().isEmpty
          ? 'هُدا 🌿'
          : 'هُدا 🌿 — ${item.title.trim()}';
      return _Message(title, body);
    } catch (_) {
      return _fallbackMessage;
    }
  }

  static DailyContent? _select(HodaContent content, String type) {
    switch (type) {
      case 'verse':
        return content.dailyVerse;
      case 'hadith':
        return content.dailyHadith;
      case 'martyr':
        return content.dailyMartyr;
      case 'nahj':
        return content.dailyNahj;
      default:
        final items = content.dailyItems;
        if (items.isEmpty) return null;
        final now = DateTime.now();
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
        return items[dayOfYear % items.length];
    }
  }

  /// Trims [text] to [max] characters on a word boundary when possible.
  static String _clip(String text, int max) {
    final clean = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (clean.length <= max) return clean;
    final cut = clean.substring(0, max);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > max * 0.6 ? cut.substring(0, lastSpace) : cut}…';
  }
}
