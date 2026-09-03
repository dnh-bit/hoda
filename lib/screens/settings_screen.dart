import 'package:flutter/material.dart';

import '../models/notification_schedule.dart';
import '../services/notification_service.dart';
import '../services/theme_controller.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';

/// App version shown at the bottom of this screen. Keep in sync with the
/// `version:` field in pubspec.yaml (currently 0.1.6).
const String kHodaVersionFa = '۰.۱.۶ بتا';

/// Settings: theme, and the multi-schedule notification manager (up to five
/// daily notifications, each with its own time and content type).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _busy = false;

  bool _master = false;
  List<NotificationSchedule> _schedules = const <NotificationSchedule>[];
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final master = await NotificationService.isMasterEnabled();
    final schedules = await NotificationService.schedules();
    final status = await NotificationService.scheduleStatus();
    if (!mounted) return;
    setState(() {
      _master = master;
      _schedules = schedules;
      _status = status;
      _loading = false;
    });
  }

  Future<void> _apply(Future<Map<String, dynamic>> action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await action;
      if (!mounted) return;
      setState(() {
        _status = status;
        _master = status['masterEnabled'] == true;
      });
      // Reload the local list so sort order/cap always mirrors the store.
      final schedules = await NotificationService.schedules();
      if (!mounted) return;
      setState(() => _schedules = schedules);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _capReached => _schedules.length >= NotificationSchedule.maxCount;

  /// Two ENABLED schedules sharing the same wall-clock minute is almost
  /// always a mistake — surface it before the user wonders why two notes
  /// arrive together.
  String? get _duplicateWarning {
    final seen = <int, NotificationSchedule>{};
    for (final s in _schedules) {
      if (!s.enabled) continue;
      final previous = seen[s.minutesOfDay];
      if (previous != null) {
        return 'دو اعلان فعال روی ساعت ${s.timeLabelFa} تنظیم شده است.';
      }
      seen[s.minutesOfDay] = s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(theme, Icons.notifications_active_outlined,
              'اعلان‌های روزانه'),
          _MasterSwitch(
            master: _master,
            busy: _busy,
            status: _status,
            onChanged: (v) => _apply(NotificationService.setMasterEnabled(v)),
          ),
          if (!_master) ...[
            const SizedBox(height: 8),
            Text(
              'برای مدیریت اعلان‌ها، ابتدا کلید اصلی را روشن کنید.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.tertiary),
            ),
          ],
          if (_duplicateWarning != null) ...[
            const SizedBox(height: 8),
            _WarningBanner(message: _duplicateWarning!),
          ],
          const SizedBox(height: 12),
          ..._schedules.map(_buildScheduleCard),
          if (!_capReached)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _addSchedule,
                icon: const Icon(Icons.add_alarm),
                label: const Text('افزودن اعلان جدید'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'حداکثر ${FaNum.number(NotificationSchedule.maxCount)} اعلان '
                'روزانه می‌توانید داشته باشید. برای اعلان جدید، یکی را حذف کنید.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.tertiary),
              ),
            ),
          const SizedBox(height: 12),
          _StatusCard(status: _status),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed:
                  _busy || !_master ? null : () => _testNotification(context),
              icon: const Icon(Icons.notifications_none),
              label: const Text('اعلان تستی'),
            ),
          ),
          const Divider(height: 40),
          _sectionTitle(theme, Icons.dark_mode_outlined, 'نمایش'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('حالت شب'),
                subtitle: Text(isDark ? 'تم تاریک فعال است' : 'تم روشن فعال است'),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.tertiary,
                ),
                value: isDark,
                onChanged: (_) => ThemeController.toggle(),
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('نسخه $kHodaVersionFa - هُدا',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(NotificationSchedule schedule) {
    final theme = Theme.of(context);
    final active = _master && schedule.enabled;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? HodaColors.turquoise : Colors.grey.shade400,
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          active ? Icons.notifications_active : Icons.notifications_off,
          color: active ? HodaColors.turquoise : Colors.grey,
        ),
        title: Text(
          '${schedule.timeLabelFa} • ${schedule.typeLabelFa}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: active ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          active
              ? 'فعال — هر روز در ساعت ${schedule.timeLabelFa}'
              : 'غیرفعال',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'پیش‌نمایش',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: _busy
                  ? null
                  : () async {
                      final ok =
                          await NotificationService.showPreview(schedule);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'پیش‌نمایش ارسال شد 🌿'
                              : 'پیش‌نمایش ارسال نشد؛ دسترسی اعلان را بررسی کنید.'),
                        ),
                      );
                    },
            ),
            Switch(
              value: schedule.enabled,
              onChanged: _busy
                  ? null
                  : (v) => _apply(NotificationService.upsert(
                        schedule.copyWith(enabled: v),
                      )),
            ),
          ],
        ),
        onTap: _busy ? null : () => _editSchedule(schedule),
      ),
    );
  }

  Future<void> _addSchedule() async {
    // Find the lowest free slot id so notification ids stay stable.
    final used = _schedules.map((s) => s.id).toSet();
    var free = 0;
    while (used.contains(free) &&
        free < NotificationSchedule.maxCount) {
      free++;
    }
    final schedule = NotificationSchedule(id: free);
    await _editSchedule(schedule, isNew: true);
  }

  Future<void> _editSchedule(
    NotificationSchedule schedule, {
    bool isNew = false,
  }) async {
    final result = await showModalBottomSheet<NotificationSchedule>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleEditor(initial: schedule, isNew: isNew),
    );
    if (result == null) return;
    if (result.enabled) {
      await _apply(NotificationService.upsert(result));
    } else if (!isNew) {
      // Delete was chosen inside the editor.
      await _apply(NotificationService.remove(schedule.id));
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    final enabledTypes = _schedules.where((s) => s.enabled).map((s) => s.type);
    final type = enabledTypes.isEmpty ? 'random' : enabledTypes.first;
    final ok = await NotificationService.showTestNotification(type);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'اعلان تستی ارسال شد 🌿'
            : 'ارسال نشد؛ دسترسی اعلان را بررسی کنید.'),
      ),
    );
  }
}

/// Master on/off for the whole notification system.
class _MasterSwitch extends StatelessWidget {
  final bool master;
  final bool busy;
  final Map<String, dynamic>? status;
  final ValueChanged<bool> onChanged;

  const _MasterSwitch({
    required this.master,
    required this.busy,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: master ? HodaColors.gold : Colors.grey.shade400,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('کلید اصلی اعلان‌ها'),
            subtitle: Text(master ? 'فعال' : 'غیرفعال'),
            secondary: Icon(
              master ? Icons.notifications_active : Icons.notifications_off,
              color: master ? HodaColors.gold : Colors.grey,
            ),
            value: master,
            onChanged: busy ? null : onChanged,
          ),
          if (status != null && status!['notificationsAllowed'] == false)
            ListTile(
              dense: true,
              leading: const Icon(Icons.warning_amber_rounded,
                  color: HodaColors.gold),
              title: Text(
                'دسترسی اعلان در سیستم داده نشده است. برای فعال‌سازی، از تنظیمات '
                'گوشی اجازه بدهید.',
                style: theme.textTheme.bodySmall,
              ),
              trailing: TextButton(
                onPressed: NotificationService.openSystemSettings,
                child: const Text('تنظیمات'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline duplicate-time warning.
class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HodaColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HodaColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: HodaColors.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Shows what is actually armed: one row per active schedule with its next
/// fire time, plus the global mode (exact/inexact) and timezone.
class _StatusCard extends StatelessWidget {
  final Map<String, dynamic>? status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (status == null) return const SizedBox.shrink();
    final s = status!;
    final reports =
        (s['schedules'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
    final activeReports =
        reports.where((r) => r['active'] == true).toList();
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HodaColors.turquoise.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: HodaColors.turquoise, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('وضعیت اعلان‌ها',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s['summaryFa']?.toString() ?? '—',
                style: theme.textTheme.bodySmall),
            if (activeReports.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...activeReports.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: HodaColors.turquoise),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${r['typeLabelFa']} • ${r['time']}'
                          '${r['armed'] == true ? '' : ' (در انتظار ثبت)'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        r['nextFireLabel']?.toString() ?? '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.tertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (s['mode'] == 'inexact')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.alarm,
                        size: 16, color: HodaColors.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'زنگ دقیق در سیستم فعال نیست؛ اعلان‌ها ممکن است چند '
                        'دقیقه جابه‌جا شوند.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: NotificationService.openSystemSettings,
                      child: const Text('رفتن به تنظیمات'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet editor for one schedule: type chips, time picker, delete.
/// Returns the edited schedule (enabled=false means «delete» from this flow).
class _ScheduleEditor extends StatefulWidget {
  final NotificationSchedule initial;
  final bool isNew;
  const _ScheduleEditor({required this.initial, required this.isNew});

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late NotificationSchedule _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isNew ? 'اعلان جدید' : 'ویرایش اعلان',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in NotificationSchedule.types)
                  ChoiceChip(
                    label: Text(NotificationSchedule.labelForType(type)),
                    selected: _draft.type == type,
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(type: type)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time,
                  color: HodaColors.turquoise),
              title: const Text('ساعت اعلان'),
              trailing: Text(_draft.timeLabelFa,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _draft.time,
                );
                if (picked != null) {
                  setState(() => _draft = _draft.copyWith(
                        hour: picked.hour,
                        minute: picked.minute,
                      ));
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!widget.isNew)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_draft.copyWith(enabled: false)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('انصراف'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_draft.copyWith(enabled: true)),
                  icon: const Icon(Icons.check),
                  label: const Text('ذخیره'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
