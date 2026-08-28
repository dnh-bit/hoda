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

  /// Last plugin error that was swallowed instead of thrown at the UI.
  /// Exposed through [scheduleStatus] for diagnostics only — never fatal.
  static String? _lastPluginError;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<TimeOfDay> getTime() async {
    const fallback = TimeOfDay(hour: 8, minute: 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      // `%` on ints is euclidean in Dart, so a corrupt negative value still
      // maps into a valid range instead of throwing inside TimeOfDay.
      final h = (prefs.getInt(_keyHour) ?? 8) % 24;
      final m = (prefs.getInt(_keyMinute) ?? 0) % 60;
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return fallback;
    }
  }

  static Future<String> getType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyType) ?? 'random';
    } catch (_) {
      return 'random';
    }
  }

  /// Persists the user's choice and (re)arms or cancels the daily schedule.
  ///
  /// Returns the resulting [scheduleStatus] so callers can show the next fire
  /// time without a second round-trip. Never throws: every plugin call is
  /// guarded, so a broken notification cache can only degrade the returned
  /// status, never crash the settings screen.
  static Future<Map<String, dynamic>> saveSettings({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    await _writePrefs(enabled: enabled, time: time, type: type);

    if (!enabled) {
      await _cancelDaily();
      return scheduleStatus();
    }

    final granted = await ensurePermission();
    if (!granted) {
      // The user denied the system permission -> store as disabled so the UI
      // reflects reality instead of promising notifications that cannot show.
      await _writePrefs(enabled: false, time: time, type: type);
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

  /// Best-effort write of the notification prefs.
  static Future<void> _writePrefs({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, enabled);
      await prefs.setInt(_keyHour, time.hour);
      await prefs.setInt(_keyMinute, time.minute);
      await prefs.setString(_keyType, type);
    } catch (error) {
      _lastPluginError = 'writePrefs → $error';
      debugPrint('NotificationService: saving prefs failed → $error');
    }
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
  /// Never throws: a platform-channel hiccup is reported as «not granted».
  static Future<bool> ensurePermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (error) {
      _lastPluginError = 'ensurePermission → $error';
      debugPrint('NotificationService: permission check failed → $error');
      return false;
    }
  }

  /// Whether the OS-level notification permission is currently granted.
  static Future<bool> hasSystemPermission() async {
    try {
      return (await Permission.notification.status).isGranted;
    } catch (error) {
      _lastPluginError = 'hasSystemPermission → $error';
      return false;
    }
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

  /// Runs a plugin call that must never crash the UI.
  ///
  /// flutter_local_notifications keeps its queue of scheduled notifications as
  /// JSON in its own SharedPreferences file and reads it back through Gson.
  /// When that queue cannot be deserialized — the R8 «Missing type parameter.»
  /// failure addressed by android/app/proguard-rules.pro, or a queue written by
  /// an older/minified build — even `cancel()` throws a PlatformException from
  /// deep inside `loadScheduledNotifications`. Cancelling an alarm that may not
  /// exist is never worth a crash, so the failure is recorded and swallowed.
  ///
  /// Returns true when [body] completed without throwing.
  static Future<bool> _guard(
    String action,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      return true;
    } on PlatformException catch (error) {
      // The interesting part of a plugin failure is code + message; the Java
      // stack trace in `details` is noise for our purposes.
      _lastPluginError = '$action → ${error.code}: ${error.message}';
      debugPrint('NotificationService: $action failed → '
          '${error.code}: ${error.message}');
      return false;
    } catch (error) {
      _lastPluginError = '$action → $error';
      debugPrint('NotificationService: $action failed → $error');
      return false;
    }
  }

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

  /// Initialises the timezone database and the plugin. Never throws: a failure
  /// here (missing tz data, plugin channel error) must not take the UI down.
  static Future<bool> _ensureReady() {
    return _guard('ensureReady', () async {
      _initTimezones();
      await _ensurePlugin();
    });
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

  /// Arms the daily notification. Returns true when the plugin accepted the
  /// schedule. Never throws — the settings UI keeps working either way.
  static Future<bool> _scheduleDaily(TimeOfDay time, String type) async {
    await _ensureReady();
    await _cancelDaily();

    final tz.TZDateTime scheduled;
    try {
      scheduled = _nextInstanceOf(time);
    } catch (error) {
      // Only possible if timezone initialisation failed above.
      _lastPluginError = 'nextInstanceOf → $error';
      debugPrint('NotificationService: cannot resolve fire time → $error');
      return false;
    }

    final message = await _message(type);
    final exact = await canScheduleExact();

    if (await _guard('zonedSchedule(exact: $exact)',
        () => _zonedSchedule(scheduled, message, type, exact: exact))) {
      // A successful arm proves the plugin cache is healthy again, so an older
      // swallowed error should no longer be reported by [scheduleStatus].
      _lastPluginError = null;
      return true;
    }

    // `exact_alarms_not_permitted` can still be thrown if the permission was
    // revoked between the check and the call, and a corrupted plugin cache can
    // make the first attempt fail for unrelated reasons. Wipe the queue and
    // retry inexact so the user gets *something* rather than nothing.
    if (!exact) return false;
    await _guard('cancelAll(before retry)', _plugin.cancelAll);
    return _guard('zonedSchedule(exact: false)',
        () => _zonedSchedule(scheduled, message, type, exact: false));
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

  /// Cancels the daily notification.
  ///
  /// Every step is guarded: `cancel(id)` goes through the plugin's Gson-backed
  /// cache, so on a build whose keep rules are missing (or with a queue left
  /// behind by such a build) it throws «Missing type parameter.». Cancelling
  /// something that is not scheduled must never surface to the UI, hence the
  /// swallow-and-continue behaviour plus the `cancelAll()` fallback.
  static Future<void> _cancelDaily() async {
    if (!await _guard('ensurePlugin(cancel)', _ensurePlugin)) return;

    if (await _guard(
      'cancel($_dailyNotificationId)',
      () => _plugin.cancel(_dailyNotificationId),
    )) {
      return;
    }

    // Fallback: drop the whole queue. Hoda only ever schedules one repeating
    // notification, so nothing of value is lost, and this also clears a cache
    // that the per-id path could not read.
    await _guard('cancelAll', _plugin.cancelAll);
  }

  /// Immediately show a test notification (used by the settings UI).
  /// Returns false when the plugin refused, so the UI can say so instead of
  /// claiming success.
  static Future<bool> showTestNotification(String type) async {
    await _ensureReady();
    final message = await _message(type);
    return _guard(
      'show(test)',
      () => _plugin.show(
        _testNotificationId,
        '${message.title} (تست)',
        message.body,
        _details(message),
        payload: type,
      ),
    );
  }

  // ---------------- self check ----------------

  /// Everything the settings screen needs to prove the schedule is armed:
  /// permission state, alarm precision, pending request count, resolved
  /// timezone and the next fire time (also pre-formatted in Persian).
  ///
  /// Fully defensive: reading the pending queue is the exact call that fails on
  /// a minified build without the Gson keep rules, so it is isolated from the
  /// permission checks and a failure only degrades the report.
  static Future<Map<String, dynamic>> scheduleStatus() async {
    final enabled = await isEnabled();
    final time = await getTime();
    final type = await getType();

    var notificationsAllowed = false;
    var exactAllowed = false;
    var pendingCount = 0;
    var armed = false;
    var queueReadable = true;
    String? error;

    try {
      await _ensureReady();
      notificationsAllowed = await hasSystemPermission();
      exactAllowed = await canScheduleExact();
    } catch (e) {
      error = e.toString();
    }

    // Isolated on purpose: `pendingNotificationRequests()` deserializes the
    // plugin's cache and can throw where nothing else does.
    try {
      final pending = await _plugin.pendingNotificationRequests();
      pendingCount = pending.length;
      armed = pending.any((r) => r.id == _dailyNotificationId);
    } catch (e) {
      queueReadable = false;
      _lastPluginError = 'pendingNotificationRequests → $e';
      debugPrint('NotificationService: cannot read pending queue → $e');
    }

    // When the queue is unreadable we cannot prove the alarm is armed, but the
    // pref says it should be — show the expected fire time rather than a scary
    // «not registered», and let the summary explain the uncertainty.
    final assumeArmed =
        armed || (enabled && notificationsAllowed && !queueReadable);

    // Label the next fire on the device's own clock — that is what the user
    // compares against when checking whether the notification is armed.
    final next = assumeArmed ? _nextLocalInstanceOf(time) : null;
    final nextLabel = next == null
        ? null
        : '${FaNum.relativeDay(next)} ${FaNum.time(next.hour, next.minute)}';

    return <String, dynamic>{
      'enabled': enabled,
      'armed': armed,
      'queueReadable': queueReadable,
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
        queueReadable: queueReadable,
        notificationsAllowed: notificationsAllowed,
        exactAllowed: exactAllowed,
        nextLabel: nextLabel,
        error: error,
      ),
      if (error != null) 'error': error,
      if (_lastPluginError != null) 'pluginError': _lastPluginError,
    };
  }

  static String _summaryFa({
    required bool enabled,
    required bool armed,
    required bool queueReadable,
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
    final precision = exactAllowed
        ? 'زمان‌بندی دقیق'
        : 'زمان‌بندی تقریبی — ممکن است با کمی تأخیر برسد';
    if (!queueReadable) {
      return 'اعلان روشن است؛ فهرست زمان‌بندی‌های سیستم خوانده نشد، '
          'اما اعلان بعدی روی ${nextLabel ?? '—'} تنظیم است ($precision).';
    }
    if (!armed || nextLabel == null) {
      return 'اعلان روشن است اما زمان‌بندی ثبت نشده؛ یک بار خاموش و روشنش کنید.';
    }
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
