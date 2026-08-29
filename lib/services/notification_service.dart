import 'dart:async';
import 'dart:typed_data' show Int64List;
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_content.dart';
import '../models/notification_schedule.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import 'content_repository.dart';

/// Entry point for taps that arrive while the Flutter engine is not running.
///
/// This runs in a *separate* isolate, so the UI's [ValueNotifier] is
/// unreachable from here: the payload is parked in SharedPreferences and the
/// next app start replays it through
/// [NotificationService.handleAppLaunchTap].
@pragma('vm:entry-point')
void hodaNotificationBackgroundTap(NotificationResponse response) {
  try {
    // The background isolate starts without plugin registrations, so
    // SharedPreferences would otherwise throw a MissingPluginException.
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {
    // Older embedders register plugins themselves; nothing to do.
  }
  unawaited(NotificationService.recordBackgroundTap(response.payload));
}

/// A notification payload ready to be handed to the plugin.
///
/// - [title] is the *raw* Persian title without bidi wrappers, so callers can
///   still append a suffix («(تست)») before wrapping it.
/// - [displayTitle] is [title] wrapped in the RTL embedding pair; it is what
///   the plugin receives as the collapsed title (and what iOS shows).
/// - [body] is the plain-text version used for the collapsed line (and iOS),
///   with every line wrapped individually (a `\n` ends a bidi paragraph, so one
///   wrapper around the whole block would not survive the line break).
/// - [htmlBody] / [htmlTitle] are the HTML-formatted versions handed to
///   [BigTextStyleInformation] with the `htmlFormat*` flags on.
/// - [ticker] is the short Persian line Android speaks/shows as the heads-up
///   ticker; wrapped as well so it does not flip to LTR.
/// - [resolvedType] is the concrete content type that ended up in the
///   notification — it is what the payload carries, so a tap can open the
///   matching tab even for a `random` schedule.
/// - [uid] identifies the concrete content row (`<table>:<id>`), so a tap can
///   open that exact card. Null when the item could not be identified.
class _Message {
  final String title;
  final String displayTitle;
  final String body;
  final String htmlTitle;
  final String htmlBody;
  final String ticker;
  final String resolvedType;
  final String? uid;

  const _Message({
    required this.title,
    required this.displayTitle,
    required this.body,
    required this.htmlTitle,
    required this.htmlBody,
    required this.ticker,
    required this.resolvedType,
    this.uid,
  });
}

/// Real notification engine for Hoda.
///
/// Responsibilities:
/// - request the Android 13+ POST_NOTIFICATIONS runtime permission,
/// - keep a user-managed list of up to [NotificationSchedule.maxCount] daily
///   notifications, persisted as JSON, and arm each one as its own plugin
///   notification (`id = NotificationSchedule.notificationId`) so they can be
///   cancelled and re-armed individually,
/// - use *exact* alarms when the OS allows it and degrade gracefully to
///   inexact alarms when it does not,
/// - re-arm every enabled schedule on app start (covers reboot, app update and
///   the case where the OEM battery manager dropped the alarms),
/// - render branded, right-to-left, HTML-styled notifications,
/// - route a notification tap to the tab that matches its content type,
/// - report what is actually armed through [scheduleStatus] so the UI can
///   prove to the user that the notifications are set.
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

  // ---------------- preference keys ----------------

  /// JSON array of [NotificationSchedule]s.
  static const String _keySchedules = 'hoda_notif_schedules_v2';

  /// Global on/off switch that gates every schedule.
  static const String _keyMaster = 'hoda_notif_master_v2';

  /// Payload of a tap that happened while the UI isolate was dead.
  static const String _keyPendingTap = 'hoda_notif_pending_tap';

  // Legacy single-schedule keys, read once by [_migrateLegacy].
  static const String _legacyKeyEnabled = 'hoda_notif_enabled';
  static const String _legacyKeyHour = 'hoda_notif_hour';
  static const String _legacyKeyMinute = 'hoda_notif_minute';
  static const String _legacyKeyType = 'hoda_notif_type';

  // ---------------- notification ids ----------------

  /// Scheduled ids live in 1000..1004 (see [NotificationSchedule]).
  /// These two ranges are kept outside of it so [cancelAllHoda] cannot wipe
  /// them and they cannot collide with a schedule.
  static const int _testNotificationId = 1100;
  static const int _previewBaseId = 1200;

  // ---------------- channels ----------------

  /// High-importance channel carrying the actual daily content.
  static const String _dailyChannelId = 'hoda_daily';
  static const String _dailyChannelName = 'محتوای معنوی';
  static const String _dailyChannelDescription =
      'آیه، حدیث، حکمت یا وصیت شهید — طبق زمان‌بندی‌های شما';

  /// Low-importance channel for previews and the test notification, so the user
  /// can silence them from the system settings without losing the daily
  /// content.
  static const String _reminderChannelId = 'hoda_reminders';
  static const String _reminderChannelName = 'یادآوری‌ها';
  static const String _reminderChannelDescription =
      'پیش‌نمایش و اعلان آزمایشی — بی‌صدا';

  /// Shown by Android under the expanded notification.
  static const String _summaryTextFa = 'هُدا • محتوای معنوی امروز';

  /// App name in the notification header. Plain text (Android does not parse
  /// HTML in `subText`), so the bidi pair is applied literally here.
  static const String _subTextFa = '$_rtlOpen$_appNameFa$_rtlClose';

  /// The app name, reused by titles and [_subTextFa].
  static const String _appNameFa = 'هُدا';

  /// Gentle two-pulse vibration: wait, buzz, pause, buzz (milliseconds).
  /// `Int64List` is what the plugin expects for `vibrationPattern`.
  static final Int64List _vibrationPattern =
      Int64List.fromList(<int>[0, 220, 160, 220]);

  /// Groups Hoda notifications so several of them stack instead of flooding
  /// the shade.
  static const String _groupKey = 'ir.hoda.daily';

  /// Right-to-left embedding + pop, so Android lays the text out RTL even when
  /// the device locale is left-to-right.
  ///
  /// ## How Hoda guarantees RTL notifications — do not strip this
  ///
  /// A notification is rendered by the *system* UI (SystemUI), which lays text
  /// out according to the **device** locale, not the app's. On a phone set to
  /// English, Persian/Arabic text is therefore treated as a neutral run inside
  /// an LTR paragraph: the line starts on the left, and trailing punctuation
  /// («…», «؟», «•», parentheses, digits) jumps to the wrong side.
  ///
  /// The fix is the Unicode Bidirectional Algorithm's *embedding* pair:
  /// `U+202B RIGHT-TO-LEFT EMBEDDING` … `U+202C POP DIRECTIONAL FORMATTING`
  /// ([_rtlOpen] / [_rtlClose], applied by [_rtl]). Everything between them is
  /// laid out RTL regardless of the surrounding paragraph direction.
  ///
  /// Three rules follow from the algorithm and are implemented in [_message]:
  /// 1. **Every segment gets its own pair.** A bidi embedding does not survive
  ///    a paragraph break, so a `\n`-separated plain body must wrap each line
  ///    separately; in the HTML body each `<br>`-separated segment is wrapped
  ///    too.
  /// 2. **The control characters sit inside the HTML tags**
  ///    (`<b>\u202B…\u202C</b>`), not around them. `Html.fromHtml` only parses
  ///    markup — the controls are ordinary characters to it, so keeping them
  ///    inside the tag makes them part of the styled span itself and they
  ///    cannot be lost if the markup is stripped by an OEM ROM.
  /// 3. **All four visible slots are wrapped**: title / contentTitle, each body
  ///    line, [_summaryTextFa] and the heads-up [ticker]. Anything left
  ///    unwrapped is the one line the user will see flipped.
  ///
  /// What the user sees: a turquoise-accented card titled «هُدا 🌿 — عنوان»,
  /// with the bold Arabic passage on the first line, its Persian translation
  /// under it, the source in italics, «هُدا • محتوای معنوی امروز» as the
  /// expanded summary — all right-aligned and reading right-to-left even on an
  /// English phone.
  static const String _rtlOpen = '\u202B';
  static const String _rtlClose = '\u202C';

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

  // ---------------- tap routing ----------------

  /// Emits the content type of the notification the user tapped
  /// (`verse` / `hadith` / `martyr` / `nahj`, or `random` when the concrete type
  /// could not be resolved). The app shell listens to this and switches tab.
  ///
  /// The value is reset to null before every emission so that tapping two
  /// notifications of the *same* type still notifies listeners twice.
  static final ValueNotifier<String?> onNotificationTap =
      ValueNotifier<String?>(null);

  /// Emits the [DailyContent.uid] of the item the tapped notification was
  /// showing (`verses:17`, `martyrs:3`, …), or nothing when the payload carries
  /// no identity (a notification armed by an older version, or a fallback
  /// message). The shell uses it to push the exact content card after it
  /// switched tab.
  ///
  /// Reset to null before every emission, exactly like [onNotificationTap], so
  /// tapping the same notification twice notifies listeners twice.
  static final ValueNotifier<String?> onNotificationOpen =
      ValueNotifier<String?>(null);

  /// Payload wire format: `requestedType|resolvedType[|uid]`.
  ///
  /// The requested type is kept for diagnostics (a `random` schedule stays
  /// recognisable), the resolved type drives tab routing and the optional third
  /// segment identifies the concrete row so the tap can open that very card.
  ///
  /// The third segment is *optional on purpose*: notifications armed by 0.0.9
  /// (two segments) are still in the plugin's queue after an update and must
  /// keep routing to their tab — see [typeFromPayload] / [uidFromPayload].
  static String _payloadFor(
    String requestedType,
    String resolvedType, [
    String? uid,
  ]) {
    final base = '$requestedType|$resolvedType';
    if (uid == null || uid.trim().isEmpty) return base;
    // `|` is the field separator, so it can never appear inside a uid.
    return '$base|${uid.trim().replaceAll('|', '/')}';
  }

  /// Content type a payload should navigate to, or null when there is nothing
  /// to route (empty payload).
  static String? typeFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final parts = payload.split('|');
    // Prefer the resolved type (last type-looking segment); fall back to the
    // requested one. Scanning instead of indexing keeps both the legacy
    // two-segment format and the new three-segment one working.
    for (final part in parts.reversed) {
      final candidate = part.trim();
      if (candidate.isEmpty) continue;
      if (NotificationSchedule.types.contains(candidate)) return candidate;
    }
    // Unknown payload: let the UI decide (it maps anything unknown to home).
    return 'random';
  }

  /// Content uid carried by a payload, or null for the legacy two-segment
  /// format (and for fallback messages, which have no concrete row).
  static String? uidFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final parts = payload.split('|');
    if (parts.length < 3) return null;
    final uid = parts[2].trim();
    return uid.isEmpty ? null : uid;
  }

  static void _emitTap(String? payload) {
    final type = typeFromPayload(payload);
    if (type == null) return;
    onNotificationTap.value = null;
    onNotificationTap.value = type;
    // Emitted *after* the type so the shell has already switched tab by the
    // time it starts resolving the uid.
    final uid = uidFromPayload(payload);
    onNotificationOpen.value = null;
    if (uid != null) onNotificationOpen.value = uid;
  }

  /// Foreground / warm-start tap handler.
  static void _onForegroundTap(NotificationResponse response) {
    _emitTap(response.payload);
  }

  /// Called from the background isolate (see [hodaNotificationBackgroundTap]).
  /// Public only because a top-level entry point cannot reach private members.
  static Future<void> recordBackgroundTap(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingTap, payload);
    } catch (_) {
      // Nothing else we can do from a background isolate.
    }
  }

  /// Replays a tap that started the app (cold start) or that was parked by the
  /// background isolate. Call once from the app bootstrap, after the first
  /// frame, so the shell is already listening.
  static Future<void> handleAppLaunchTap() async {
    await _guard('handleAppLaunchTap', () async {
      await _ensureReady();
      String? payload;
      try {
        final details = await _plugin.getNotificationAppLaunchDetails();
        if (details?.didNotificationLaunchApp == true) {
          payload = details?.notificationResponse?.payload;
        }
      } catch (error) {
        _lastPluginError = 'launchDetails → $error';
      }

      // A parked background tap wins only when the cold start itself did not
      // carry a payload (the launch details are the fresher signal).
      payload ??= await _takePendingTap();
      if (payload != null) _emitTap(payload);
    });
  }

  static Future<String?> _takePendingTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyPendingTap);
      if (raw == null) return null;
      await prefs.remove(_keyPendingTap);
      return raw;
    } catch (_) {
      return null;
    }
  }

  // ---------------- persistence ----------------

  /// The persisted schedules, sorted by fire time. Never throws: a corrupt
  /// value yields the default list.
  static Future<List<NotificationSchedule>> schedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySchedules);
      if (raw == null) {
        final migrated = await _migrateLegacy(prefs);
        return NotificationSchedule.sorted(migrated);
      }
      return NotificationSchedule.sorted(NotificationSchedule.decodeList(raw));
    } catch (error) {
      _lastPluginError = 'readSchedules → $error';
      return const <NotificationSchedule>[];
    }
  }

  /// Global switch. Every schedule is gated by it.
  static Future<bool> isMasterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_keySchedules)) {
        // First run after the upgrade: the legacy pref decides.
        await _migrateLegacy(prefs);
      }
      return prefs.getBool(_keyMaster) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Converts the 0.0.8 single-schedule prefs
  /// (`hoda_notif_enabled/hour/minute/type`) into one schedule with id 0 and
  /// writes the v2 keys. Returns the resulting list.
  ///
  /// Runs at most once: after it, `_keySchedules` exists.
  static Future<List<NotificationSchedule>> _migrateLegacy(
    SharedPreferences prefs,
  ) async {
    final hadLegacy = prefs.containsKey(_legacyKeyEnabled) ||
        prefs.containsKey(_legacyKeyHour) ||
        prefs.containsKey(_legacyKeyMinute) ||
        prefs.containsKey(_legacyKeyType);

    final enabled = prefs.getBool(_legacyKeyEnabled) ?? false;
    final schedule = NotificationSchedule(
      id: 0,
      enabled: hadLegacy ? enabled : true,
      hour: (prefs.getInt(_legacyKeyHour) ?? 8) % 24,
      minute: (prefs.getInt(_legacyKeyMinute) ?? 0) % 60,
      type: NotificationSchedule.normalizeType(
        prefs.getString(_legacyKeyType),
      ),
    );
    final list = <NotificationSchedule>[schedule];

    try {
      await prefs.setString(
        _keySchedules,
        NotificationSchedule.encodeList(list),
      );
      // A user who had the daily notification on keeps it on; a fresh install
      // starts with the master switch off and one ready-made 08:00 schedule.
      await prefs.setBool(_keyMaster, hadLegacy && enabled);
      for (final key in <String>[
        _legacyKeyEnabled,
        _legacyKeyHour,
        _legacyKeyMinute,
        _legacyKeyType,
      ]) {
        await prefs.remove(key);
      }
    } catch (error) {
      _lastPluginError = 'migrateLegacy → $error';
      debugPrint('NotificationService: legacy migration failed → $error');
    }
    return list;
  }

  static Future<void> _writeSchedules(
    List<NotificationSchedule> list,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keySchedules,
        NotificationSchedule.encodeList(list),
      );
    } catch (error) {
      _lastPluginError = 'writeSchedules → $error';
      debugPrint('NotificationService: saving schedules failed → $error');
    }
  }

  static Future<void> _writeMaster(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMaster, enabled);
    } catch (error) {
      _lastPluginError = 'writeMaster → $error';
      debugPrint('NotificationService: saving master switch failed → $error');
    }
  }

  // ---------------- public mutations ----------------

  /// Turns every schedule on/off at once. Returns the fresh [scheduleStatus].
  ///
  /// When enabling, the OS permission is requested first; a denial is written
  /// back as «off» so the UI never promises notifications that cannot show.
  static Future<Map<String, dynamic>> setMasterEnabled(bool enabled) async {
    if (!enabled) {
      await _writeMaster(false);
      await cancelAllHoda();
      return scheduleStatus();
    }

    final granted = await ensurePermission();
    if (!granted) {
      await _writeMaster(false);
      await cancelAllHoda();
      return scheduleStatus();
    }

    await _writeMaster(true);
    return scheduleAll(interactive: true);
  }

  /// Adds or replaces the schedule with [schedule]'s id and re-arms.
  static Future<Map<String, dynamic>> upsert(
    NotificationSchedule schedule,
  ) async {
    final list = List<NotificationSchedule>.of(await schedules());
    final index = list.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      list[index] = schedule;
    } else if (list.length < NotificationSchedule.maxCount) {
      list.add(schedule);
    } else {
      // Full list: nothing to do, the UI blocks this case already.
      return scheduleStatus();
    }
    await _writeSchedules(NotificationSchedule.sorted(list));
    return scheduleAll(interactive: true);
  }

  /// Drops the schedule with [id], cancelling its alarm first.
  static Future<Map<String, dynamic>> remove(int id) async {
    final list = List<NotificationSchedule>.of(await schedules())
      ..removeWhere((s) => s.id == id);
    await _writeSchedules(NotificationSchedule.sorted(list));
    await _guard(
      'cancel(${NotificationSchedule.baseNotificationId + id})',
      () => _plugin.cancel(NotificationSchedule.baseNotificationId + id),
    );
    return scheduleAll();
  }

  /// Cancels every Hoda schedule and re-arms the enabled ones.
  ///
  /// [interactive] is true when the call comes from a user action, in which
  /// case a missing exact-alarm permission is requested (that opens a system
  /// screen, so it must never happen during a silent boot re-arm).
  static Future<Map<String, dynamic>> scheduleAll({
    bool interactive = false,
  }) async {
    await _ensureReady();
    await cancelAllHoda();

    final master = await isMasterEnabled();
    final list = await schedules();
    final enabled = list.where((s) => s.enabled).toList();
    if (!master || enabled.isEmpty) return scheduleStatus();

    if (!await hasSystemPermission()) return scheduleStatus();

    if (interactive && !await canScheduleExact()) {
      await requestExactAlarmPermission();
    }
    final exact = await canScheduleExact();

    for (final schedule in enabled) {
      await _armSchedule(schedule, exact: exact);
    }
    return scheduleStatus();
  }

  /// Cancels the five schedule slots (1000..1004).
  ///
  /// Every step is guarded: `cancel(id)` goes through the plugin's Gson-backed
  /// cache, so on a build whose keep rules are missing (or with a queue left
  /// behind by such a build) it throws «Missing type parameter.». If any id
  /// fails, the whole queue is dropped — that also repairs a cache the per-id
  /// path could not read, and it runs *before* arming so nothing armed in this
  /// pass is lost.
  static Future<void> cancelAllHoda() async {
    if (!await _guard('ensurePlugin(cancel)', _ensurePlugin)) return;

    var allOk = true;
    for (var id = 0; id < NotificationSchedule.maxCount; id++) {
      final pluginId = NotificationSchedule.baseNotificationId + id;
      final ok = await _guard(
        'cancel($pluginId)',
        () => _plugin.cancel(pluginId),
      );
      allOk = allOk && ok;
    }
    if (!allOk) await _guard('cancelAll', _plugin.cancelAll);
  }

  /// Re-arms every enabled schedule on app start.
  ///
  /// Needed because AlarmManager alarms are dropped on reboot (the boot
  /// receiver in AndroidManifest.xml restores them, but only for alarms the
  /// plugin still knows about) and because aggressive OEM battery managers
  /// cancel alarms of apps that were force-stopped. Safe to call on every
  /// launch: it re-creates the same notification ids and refreshes each body
  /// with today's content.
  static Future<void> restoreSchedule() async {
    try {
      if (!await isMasterEnabled()) return;
      if (!await hasSystemPermission()) {
        // Permission was revoked from system settings; leave the prefs alone so
        // the settings screen can explain the situation to the user.
        return;
      }
      await scheduleAll();
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
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      // Tap while the engine is alive (foreground or warm start).
      onDidReceiveNotificationResponse: _onForegroundTap,
      // Tap while the engine is dead: handled in a background isolate.
      onDidReceiveBackgroundNotificationResponse: hodaNotificationBackgroundTap,
    );

    const dailyChannel = AndroidNotificationChannel(
      _dailyChannelId,
      _dailyChannelName,
      description: _dailyChannelDescription,
      importance: Importance.high,
      showBadge: true,
      enableLights: true,
      enableVibration: true,
      ledColor: HodaColors.turquoise,
    );
    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      _reminderChannelName,
      description: _reminderChannelDescription,
      importance: Importance.low,
      showBadge: false,
      enableVibration: false,
    );
    await _android?.createNotificationChannel(dailyChannel);
    await _android?.createNotificationChannel(reminderChannel);

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

  // ---------------- styling ----------------

  /// The ONE branded, RTL, HTML-formatted notification style builder.
  ///
  /// Every path that shows something — [_zonedSchedule] (the armed daily
  /// schedules), [showTestNotification] and [showPreview] — goes through here,
  /// so the user cannot get a plain-looking notification from one of them.
  ///
  /// The plugin renders `bigText`, `contentTitle` and `summaryText` through
  /// Android's `Html.fromHtml` when the matching `htmlFormat*` flag is set, so
  /// the body can be laid out like a small card:
  ///
  /// ```
  /// <b>ARABIC</b><br>persian translation<br><i>source</i>
  /// ```
  ///
  /// HTML also means the text must be escaped (see [_escapeHtml]) and that
  /// `<br>` is the line break. Layout direction is forced with RTL embedding
  /// control characters — see the doc on [_rtlOpen] for the full mechanism and
  /// why every single segment carries its own pair.
  ///
  /// [reminder] switches to the low-importance «یادآوری‌ها» channel used by the
  /// preview and test notifications. [titleSuffix] is appended to both the
  /// collapsed title and the expanded `contentTitle` («(تست)»), inside the bidi
  /// wrapper so the suffix cannot flip the line.
  static NotificationDetails _details(
    _Message message, {
    bool reminder = false,
    String? titleSuffix,
  }) {
    final htmlTitle = titleSuffix == null || titleSuffix.trim().isEmpty
        ? message.htmlTitle
        : _htmlTitle('${message.title} ${titleSuffix.trim()}');

    final android = AndroidNotificationDetails(
      reminder ? _reminderChannelId : _dailyChannelId,
      reminder ? _reminderChannelName : _dailyChannelName,
      channelDescription:
          reminder ? _reminderChannelDescription : _dailyChannelDescription,
      importance: reminder ? Importance.low : Importance.high,
      priority: reminder ? Priority.low : Priority.high,
      // Without an explicit bigText the expanded notification is empty, which
      // truncated long Arabic passages to a single line.
      styleInformation: BigTextStyleInformation(
        message.htmlBody,
        htmlFormatBigText: true,
        contentTitle: htmlTitle,
        htmlFormatContentTitle: true,
        summaryText: _htmlSegment(_summaryTextFa),
        htmlFormatSummaryText: true,
      ),
      // App name in the notification header.
      subText: _subTextFa,
      // Heads-up / accessibility line: Persian and RTL-wrapped, otherwise this
      // is the one place that still reads left-to-right.
      ticker: message.ticker,
      // Branding: turquoise accent + matching LED pulse.
      color: HodaColors.turquoise,
      ledColor: HodaColors.turquoise,
      // Short pulse, long pause: a calm heartbeat rather than a blinking alarm.
      ledOnMs: 400,
      ledOffMs: 800,
      enableLights: !reminder,
      enableVibration: !reminder,
      vibrationPattern: reminder ? null : _vibrationPattern,
      playSound: !reminder,
      channelShowBadge: !reminder,
      // Never hijack the whole screen — this is gentle spiritual content.
      fullScreenIntent: false,
      autoCancel: true,
      showWhen: true,
      // The «alarm-ish» family that survives Do-Not-Disturb reminder
      // allowances, without claiming to be an actual alarm.
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      // Several Hoda notifications collapse into one group in the shade.
      groupKey: _groupKey,
      setAsGroupSummary: false,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  /// Minimal HTML escaping for text handed to `Html.fromHtml`.
  static String _escapeHtml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _rtl(String input) => '$_rtlOpen$input$_rtlClose';

  /// Escapes [text], wraps it in the RTL embedding pair and puts the result
  /// *inside* [tag] (`b`, `i`, … or none), which is where the bidi controls
  /// belong — see the doc on [_rtlOpen].
  static String _htmlSegment(String text, {String tag = ''}) {
    final inner = _rtl(_escapeHtml(text));
    return tag.isEmpty ? inner : '<$tag>$inner</$tag>';
  }

  /// Bold, escaped, RTL-wrapped title for `contentTitle`.
  static String _htmlTitle(String plainTitle) =>
      _htmlSegment(plainTitle, tag: 'b');

  // ---------------- scheduling engine ----------------

  /// Arms one schedule. Returns true when the plugin accepted it.
  /// Never throws — the settings UI keeps working either way.
  ///
  /// The body and the payload are built **once, here at arm time** by
  /// [_message]: `matchDateTimeComponents: DateTimeComponents.time` makes the
  /// OS re-post that same, already-rendered notification every day, so the
  /// text the user reads and the `uid` in the payload always describe the same
  /// item — tapping it can therefore open exactly that card.
  ///
  /// Limitation worth knowing: because the content is frozen at arm time, a
  /// schedule that is never re-armed keeps showing the item picked back then.
  /// [restoreSchedule] re-arms everything on each app start, which is what
  /// refreshes the content in practice; a device that goes days without opening
  /// the app repeats yesterday's item (and its uid) — consistent, just not new.
  static Future<bool> _armSchedule(
    NotificationSchedule schedule, {
    required bool exact,
  }) async {
    final tz.TZDateTime when;
    try {
      when = _nextInstanceOf(schedule.time);
    } catch (error) {
      // Only possible if timezone initialisation failed above.
      _lastPluginError = 'nextInstanceOf → $error';
      debugPrint('NotificationService: cannot resolve fire time → $error');
      return false;
    }

    final message = await _message(schedule.type, variant: schedule.id);

    if (await _guard(
      'zonedSchedule(#${schedule.id}, exact: $exact)',
      () => _zonedSchedule(schedule, when, message, exact: exact),
    )) {
      // A successful arm proves the plugin cache is healthy again, so an older
      // swallowed error should no longer be reported by [scheduleStatus].
      _lastPluginError = null;
      return true;
    }

    // `exact_alarms_not_permitted` can still be thrown if the permission was
    // revoked between the check and the call. Retry inexact so the user gets
    // *something* rather than nothing. (The queue-repair `cancelAll` lives in
    // [cancelAllHoda], which already ran before this pass — retrying it here
    // would wipe the sibling schedules armed a moment ago.)
    if (!exact) return false;
    return _guard(
      'zonedSchedule(#${schedule.id}, exact: false)',
      () => _zonedSchedule(schedule, when, message, exact: false),
    );
  }

  static Future<void> _zonedSchedule(
    NotificationSchedule schedule,
    tz.TZDateTime when,
    _Message message, {
    required bool exact,
  }) {
    return _plugin.zonedSchedule(
      schedule.notificationId,
      message.displayTitle,
      message.body,
      when,
      _details(message),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeats every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payloadFor(schedule.type, message.resolvedType, message.uid),
    );
  }

  /// Immediately shows a test notification (used by the settings UI).
  /// Returns false when the plugin refused, so the UI can say so instead of
  /// claiming success. Uses the same styled path as the scheduled ones.
  static Future<bool> showTestNotification(String type) async {
    await _ensureReady();
    final message = await _message(type);
    const suffix = '(تست)';
    return _guard(
      'show(test)',
      () => _plugin.show(
        _testNotificationId,
        _rtl('${message.title} $suffix'),
        message.body,
        _details(message, titleSuffix: suffix),
        payload: _payloadFor(type, message.resolvedType, message.uid),
      ),
    );
  }

  /// Instant sample of what [schedule] will look like, on the low-importance
  /// «یادآوری‌ها» channel so a burst of previews cannot become annoying.
  static Future<bool> showPreview(NotificationSchedule schedule) async {
    await _ensureReady();
    final message = await _message(schedule.type, variant: schedule.id);
    final suffix = '(پیش‌نمایش ${schedule.timeLabelFa})';
    return _guard(
      'show(preview #${schedule.id})',
      () => _plugin.show(
        _previewBaseId + schedule.id,
        _rtl('${message.title} $suffix'),
        message.body,
        _details(message, reminder: true, titleSuffix: suffix),
        payload: _payloadFor(
          schedule.type,
          message.resolvedType,
          message.uid,
        ),
      ),
    );
  }

  // ---------------- self check ----------------

  /// Everything the settings screen needs to prove the schedules are armed:
  /// permission state, alarm precision, pending request count, resolved
  /// timezone and, per schedule, whether it is registered and when it fires
  /// next (pre-formatted in Persian).
  ///
  /// Fully defensive: reading the pending queue is the exact call that fails on
  /// a minified build without the Gson keep rules, so it is isolated from the
  /// permission checks and a failure only degrades the report.
  static Future<Map<String, dynamic>> scheduleStatus() async {
    final master = await isMasterEnabled();
    final list = await schedules();
    final enabledList = list.where((s) => s.enabled).toList();

    var notificationsAllowed = false;
    var exactAllowed = false;
    var pendingCount = 0;
    var queueReadable = true;
    final armedIds = <int>{};
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
      armedIds.addAll(pending.map((r) => r.id));
    } catch (e) {
      queueReadable = false;
      _lastPluginError = 'pendingNotificationRequests → $e';
      debugPrint('NotificationService: cannot read pending queue → $e');
    }

    // When the queue is unreadable we cannot prove the alarms are armed, but
    // the prefs say they should be — show the expected fire times rather than a
    // scary «not registered», and let the summary explain the uncertainty.
    final assumeArmed = master && notificationsAllowed && !queueReadable;

    final now = DateTime.now();
    DateTime? soonest;
    var armedCount = 0;
    final scheduleReports = <Map<String, dynamic>>[];

    for (final schedule in list) {
      final armed = armedIds.contains(schedule.notificationId);
      final active = master && schedule.enabled && (armed || assumeArmed);
      if (active) armedCount++;
      final next =
          active ? _nextLocalInstanceOf(schedule.time, from: now) : null;
      if (next != null && (soonest == null || next.isBefore(soonest))) {
        soonest = next;
      }
      scheduleReports.add(<String, dynamic>{
        'id': schedule.id,
        'enabled': schedule.enabled,
        'armed': armed,
        'active': active,
        'type': schedule.type,
        'typeLabelFa': schedule.typeLabelFa,
        'time': schedule.timeLabelFa,
        'nextFire': next?.toIso8601String(),
        'nextFireLabel': next == null ? null : _fireLabel(next),
      });
    }

    return <String, dynamic>{
      'masterEnabled': master,
      // Kept for callers that only care whether anything is going to fire.
      'enabled': master && enabledList.isNotEmpty,
      'scheduleCount': list.length,
      'enabledCount': enabledList.length,
      'armedCount': armedCount,
      'armed': armedCount > 0,
      'queueReadable': queueReadable,
      'pendingCount': pendingCount,
      'notificationsAllowed': notificationsAllowed,
      'exactAllowed': exactAllowed,
      'mode': exactAllowed ? 'exact' : 'inexact',
      'timeZone': _zoneName,
      'schedules': scheduleReports,
      'nextFire': soonest?.toIso8601String(),
      'nextFireLabel': soonest == null ? null : _fireLabel(soonest),
      'summaryFa': _summaryFa(
        master: master,
        enabledCount: enabledList.length,
        armedCount: armedCount,
        queueReadable: queueReadable,
        notificationsAllowed: notificationsAllowed,
        exactAllowed: exactAllowed,
        nextLabel: soonest == null ? null : _fireLabel(soonest),
        error: error,
      ),
      if (error != null) 'error': error,
      if (_lastPluginError != null) 'pluginError': _lastPluginError,
    };
  }

  /// «فردا ۰۸:۰۰» — labelled on the device's own clock, which is what the user
  /// compares against when checking whether a notification is armed.
  static String _fireLabel(DateTime when) =>
      '${FaNum.relativeDay(when)} ${FaNum.time(when.hour, when.minute)}';

  static String _summaryFa({
    required bool master,
    required int enabledCount,
    required int armedCount,
    required bool queueReadable,
    required bool notificationsAllowed,
    required bool exactAllowed,
    required String? nextLabel,
    required String? error,
  }) {
    if (error != null) {
      return 'بررسی وضعیت اعلان ممکن نشد.';
    }
    if (!master) {
      return 'اعلان‌های روزانه خاموش است.';
    }
    if (enabledCount == 0) {
      return 'هیچ اعلان فعالی تنظیم نشده است؛ یک اعلان جدید بسازید.';
    }
    if (!notificationsAllowed) {
      return 'اجازه اعلان از سیستم گرفته نشده است.';
    }
    final precision = exactAllowed
        ? 'زمان‌بندی دقیق'
        : 'زمان‌بندی تقریبی — ممکن است با کمی تأخیر برسد';
    final countLabel = '${FaNum.number(enabledCount)} اعلان فعال';
    if (!queueReadable) {
      return '$countLabel؛ فهرست زمان‌بندی‌های سیستم خوانده نشد، '
          'اما اعلان بعدی روی ${nextLabel ?? '—'} تنظیم است ($precision).';
    }
    if (armedCount == 0 || nextLabel == null) {
      return 'اعلان‌ها روشن‌اند اما در سیستم ثبت نشده؛ '
          'یک بار کلید اصلی را خاموش و روشن کنید.';
    }
    return 'اعلان بعدی: $nextLabel • $countLabel ($precision)';
  }

  // ---------------- content picking ----------------

  /// Shown when the database has nothing usable. Kept const, so the bidi
  /// wrappers are spelled out through const interpolation instead of [_rtl].
  static const String _fallbackTitleFa = '$_appNameFa 🌿';
  static const String _fallbackBodyFa = 'امروز هم همراه تو هستیم 🌿';

  static const _Message _fallbackMessage = _Message(
    title: _fallbackTitleFa,
    displayTitle: '$_rtlOpen$_fallbackTitleFa$_rtlClose',
    body: '$_rtlOpen$_fallbackBodyFa$_rtlClose',
    htmlTitle: '<b>$_rtlOpen$_fallbackTitleFa$_rtlClose</b>',
    htmlBody: '$_rtlOpen$_fallbackBodyFa$_rtlClose',
    ticker: '$_rtlOpen$_fallbackTitleFa$_rtlClose',
    resolvedType: 'random',
  );

  /// Builds the notification text for [requestedType].
  ///
  /// [variant] shifts the `random` rotation so five «تصادفی» schedules on the
  /// same day pick five different items instead of repeating one.
  ///
  /// The result carries the picked item's [DailyContent.uid] so the payload can
  /// point a tap at that exact card; see [_armSchedule] for why the pick made
  /// here stays the one the user eventually reads.
  static Future<_Message> _message(String requestedType,
      {int variant = 0}) async {
    try {
      final content = await ContentRepository.loadDaily();
      final picked = _select(content, requestedType, variant: variant);
      if (picked == null) return _fallbackMessage;

      final item = picked.value;
      // Notification texts prefer the dedicated short excerpt (martyr wills
      // carry one in `notif_excerpt`); the full text stays behind the tap.
      final bodyText =
          (item.notifPersian?.trim().isNotEmpty ?? false)
              ? item.notifPersian!.trim()
              : item.persian.trim();
      final arabic = item.hasArabic ? _clip(item.arabic.trim(), 200) : '';
      final persian = bodyText.isNotEmpty ? _clip(bodyText, 240) : '';
      if (arabic.isEmpty && persian.isEmpty) return _fallbackMessage;
      // Third line of the card: «بقره ۲۵۵», «الکافی», the martyr's name…
      final source = item.hasSource ? _clip(item.source.trim(), 90) : '';

      final plainTitle = item.title.trim().isEmpty
          ? _fallbackTitleFa
          : '$_appNameFa 🌿 — ${item.title.trim()}';

      // Heads-up ticker label: the item's own title, or the type's short
      // Persian label when the row has none.
      final tickerLabel = item.title.trim().isEmpty
          ? NotificationSchedule.shortLabelForType(picked.key)
          : item.title.trim();

      // Plain body for the collapsed line and for iOS. Each line is wrapped on
      // its own: `\n` ends a bidi paragraph, which would drop a single wrapper
      // spanning the whole block.
      final plainLines = <String>[arabic, persian, source]
          .where((e) => e.isNotEmpty)
          .map(_rtl)
          .toList();

      // HTML body, laid out like a card:
      //   <b>arabic</b><br>persian<br><i>source</i>
      // Every segment carries its own bidi pair *inside* its tag; the whole
      // block is wrapped once more so the paragraph itself starts RTL even on a
      // ROM that strips the markup.
      final htmlParts = <String>[
        if (arabic.isNotEmpty) _htmlSegment(arabic, tag: 'b'),
        if (persian.isNotEmpty) _htmlSegment(persian),
        if (source.isNotEmpty) _htmlSegment(source, tag: 'i'),
      ];

      return _Message(
        title: plainTitle,
        displayTitle: _rtl(plainTitle),
        body: plainLines.join('\n'),
        htmlTitle: _htmlTitle(plainTitle),
        htmlBody: _rtl(htmlParts.join('<br>')),
        // Heads-up ticker: short enough to be read at a glance, and RTL.
        ticker: _rtl('$_appNameFa • $tickerLabel'),
        resolvedType: picked.key,
        uid: item.uid,
      );
    } catch (_) {
      return _fallbackMessage;
    }
  }

  /// Today's item for [type], paired with the concrete type it belongs to.
  ///
  /// For `random` the pair's key is the type that was actually chosen, which is
  /// what ends up in the payload and therefore drives tab routing.
  static MapEntry<String, DailyContent>? _select(
    HodaContent content,
    String type, {
    int variant = 0,
  }) {
    final typed = _typedDailyItems(content);
    final normalized = NotificationSchedule.normalizeType(type);
    if (normalized != 'random') {
      for (final entry in typed) {
        if (entry.key == normalized) return entry;
      }
      return null;
    }
    if (typed.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return typed[(dayOfYear + variant) % typed.length];
  }

  /// Today's items in a fixed order, each tagged with its content type.
  static List<MapEntry<String, DailyContent>> _typedDailyItems(
    HodaContent content,
  ) {
    final result = <MapEntry<String, DailyContent>>[];
    void add(String type, DailyContent? item) {
      if (item != null) result.add(MapEntry(type, item));
    }

    add('verse', content.dailyVerse);
    add('hadith', content.dailyHadith);
    add('martyr', content.dailyMartyr);
    add('nahj', content.dailyNahj);
    return result;
  }

  /// Trims [text] to [max] characters on a word boundary when possible.
  static String _clip(String text, int max) {
    final clean = text.replaceAll(RegExp(r'\s*\n{2,}\s*'), '\n').trim();
    if (clean.length <= max) return clean;
    final cut = clean.substring(0, max);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > max * 0.6 ? cut.substring(0, lastSpace) : cut}…';
  }
}
