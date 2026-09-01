import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../theme/hoda_theme.dart';
import '../widgets/hoda_logo.dart';

/// First-run onboarding: three swipeable slides introducing the app, the daily
/// notifications (with an inline activation button) and the dhikr counter.
///
/// Shown exactly once — the [kOnboardingDoneKey] preference is written when the
/// user finishes (or skips) it. App updates never re-show it.
class OnboardingScreen extends StatefulWidget {
  /// Called when the user finishes or skips, so the shell can replace this
  /// screen with the real app.
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  /// Whether onboarding still needs to run (first launch only).
  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(kOnboardingDoneKey) ?? false);
    } catch (_) {
      return false; // Never block the app for a preference read.
    }
  }

  /// Marks onboarding as finished so it never shows again.
  static Future<void> markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingDoneKey, true);
    } catch (_) {
      // Best-effort: worst case the slides show once more next launch.
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Preference key under which «onboarding finished» is stored.
const String kOnboardingDoneKey = 'hoda_onboarding_done_v1';

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  bool _enabling = false;
  bool? _enableResult;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.auto_stories,
      title: 'به هُدا خوش آمدید',
      body: 'گنجینه‌ای از آیات قرآن، احادیث چهارده معصوم (ع)، وصایای شهدا و '
          'حکمت‌های نهج‌البلاغه — همیشه در جیب شما، بدون نیاز به اینترنت.',
    ),
    _Slide(
      icon: Icons.notifications_active_outlined,
      title: 'اعلان‌های روزانه',
      body: 'هر روز چهار پیام معنوی دریافت کنید: آیه صبحگاهی ۷:۰۰، حدیث ۱۰:۰۰، '
          'حکمت ۱۳:۰۰ و وصیت شهید ۱۶:۰۰. بعداً می‌توانید ساعت‌ها را در '
          'تنظیمات تغییر دهید.',
      showNotifyButton: true,
    ),
    _Slide(
      icon: Icons.touch_app_outlined,
      title: 'ذکرشمار',
      body: 'صلوات و ذکرهای منتخب را با یک لمس بشمارید؛ آمار هر ذکر جداگانه '
          'ذخیره می‌شود و هیچ‌وقت گم نمی‌شود.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    widget.onDone();
  }

  /// Slide 2's action: enable the master notification switch right here —
  /// this also seeds the four default schedules (07/10/13/16).
  Future<void> _enableNotifications() async {
    if (_enabling) return;
    setState(() {
      _enabling = true;
      _enableResult = null;
    });
    final status = await NotificationService.setMasterEnabled(true);
    if (!mounted) return;
    setState(() {
      _enabling = false;
      _enableResult = (status['masterEnabled'] == true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('رد شدن'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 0) ...[
                            const HodaLogo(size: 120),
                            const SizedBox(height: 32),
                          ] else ...[
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    HodaColors.turquoise,
                                    HodaColors.forestGreen
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: HodaColors.turquoise
                                        .withOpacity(0.30),
                                    blurRadius: 26,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(slide.icon,
                                  size: 62, color: Colors.white),
                            ),
                            const SizedBox(height: 32),
                          ],
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (slide.showNotifyButton) ...[
                            const SizedBox(height: 28),
                            if (_enableResult == true) ...[
                              const Icon(Icons.check_circle_outline,
                                  color: HodaColors.forestGreen, size: 28),
                              const SizedBox(height: 8),
                              const Text(
                                'اعلان‌ها فعال شد! 🌿',
                                style: TextStyle(
                                  color: HodaColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else
                              FilledButton.icon(
                                onPressed:
                                    _enabling ? null : _enableNotifications,
                                icon: _enabling
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.notifications_active_outlined,
                                        size: 20),
                                label: const Text('فعال‌سازی اعلان‌ها'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: HodaColors.turquoise,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? HodaColors.turquoise
                          : HodaColors.gold.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: HodaColors.turquoise,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isLast ? 'شروع کنیم' : 'بعدی'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  final bool showNotifyButton;

  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.showNotifyButton = false,
  });
}
