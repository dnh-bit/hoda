import 'package:flutter/material.dart';

import '../models/notification_schedule.dart';
import '../services/notification_service.dart';
import '../services/theme_controller.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';

<<<<<<< HEAD
/// App version shown at the bottom of this screen. Keep in sync with the
/// `version:` field in pubspec.yaml (currently 0.1.6).
const String kHodaVersionFa = '۰.۱.۷ بتا';
=======
const String kHodaVersionFa = '۰.۱.۵';
>>>>>>> test/modern-ui-1

/// Modern settings screen with clean card groups, streamlined notification
/// management, and intuitive theme toggling.
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
      final schedules = await NotificationService.schedules();
      if (!mounted) return;
      setState(() => _schedules = schedules);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _capReached => _schedules.length >= NotificationSchedule.maxCount;

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
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: HodaColors.turquoise)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات برنامه')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Appearance / Theme Section
          _buildSectionHeader('ظاهر و پوسته', Icons.palette_outlined, isDark),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
              ),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) {
                final isDarkMode = mode == ThemeMode.dark;
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  title: const Text(
                    'حالت شب (تم تاریک)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    isDarkMode ? 'پوسته زمردی تیره فعال است' : 'پوسته کرم و سبز روشن فعال است',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                    ),
                  ),
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? HodaColors.goldLight : HodaColors.forestGreen).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDarkMode ? HodaColors.goldLight : HodaColors.forestGreen,
                      size: 20,
                    ),
                  ),
                  value: isDarkMode,
                  activeColor: HodaColors.turquoise,
                  onChanged: (_) => ThemeController.toggle(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 2. Daily Notifications Section
          _buildSectionHeader('اعلان‌های یادآور روزانه', Icons.notifications_active_outlined, isDark),
          const SizedBox(height: 10),
          _MasterSwitch(
            master: _master,
            busy: _busy,
            status: _status,
            onChanged: (v) => _apply(NotificationService.setMasterEnabled(v)),
          ),

          if (_duplicateWarning != null) ...[
            const SizedBox(height: 10),
            _WarningBanner(message: _duplicateWarning!),
          ],

          const SizedBox(height: 12),
          ..._schedules.map((s) => _buildScheduleCard(s, isDark)),

          if (!_capReached)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _addSchedule,
                icon: const Icon(Icons.add_alarm_rounded, size: 18),
                label: const Text('افزودن زمان‌بندی جدید'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
                  side: BorderSide(
                    color: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'حداکثر ${FaNum.number(NotificationSchedule.maxCount)} اعلان '
                'روزانه فعال است.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                ),
              ),
            ),

          const SizedBox(height: 16),
          _StatusCard(status: _status),

          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: _busy || !_master ? null : () => _testNotification(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('ارسال اعلان آزمایشی'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                side: BorderSide(
                  color: (isDark ? HodaColors.goldLight : HodaColors.goldDark).withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 36),

          // App Footer
          Center(
            child: Column(
              children: [
                Text(
                  'اپلیکیشن معنوی هُدا',
                  style: TextStyle(
                    fontFamily: HodaTheme.displayFontFamily,
                    fontSize: 18,
                    color: isDark ? HodaColors.goldLight : HodaColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نسخه $kHodaVersionFa • طراحی شده با عشق و اخلاص',
                  style: TextStyle(
                    fontFamily: HodaTheme.fontFamily,
                    fontSize: 11.5,
                    color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: HodaTheme.fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: isDark ? HodaColors.cream : HodaColors.inkGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(NotificationSchedule schedule, bool isDark) {
    final active = _master && schedule.enabled;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? (isDark ? HodaColors.turquoiseLight : HodaColors.turquoise)
              : (isDark ? HodaColors.darkBorder : HodaColors.borderSubtle),
          width: active ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (active ? HodaColors.turquoise : Colors.grey).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            active ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: active ? HodaColors.turquoise : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          '${schedule.timeLabelFa} • ${schedule.typeLabelFa}',
          style: TextStyle(
            fontFamily: HodaTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: active
                ? (isDark ? HodaColors.cream : HodaColors.inkGreen)
                : Colors.grey,
          ),
        ),
        subtitle: Text(
          active ? 'فعال — دریافت روزانه در این ساعت' : 'غیرفعال',
          style: TextStyle(
            fontFamily: HodaTheme.fontFamily,
            fontSize: 11,
            color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'پیش‌نمایش',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await NotificationService.showPreview(schedule);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'پیش‌نمایش اعلان ارسال شد'
                              : 'پیش‌نمایش ارسال نشد؛ دسترسی اعلان‌ها بررسی شود.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
            Switch(
              value: schedule.enabled,
              activeColor: HodaColors.turquoise,
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
    final used = _schedules.map((s) => s.id).toSet();
    var free = 0;
    while (used.contains(free) && free < NotificationSchedule.maxCount) {
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
            ? 'اعلان تستی با موفقیت ارسال شد 🌿'
            : 'ارسال نشد؛ لطفاً مجوز دسترسی اعلان را چک کنید.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: master
              ? (isDark ? HodaColors.goldLight : HodaColors.gold)
              : (isDark ? HodaColors.darkBorder : HodaColors.borderSubtle),
          width: master ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            title: const Text(
              'کلید اصلی اعلان‌ها',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              master ? 'سیستم اعلان‌ها روشن است' : 'همه یادآورها خاموش هستند',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
              ),
            ),
            secondary: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (master ? HodaColors.gold : Colors.grey).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                master ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: master ? (isDark ? HodaColors.goldLight : HodaColors.goldDark) : Colors.grey,
                size: 20,
              ),
            ),
            value: master,
            activeColor: HodaColors.gold,
            onChanged: busy ? null : onChanged,
          ),
          if (status != null && status!['notificationsAllowed'] == false)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'دسترسی اعلان در گوشی داده نشده است.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: NotificationService.openSystemSettings,
                      child: const Text('تنظیمات دستگاه'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, dynamic>? status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (status == null) return const SizedBox.shrink();
    final s = status!;
    final reports = (s['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final activeReports = reports.where((r) => r['active'] == true).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? HodaColors.darkBorder : HodaColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: isDark ? HodaColors.turquoiseLight : HodaColors.turquoise,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'وضعیت زمان‌بندی‌ها',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s['summaryFa']?.toString() ?? '—',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
            ),
          ),
          if (activeReports.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...activeReports.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark ? HodaColors.turquoiseLight : HodaColors.turquoise,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${r['typeLabelFa']} • ${r['time']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      r['nextFireLabel']?.toString() ?? '—',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? HodaColors.goldLight : HodaColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? HodaColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
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
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? HodaColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isNew ? 'افزودن اعلان روزانه' : 'ویرایش اعلان',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'نوع محتوای ارسالی:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in NotificationSchedule.types)
                    ChoiceChip(
                      label: Text(NotificationSchedule.labelForType(type)),
                      selected: _draft.type == type,
                      selectedColor: isDark ? HodaColors.turquoiseLight : HodaColors.forestGreen,
                      onSelected: (_) =>
                          setState(() => _draft = _draft.copyWith(type: type)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded, color: HodaColors.turquoise),
                title: const Text('ساعت ارسال اعلان'),
                trailing: Text(
                  _draft.timeLabelFa,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? HodaColors.goldLight : HodaColors.forestGreen,
                  ),
                ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!widget.isNew)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_draft.copyWith(enabled: false)),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
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
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('ذخیره تغییرات'),
                    style: FilledButton.styleFrom(
                      backgroundColor: HodaColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
