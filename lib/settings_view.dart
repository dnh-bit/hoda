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
    if (!mounted) return;
    setState(() {
      _notifEnabled = enabled;
      _notifTime = time;
      _notifType = type;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await NotificationService.saveSettings(
      enabled: _notifEnabled,
      time: _notifTime,
      type: _notifType,
    );
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
          subtitle: const Text('دریافت آیه، حدیث یا وصیت شهید در طول روز'),
          secondary: const Icon(Icons.notifications_active, color: HodaColors.gold),
          value: _notifEnabled,
          onChanged: (val) async {
            setState(() => _notifEnabled = val);
            await _save();
            if (val && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اعلان‌های روزانه فعال شد.')),
              );
            }
          },
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
              await _save();
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
                await _save();
              }
            },
          ),
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text('نسخه ۰.۰.۵ - هُدا (پیشرفته)',
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
