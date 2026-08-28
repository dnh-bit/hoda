import 'package:flutter/material.dart';
import 'theme.dart';
import 'notification_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notifEnabled = false;
  bool _systemGranted = true;
  TimeOfDay _notifTime = const TimeOfDay(hour: 8, minute: 0);
  String _notifType = 'random';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService.isEnabled();
    final time = await NotificationService.getTime();
    final type = await NotificationService.getType();
    final granted = await NotificationService.hasSystemPermission();
    if (!mounted) return;
    setState(() {
      _notifEnabled = enabled;
      _notifTime = time;
      _notifType = type;
      _systemGranted = granted;
      _loading = false;
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'اجازه اعلان داده نشد. از تنظیمات سیستم > برنامه‌ها > هُدا > اعلان‌ها می‌توانید فعالش کنید.'),
          duration: Duration(seconds: 5),
        ));
        return;
      }
    }

    await NotificationService.saveSettings(
      enabled: val,
      time: _notifTime,
      type: _notifType,
    );
    if (!mounted) return;
    setState(() => _systemGranted = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(val
          ? 'اعلان روزانه فعال شد — هر روز ساعت ${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}'
          : 'اعلان‌های روزانه غیرفعال شد.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تنظیمات و اعلان‌ها',
            style: Theme.of(context)
                .textTheme
                .titleLarge
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
                  color: Theme.of(context).colorScheme.tertiary),
              value: isDark,
              onChanged: (_) {
                ThemeController.toggle();
              },
            );
          },
        ),
        const Divider(height: 32),

        // Notifications Section
        Text('تنظیم اعلان‌های روزانه',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: HodaColors.turquoise)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('ارسال اعلان هوشمند'),
          subtitle: Text(_notifEnabled
              ? 'فعال — هر روز ساعت ${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}'
              : 'دریافت آیه، حدیث یا وصیت شهید در طول روز'),
          secondary: const Icon(Icons.notifications_active, color: HodaColors.gold),
          value: _notifEnabled,
          onChanged: _toggleEnabled,
        ),
        const SizedBox(height: 8),

        ListTile(
          title: const Text('ساعت ارسال اعلان'),
          subtitle: Text('${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}'),
          leading: const Icon(Icons.access_time, color: HodaColors.turquoise),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _notifTime,
            );
            if (picked != null) {
              setState(() => _notifTime = picked);
              if (_notifEnabled) {
                await NotificationService.saveSettings(
                    enabled: true, time: picked, type: _notifType);
              }
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
              DropdownMenuItem(value: 'random', child: Text('تصادفی (پیشنهادی)')),
              DropdownMenuItem(value: 'verse', child: Text('آیه قرآن')),
              DropdownMenuItem(value: 'hadith', child: Text('حدیث معصومین')),
              DropdownMenuItem(value: 'martyr', child: Text('وصیت شهید')),
              DropdownMenuItem(value: 'nahj', child: Text('حکمت نهج‌البلاغه')),
            ],
            onChanged: (val) async {
              if (val != null) {
                setState(() => _notifType = val);
                if (_notifEnabled) {
                  await NotificationService.saveSettings(
                      enabled: true, time: _notifTime, type: val);
                }
              }
            },
          ),
        ),

        // Test button — shows a notification right now
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final granted = await NotificationService.ensurePermission();
            if (!granted) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('اجازه اعلان از سیستم داده نشد.')));
              return;
            }
            await NotificationService.showTestNotification(_notifType);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اعلان تست ارسال شد 🌿')));
          },
          icon: const Icon(Icons.notifications_none),
          label: const Text('ارسال اعلان تست'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: HodaColors.gold),
            foregroundColor: Theme.of(context).colorScheme.tertiary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        if (!_systemGranted) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'اجازه اعلان از سیستم گرفته نشده است. برای فعال‌سازی، از تنظیمات سیستم > برنامه‌ها > هُدا > اعلان‌ها، اجازه را بدهید.',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Center(
          child: Text('نسخه ۰.۰.۶ - هُدا',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'verse': return 'آیه قرآن';
      case 'hadith': return 'حدیث معصومین';
      case 'martyr': return 'وصیت شهید';
      case 'nahj': return 'حکمت نهج‌البلاغه';
      default: return 'تصادفی (گزیده روز)';
    }
  }
}
