import 'package:flutter/material.dart';

import '../models/notification_schedule.dart';
import '../services/favorites_store.dart';
import '../services/notification_service.dart';
import '../services/reader_settings.dart';
import '../services/theme_controller.dart';
import '../theme/content_style.dart';
import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';
import '../widgets/arabic_text.dart';
import '../widgets/hoda_app_bar.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/hoda_pattern.dart';
import '../widgets/info_pill.dart';
import '../widgets/motion.dart';
import '../widgets/section_header.dart';

/// App version shown at the bottom of this screen. Keep in sync with the
/// `version:` field in pubspec.yaml (currently 0.2.0).
const String kHodaVersionFa = '۰.۲.۰';

/// Icon for a notification content type.
IconData _iconForType(String type) {
  switch (type) {
    case 'verse':
      return ContentStyle.verse.icon;
    case 'hadith':
      return ContentStyle.hadith.icon;
    case 'martyr':
      return ContentStyle.martyr.icon;
    case 'nahj':
      return ContentStyle.nahj.icon;
    default:
      return Icons.shuffle;
  }
}

/// Colour for a notification content type.
Color _colorForType(BuildContext context, String type) {
  switch (type) {
    case 'verse':
      return ContentStyle.verse.colorOf(context);
    case 'hadith':
      return ContentStyle.hadith.colorOf(context);
    case 'martyr':
      return ContentStyle.martyr.colorOf(context);
    case 'nahj':
      return ContentStyle.nahj.colorOf(context);
    default:
      return HodaColors.turquoise;
  }
}

/// Settings: appearance, reading, the multi-schedule notification manager (up to
/// five daily notifications, each with its own time and content type), saved
/// items and the about card.
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
    ReaderSettings.ensureLoaded();
    _reload();
  }

  Future<void> _reload() async {
    final bool master = await NotificationService.isMasterEnabled();
    final List<NotificationSchedule> schedules =
        await NotificationService.schedules();
    final Map<String, dynamic> status =
        await NotificationService.scheduleStatus();
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
      final Map<String, dynamic> status = await action;
      if (!mounted) return;
      setState(() {
        _status = status;
        _master = status['masterEnabled'] == true;
      });
      // Reload the local list so sort order/cap always mirrors the store.
      final List<NotificationSchedule> schedules =
          await NotificationService.schedules();
      if (!mounted) return;
      setState(() => _schedules = schedules);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _capReached => _schedules.length >= NotificationSchedule.maxCount;

  /// Two ENABLED schedules sharing the same wall-clock minute is almost always a
  /// mistake — surface it before the user wonders why two notes arrive together.
  String? get _duplicateWarning {
    final Map<int, NotificationSchedule> seen =
        <int, NotificationSchedule>{};
    for (final NotificationSchedule s in _schedules) {
      if (!s.enabled) continue;
      final NotificationSchedule? previous = seen[s.minutesOfDay];
      if (previous != null) {
        return 'دو اعلان فعال روی ساعت ${s.timeLabelFa} تنظیم شده است.';
      }
      seen[s.minutesOfDay] = s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const HodaAppBar(titleText: 'تنظیمات'),
        body: const HodaBackground(
          child: Center(
            child: CircularProgressIndicator(color: HodaColors.turquoise),
          ),
        ),
      );
    }

    int i = 0;
    Widget reveal(Widget child) =>
        Reveal(delay: Reveal.stagger(i++), child: child);

    return Scaffold(
      appBar: const HodaAppBar(titleText: 'تنظیمات'),
      body: HodaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            reveal(const _AppearanceSection()),
            const SizedBox(height: 22),
            reveal(const _ReadingSection()),
            const SizedBox(height: 22),
            reveal(_notificationsSection()),
            const SizedBox(height: 22),
            reveal(const _SavedSection()),
            const SizedBox(height: 22),
            reveal(const _AboutCard()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _notificationsSection() {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          icon: Icons.notifications_active_outlined,
          title: 'اعلان‌های روزانه',
          subtitle: 'تا ${FaNum.number(NotificationSchedule.maxCount)} یادآور، '
              'هر کدام با ساعت و محتوای دلخواه',
          color: HodaColors.turquoise,
        ),
        const SizedBox(height: 12),
        _MasterSwitch(
          master: _master,
          busy: _busy,
          status: _status,
          onChanged: (bool v) =>
              _apply(NotificationService.setMasterEnabled(v)),
        ),
        if (!_master) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'برای مدیریت اعلان‌ها، ابتدا کلید اصلی را روشن کنید.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_duplicateWarning != null) ...<Widget>[
          const SizedBox(height: 10),
          _WarningBanner(message: _duplicateWarning!),
        ],
        const SizedBox(height: 12),
        for (final NotificationSchedule s in _schedules) ...<Widget>[
          _buildScheduleCard(s),
          const SizedBox(height: 10),
        ],
        if (!_capReached)
          OutlinedButton.icon(
            onPressed: _busy ? null : _addSchedule,
            icon: const Icon(Icons.add_alarm, size: 18),
            label: const Text('افزودن اعلان جدید'),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: palette.card(elevated: false),
            child: Text(
              'حداکثر ${FaNum.number(NotificationSchedule.maxCount)} اعلان روزانه '
              'می‌توانید داشته باشید. برای اعلان جدید، یکی را حذف کنید.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 14),
        _StatusCard(status: _status),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy || !_master ? null : () => _testNotification(context),
          icon: const Icon(Icons.notifications_none, size: 18),
          label: const Text('ارسال اعلان تستی'),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(NotificationSchedule schedule) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final bool active = _master && schedule.enabled;
    final Color color = active
        ? _colorForType(context, schedule.type)
        : palette.faint;

    return PressableScale(
      onTap: _busy ? null : () => _editSchedule(schedule),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: palette.card(
          accentColor: active ? color : null,
          radius: HodaRadius.md,
          elevated: active,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 62,
              height: 56,
              decoration: BoxDecoration(
                gradient: active ? palette.tintGradient(color) : null,
                color: active ? null : palette.surfaceSunken,
                borderRadius: HodaRadius.all(HodaRadius.sm),
                border: Border.all(color: color.withOpacity(0.30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    schedule.timeLabelFa,
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Icon(_iconForType(schedule.type), size: 14, color: color),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    schedule.typeLabelFa,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    active
                        ? 'هر روز، ساعت ${schedule.timeLabelFa}'
                        : 'غیرفعال',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'پیش‌نمایش',
              icon: const Icon(Icons.play_circle_outline, size: 22),
              color: palette.muted,
              onPressed: _busy
                  ? null
                  : () async {
                      final bool ok =
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
                  : (bool v) => _apply(
                        NotificationService.upsert(
                          schedule.copyWith(enabled: v),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSchedule() async {
    // Find the lowest free slot id so notification ids stay stable.
    final Set<int> used = _schedules.map((NotificationSchedule s) => s.id).toSet();
    int free = 0;
    while (used.contains(free) && free < NotificationSchedule.maxCount) {
      free++;
    }
    final NotificationSchedule schedule = NotificationSchedule(id: free);
    await _editSchedule(schedule, isNew: true);
  }

  Future<void> _editSchedule(
    NotificationSchedule schedule, {
    bool isNew = false,
  }) async {
    final NotificationSchedule? result =
        await showModalBottomSheet<NotificationSchedule>(
      context: context,
      isScrollControlled: true,
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
    final Iterable<String> enabledTypes = _schedules
        .where((NotificationSchedule s) => s.enabled)
        .map((NotificationSchedule s) => s.type);
    final String type = enabledTypes.isEmpty ? 'random' : enabledTypes.first;
    final bool ok = await NotificationService.showTestNotification(type);
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

/// Appearance: light / dark / follow-system, as three tappable cards.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(
          icon: Icons.palette_outlined,
          title: 'نمایش',
          subtitle: 'حالت روشن، شب یا هماهنگ با سیستم',
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (BuildContext context, ThemeMode mode, _) {
            return Row(
              children: <Widget>[
                for (final ThemeMode option in <ThemeMode>[
                  ThemeMode.light,
                  ThemeMode.dark,
                  ThemeMode.system,
                ]) ...<Widget>[
                  Expanded(
                    child: _ThemeOption(
                      mode: option,
                      selected: mode == option,
                      onTap: () => ThemeController.setMode(option),
                    ),
                  ),
                  if (option != ThemeMode.system) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color color = selected ? HodaColors.turquoise : palette.faint;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: HodaMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: palette.card(
          accentColor: selected ? HodaColors.turquoise : null,
          radius: HodaRadius.md,
          elevated: selected,
        ),
        child: Column(
          children: <Widget>[
            Icon(ThemeController.iconFor(mode), size: 22, color: color),
            const SizedBox(height: 8),
            Text(
              ThemeController.labelFor(mode),
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reading: the global text size, with a live Arabic + Persian preview.
class _ReadingSection extends StatelessWidget {
  const _ReadingSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(
          icon: Icons.menu_book_outlined,
          title: 'خواندن',
          subtitle: 'اندازه و چینش متن در صفحه‌های محتوا',
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<double>(
          valueListenable: ReaderSettings.scale,
          builder: (BuildContext context, double scale, _) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: palette.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'اندازه متن',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      InfoPill(
                        label: '${FaNum.number(ReaderSettings.percent)}٪',
                        dense: true,
                        color: palette.accent,
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'کوچک‌تر',
                        onPressed: ReaderSettings.canShrink
                            ? ReaderSettings.shrink
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Slider(
                          min: ReaderSettings.minScale,
                          max: ReaderSettings.maxScale,
                          divisions: 7,
                          value: scale.clamp(
                            ReaderSettings.minScale,
                            ReaderSettings.maxScale,
                          ),
                          onChanged: ReaderSettings.setScale,
                        ),
                      ),
                      IconButton(
                        tooltip: 'بزرگ‌تر',
                        onPressed:
                            ReaderSettings.canGrow ? ReaderSettings.grow : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: palette.inset(),
                    child: Column(
                      children: <Widget>[
                        ArabicText(
                          'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً',
                          fontSize: 20 * scale,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'پروردگارا، از سوی خود رحمتی به ما عطا کن.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 14 * scale),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: ReaderSettings.justify,
                    builder: (BuildContext context, bool justify, __) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('چینش هم‌تراز پاراگراف'),
                        subtitle: Text(
                          justify ? 'مثل صفحه کتاب' : 'چینش از راست',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: justify,
                        onChanged: ReaderSettings.setJustify,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Saved items: how many bookmarks exist, and a way to clear them.
class _SavedSection extends StatelessWidget {
  const _SavedSection();

  Future<void> _clear(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('پاک کردن نشان‌شده‌ها'),
        content: const Text('همه موارد نشان‌شده حذف می‌شوند.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: HodaColors.danger),
            child: const Text('پاک کن'),
          ),
        ],
      ),
    );
    if (ok == true) await FavoritesStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(
          icon: Icons.bookmarks_outlined,
          title: 'ذخیره‌شده‌ها',
          subtitle: 'موارد نشان‌گذاری‌شده روی همین دستگاه',
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<Set<String>>(
          valueListenable: FavoritesStore.uids,
          builder: (BuildContext context, Set<String> uids, _) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: palette.card(),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: palette.tintGradient(palette.accent),
                      borderRadius: HodaRadius.all(HodaRadius.sm),
                    ),
                    child: Icon(
                      Icons.bookmark_outline,
                      size: 20,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${FaNum.number(uids.length)} مورد نشان‌شده',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'روی هر کارت، آیکن نشان‌گذاری را بزنید.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (uids.isNotEmpty)
                    TextButton(
                      onPressed: () => _clear(context),
                      style: TextButton.styleFrom(
                        foregroundColor: HodaColors.danger,
                      ),
                      child: const Text('پاک کردن'),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Master on/off for the whole notification system.
class _MasterSwitch extends StatelessWidget {
  const _MasterSwitch({
    required this.master,
    required this.busy,
    required this.status,
    required this.onChanged,
  });

  final bool master;
  final bool busy;
  final Map<String, dynamic>? status;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color color = master ? HodaColors.turquoise : palette.faint;

    return Container(
      decoration: palette.card(
        accentColor: master ? HodaColors.turquoise : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: master ? palette.tintGradient(color) : null,
                    color: master ? null : palette.surfaceSunken,
                    borderRadius: HodaRadius.all(HodaRadius.sm),
                  ),
                  child: Icon(
                    master
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    size: 21,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'کلید اصلی اعلان‌ها',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        master ? 'فعال' : 'غیرفعال',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: master,
                  onChanged: busy ? null : onChanged,
                ),
              ],
            ),
          ),
          if (status != null && status!['notificationsAllowed'] == false)
            Container(
              width: double.infinity,
              color: HodaColors.gold.withOpacity(0.10),
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: HodaColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'دسترسی اعلان در سیستم داده نشده است. برای فعال‌سازی، از '
                      'تنظیمات گوشی اجازه بدهید.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: NotificationService.openSystemSettings,
                    child: const Text('تنظیمات'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline duplicate-time warning.
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HodaColors.gold.withOpacity(0.12),
        borderRadius: HodaRadius.all(HodaRadius.sm),
        border: Border.all(color: HodaColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: HodaColors.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Shows what is actually armed: one row per active schedule with its next fire
/// time, plus the global mode (exact/inexact) and timezone summary.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final Map<String, dynamic>? status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    if (status == null) return const SizedBox.shrink();
    final Map<String, dynamic> s = status!;
    final List<Map<String, dynamic>> reports =
        (s['schedules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> activeReports = reports
        .where((Map<String, dynamic> r) => r['active'] == true)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: palette.card(accentColor: HodaColors.turquoise),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.verified_outlined,
                color: HodaColors.turquoise,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('وضعیت اعلان‌ها',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s['summaryFa']?.toString() ?? '—',
            style: theme.textTheme.bodySmall,
          ),
          if (activeReports.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final Map<String, dynamic> r in activeReports)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: HodaColors.turquoise,
                    ),
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
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: palette.accent),
                    ),
                  ],
                ),
              ),
          ],
          if (s['mode'] == 'inexact')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.alarm, size: 16, color: HodaColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'زنگ دقیق در سیستم فعال نیست؛ اعلان‌ها ممکن است چند دقیقه '
                      'جابه‌جا شوند.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: NotificationService.openSystemSettings,
                    child: const Text('تنظیمات'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// About card: logo, version, a one-line description and the font credit.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.card(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: palette.accent.withOpacity(0.05),
              tile: 60,
            ),
          ),
          Column(
            children: <Widget>[
              const HodaLogo(size: 58, ring: true),
              const SizedBox(height: 12),
              Text('هُدا', style: HodaTheme.appNameStyle(
                context,
                size: 26,
                color: palette.text,
              )),
              const SizedBox(height: 4),
              Text(
                'گنجینه معنوی روزانه — کاملاً آفلاین',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const OrnamentDivider(width: 120),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  InfoPill(
                    label: 'نسخه $kHodaVersionFa',
                    icon: Icons.verified_outlined,
                    dense: true,
                    color: palette.accent,
                  ),
                  const InfoPill(
                    label: 'بدون اینترنت',
                    icon: Icons.wifi_off,
                    dense: true,
                    color: HodaColors.turquoise,
                  ),
                  const InfoPill(
                    label: 'بدون تبلیغات',
                    icon: Icons.block,
                    dense: true,
                    color: HodaColors.clay,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'قلم‌ها: Vazirmatn و Lalezar و Amiri (SIL OFL 1.1)',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.faint,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet editor for one schedule: content type, time (with presets) and
/// delete. Returns the edited schedule (enabled=false means «delete»).
class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({required this.initial, required this.isNew});

  final NotificationSchedule initial;
  final bool isNew;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late NotificationSchedule _draft = widget.initial;

  static const List<List<int>> _presets = <List<int>>[
    <int>[7, 0],
    <int>[10, 0],
    <int>[13, 0],
    <int>[16, 0],
    <int>[21, 0],
  ];

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _draft.time,
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(
            hour: picked.hour,
            minute: picked.minute,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isNew ? 'اعلان جدید' : 'ویرایش اعلان',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'نوع محتوا و ساعت ارسال را انتخاب کنید.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('نوع محتوا', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String type in NotificationSchedule.types)
                    PressableScale(
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(type: type)),
                      child: AnimatedContainer(
                        duration: HodaMotion.fast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: _draft.type == type
                              ? palette.tintGradient(
                                  _colorForType(context, type),
                                )
                              : null,
                          color: _draft.type == type ? null : palette.surface,
                          borderRadius: HodaRadius.all(HodaRadius.pill),
                          border: Border.all(
                            color: _draft.type == type
                                ? _colorForType(context, type)
                                    .withOpacity(0.55)
                                : palette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              _iconForType(type),
                              size: 15,
                              color: _draft.type == type
                                  ? _colorForType(context, type)
                                  : palette.muted,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              NotificationSchedule.labelForType(type),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _draft.type == type
                                    ? _colorForType(context, type)
                                    : palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('ساعت ارسال', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              PressableScale(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: palette.card(accentColor: HodaColors.turquoise),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.access_time,
                        color: HodaColors.turquoise,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'انتخاب ساعت',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        _draft.timeLabelFa,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: HodaColors.turquoise),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final List<int> preset in _presets)
                    InfoPill(
                      label: FaNum.time(preset[0], preset[1]),
                      icon: Icons.schedule,
                      dense: true,
                      color: _draft.hour == preset[0] &&
                              _draft.minute == preset[1]
                          ? HodaColors.turquoise
                          : palette.muted,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(
                          hour: preset[0],
                          minute: preset[1],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  if (!widget.isNew)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pop(_draft.copyWith(enabled: false)),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('حذف'),
                      style: TextButton.styleFrom(
                        foregroundColor: HodaColors.danger,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('انصراف'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(_draft.copyWith(enabled: true)),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('ذخیره'),
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
