import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/theme_controller.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';

/// App version shown at the bottom of this screen. Keep in sync with the
/// `version:` field in pubspec.yaml.
const String kHodaVersionFa = '۰.۰.۷';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 8, minute: 0);
  String _notifType = 'random';
  bool _loading = true;

  /// Last snapshot from [NotificationService.scheduleStatus]; null while the
  /// check is running.
  Map<String, dynamic>? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService.isEnabled();
    final time = await NotificationService.getTime();
    final type = await NotificationService.getType();
    final status = await NotificationService.scheduleStatus();
    if (!mounted) return;
    setState(() {
      _notifEnabled = enabled;
      _notifTime = time;
      _notifType = type;
      _loading = false;
      _applyStatus(status);
    });
  }

  /// Mirrors the service snapshot into the widget state. Must be called from
  /// inside a [setState] callback (or before the first build).
  void _applyStatus(Map<String, dynamic> status) {
    _status = status;
    // The service disables the pref itself when the OS permission was denied,
    // so the switch always reflects reality.
    _notifEnabled = status['enabled'] == true;
  }

  Future<void> _refreshStatus() async {
    setState(() => _status = null);
    final status = await NotificationService.scheduleStatus();
    if (!mounted) return;
    setState(() => _applyStatus(status));
  }

  Future<void> _save({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final status = await NotificationService.saveSettings(
      enabled: enabled,
      time: time,
      type: type,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _applyStatus(status);
    });
  }

  Future<void> _toggleEnabled(bool val) async {
    setState(() => _notifEnabled = val);

    if (val) {
      // Ask for the OS permission first; if denied, revert the switch.
      final granted = await NotificationService.ensurePermission();
      if (!granted) {
        if (!mounted) return;
        setState(() => _notifEnabled = false);
        _snack(
          'اجازه اعلان داده نشد. از تنظیمات سیستم > برنامه‌ها > هُدا > اعلان‌ها می‌توانید فعالش کنید.',
          seconds: 5,
        );
        await _refreshStatus();
        return;
      }
    }

    await _save(enabled: val, time: _notifTime, type: _notifType);
    if (!mounted) return;
    final summary = _status?['summaryFa'] as String?;
    _snack(val
        ? (summary ?? 'اعلان روزانه فعال شد.')
        : 'اعلان‌های روزانه غیرفعال شد.');
  }

  void _snack(String message, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: seconds),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        actions: [
          IconButton(
            tooltip: 'بررسی دوباره وضعیت اعلان',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _refreshStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تنظیمات و اعلان‌ها',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Theme switch
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return SwitchListTile(
              title: const Text('حالت شب'),
              subtitle: Text(isDark ? 'تم تاریک فعال است' : 'تم روشن فعال است'),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.tertiary),
              value: isDark,
              onChanged: (_) {
                ThemeController.toggle();
              },
            );
          },
        ),
        const Divider(height: 32),

        // Notifications section
        Text('تنظیم اعلان‌های روزانه',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: HodaColors.turquoise)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('ارسال اعلان هوشمند'),
          subtitle: Text(_notifEnabled
              ? 'فعال — هر روز ساعت ${FaNum.time(_notifTime.hour, _notifTime.minute)}'
              : 'دریافت آیه، حدیث یا وصیت شهید در طول روز'),
          secondary:
              const Icon(Icons.notifications_active, color: HodaColors.gold),
          value: _notifEnabled,
          onChanged: _busy ? null : _toggleEnabled,
        ),
        const SizedBox(height: 8),

        ListTile(
          title: const Text('ساعت ارسال اعلان'),
          subtitle: Text(FaNum.time(_notifTime.hour, _notifTime.minute)),
          leading: const Icon(Icons.access_time, color: HodaColors.turquoise),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: _busy
              ? null
              : () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _notifTime,
                  );
                  if (picked == null || !mounted) return;
                  setState(() => _notifTime = picked);
                  if (_notifEnabled) {
                    await _save(
                        enabled: true, time: picked, type: _notifType);
                  }
                },
        ),

        ListTile(
          title: const Text('موضوع اعلان'),
          subtitle: Text(_labelForType(_notifType)),
          leading: const Icon(Icons.category, color: HodaColors.gold),
          trailing: DropdownButton<String>(
            value: _notifType,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                  value: 'random', child: Text('تصادفی (پیشنهادی)')),
              DropdownMenuItem(value: 'verse', child: Text('آیه قرآن')),
              DropdownMenuItem(value: 'hadith', child: Text('حدیث معصومین')),
              DropdownMenuItem(value: 'martyr', child: Text('وصیت شهید')),
              DropdownMenuItem(value: 'nahj', child: Text('حکمت نهج‌البلاغه')),
            ],
            onChanged: _busy
                ? null
                : (val) async {
                    if (val == null) return;
                    setState(() => _notifType = val);
                    if (_notifEnabled) {
                      await _save(
                          enabled: true, time: _notifTime, type: val);
                    }
                  },
          ),
        ),

        // Live proof that the schedule is armed.
        if (_notifEnabled) ...[
          const SizedBox(height: 12),
          _buildStatusCard(context),
        ],

        // Test button — shows a notification right now with the selected type.
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _sendTest,
          icon: const Icon(Icons.notifications_none),
          label: const Text('تست اعلان'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: HodaColors.gold),
            foregroundColor: theme.colorScheme.tertiary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: Text('نسخه $kHodaVersionFa - هُدا',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _sendTest() async {
    final granted = await NotificationService.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      _snack('اجازه اعلان از سیستم داده نشد.');
      await _refreshStatus();
      return;
    }
    await NotificationService.showTestNotification(_notifType);
    if (!mounted) return;
    _snack('اعلان تست ارسال شد 🌿');
  }

  // ---------------- schedule status card ----------------

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;

    if (status == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('در حال بررسی وضعیت زمان‌بندی…',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final armed = status['armed'] == true;
    final allowed = status['notificationsAllowed'] == true;
    final exact = status['exactAllowed'] == true;
    final summary = (status['summaryFa'] as String?) ?? '';
    final nextLabel = status['nextFireLabel'] as String?;
    final pending = status['pendingCount'];
    final zone = (status['timeZone'] as String?) ?? '—';
    final hasError = status['error'] != null;

    final accent = !allowed || hasError
        ? Colors.orange
        : armed
            ? HodaColors.turquoise
            : HodaColors.gold;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  armed && allowed
                      ? Icons.alarm_on
                      : Icons.alarm_off_outlined,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'وضعیت زمان‌بندی اعلان',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Persian summary straight from the service.
            Text(summary, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            _statusRow(
              context,
              icon: armed ? Icons.check_circle_outline : Icons.error_outline,
              label: 'ثبت در سیستم',
              value: armed ? 'ثبت شده' : 'ثبت نشده',
            ),
            _statusRow(
              context,
              icon: exact ? Icons.timer_outlined : Icons.timelapse,
              label: 'دقت زمان‌بندی',
              value: exact ? 'دقیق' : 'تقریبی',
            ),
            _statusRow(
              context,
              icon: Icons.schedule,
              label: 'اعلان بعدی',
              value: nextLabel ?? '—',
            ),
            _statusRow(
              context,
              icon: Icons.list_alt,
              label: 'اعلان‌های در نوبت',
              value: pending is int ? FaNum.number(pending) : '—',
            ),
            _statusRow(
              context,
              icon: Icons.public,
              label: 'منطقه زمانی',
              value: zone,
            ),

            // Permission warnings.
            if (!allowed) ...[
              const SizedBox(height: 12),
              _notice(
                context,
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
                text:
                    'اجازه اعلان از سیستم گرفته نشده است. بدون آن هیچ اعلانی نمایش داده نمی‌شود.',
                actionLabel: 'باز کردن تنظیمات برنامه',
                onAction: () async {
                  await NotificationService.openSystemSettings();
                  await _refreshStatus();
                },
              ),
            ],

            // Exact alarms denied -> we fell back to inexact scheduling.
            if (allowed && !exact) ...[
              const SizedBox(height: 12),
              _notice(
                context,
                color: HodaColors.gold,
                icon: Icons.info_outline,
                text:
                    'زمان‌بندی دقیق مجاز نیست، پس اعلان با حالت تقریبی ثبت شده و ممکن است با چند دقیقه تا چند ساعت تأخیر برسد.\n'
                    'برای دقیق شدن: تنظیمات سیستم > برنامه‌ها > هُدا > «هشدارها و یادآورها» (Alarms & reminders) را روشن کنید.',
                actionLabel: 'اجازه هشدار دقیق',
                onAction: () async {
                  await NotificationService.requestExactAlarmPermission();
                  if (!mounted) return;
                  // Re-arm so the new precision is actually applied.
                  await _save(
                      enabled: true, time: _notifTime, type: _notifType);
                },
              ),
            ],

            if (hasError) ...[
              const SizedBox(height: 12),
              _notice(
                context,
                color: Colors.orange,
                icon: Icons.bug_report_outlined,
                text:
                    'بررسی وضعیت با خطا روبه‌رو شد. اگر ادامه داشت، اعلان را خاموش و دوباره روشن کنید.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Text('$label:', style: theme.textTheme.bodySmall),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String text,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    final theme = Theme.of(context);
    // Captured in a local so the callback is non-nullable inside the closure.
    final action = onAction;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
              ),
            ],
          ),
          if (actionLabel != null && action != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : () => action(),
                style: TextButton.styleFrom(foregroundColor: color),
                child: Text(actionLabel),
              ),
            ),
        ],
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'verse':
        return 'آیه قرآن';
      case 'hadith':
        return 'حدیث معصومین';
      case 'martyr':
        return 'وصیت شهید';
      case 'nahj':
        return 'حکمت نهج‌البلاغه';
      default:
        return 'تصادفی (گزیده روز)';
    }
  }
}
