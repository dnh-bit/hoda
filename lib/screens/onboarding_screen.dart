import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../theme/hoda_theme.dart';
import '../widgets/hoda_logo.dart';

const String kOnboardingDoneKey = 'hoda_onboarding_done_v1';

/// Modern onboarding walkthrough with engaging typography, visual illustrations,
/// and smooth page indicators.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(kOnboardingDoneKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingDoneKey, true);
    } catch (_) {}
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _enabling = false;
  bool? _enableResult;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.auto_stories_rounded,
      title: 'به هُدا خوش آمدید',
      body: 'همراه معنوی روزانه شما؛ گنجینه‌ای از آیات قرآن، احادیث معصومین (ع)، '
          'حکمت‌های نهج‌البلاغه و وصایای شهدا — کاملاً آفلاین و در دسترس شما.',
    ),
    _Slide(
      icon: Icons.notifications_active_rounded,
      title: 'یادآور و اعلان‌های روزانه',
      body: 'هر روز با پیام‌های نورانی دلگرم شوید: آیه صبحگاهی ۷:۰۰، حدیث ۱۰:۰۰، '
          'حکمت ۱۳:۰۰ و وصیت شهید ۱۶:۰۰. قابلیت تنظیم دلخواه در هر ساعت.',
      showNotifyButton: true,
    ),
    _Slide(
      icon: Icons.touch_app_rounded,
      title: 'ذکرشمار و صلوات‌شمار هوشمند',
      body: 'ذکرهای مشهور و صلوات را با بازخورد لمسی دقیق بشمارید. '
          'آمار هر ذکر جداگانه ثبت شده و در هر زمان قابل مشاهده است.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    widget.onDone();
  }

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
    final isDark = theme.brightness == Brightness.dark;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // Top Skip Bar
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'رد شدن',
                      style: TextStyle(
                        fontFamily: HodaTheme.fontFamily,
                        color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Swipeable Slides
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 0) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: HodaColors.turquoise.withOpacity(0.25),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const HodaLogo(size: 130),
                            ),
                            const SizedBox(height: 36),
                          ] else ...[
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    HodaColors.turquoise,
                                    HodaColors.forestGreen,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: HodaColors.turquoise.withOpacity(0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(slide.icon, size: 66, color: Colors.white),
                            ),
                            const SizedBox(height: 36),
                          ],
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? HodaColors.cream : HodaColors.inkGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.9,
                              color: isDark ? HodaColors.darkTextMuted : HodaColors.textMuted,
                            ),
                          ),
                          if (slide.showNotifyButton) ...[
                            const SizedBox(height: 28),
                            if (_enableResult == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: HodaColors.forestGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_rounded, color: HodaColors.forestGreen, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'اعلان‌های روزانه فعال شد 🌿',
                                      style: TextStyle(
                                        fontFamily: HodaTheme.fontFamily,
                                        color: HodaColors.forestGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else
                              FilledButton.icon(
                                onPressed: _enabling ? null : _enableNotifications,
                                icon: _enabling
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.notifications_active_rounded, size: 18),
                                label: const Text('فعال‌سازی اعلان‌ها'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: HodaColors.forestGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicators & Button Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? HodaColors.turquoise
                                : (isDark ? HodaColors.darkBorder : HodaColors.gold.withOpacity(0.35)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: isLast
                            ? _finish
                            : () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: HodaColors.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          isLast ? 'ورود به هُدا' : 'ادامه',
                          style: const TextStyle(
                            fontFamily: HodaTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
