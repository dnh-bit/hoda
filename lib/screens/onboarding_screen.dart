import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../theme/hoda_theme.dart';
import '../widgets/hoda_logo.dart';
import '../widgets/hoda_pattern.dart';

/// Preference key under which «onboarding finished» is stored.
const String kOnboardingDoneKey = 'hoda_onboarding_done_v1';

/// First-run onboarding: four full-bleed slides introducing the app, the daily
/// notifications (with an inline activation button), the dhikr counter and the
/// search / bookmark features.
///
/// Shown exactly once — [kOnboardingDoneKey] is written when the user finishes
/// (or skips) it. App updates never re-show it.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user finishes or skips, so the shell can replace this
  /// screen with the real app.
  final VoidCallback onDone;

  /// Whether onboarding still needs to run (first launch only).
  static Future<bool> shouldShow() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(kOnboardingDoneKey) ?? false);
    } catch (_) {
      return false; // Never block the app for a preference read.
    }
  }

  /// Marks onboarding as finished so it never shows again.
  static Future<void> markDone() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingDoneKey, true);
    } catch (_) {
      // Best-effort: worst case the slides show once more next launch.
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.showNotifyButton = false,
    this.showLogo = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool showNotifyButton;
  final bool showLogo;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  bool _enabling = false;
  bool? _enableResult;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      icon: Icons.auto_stories,
      title: 'به هُدا خوش آمدید',
      body: 'گنجینه‌ای از آیات قرآن، احادیث چهارده معصوم (ع)، وصایای شهدا و '
          'حکمت‌های نهج‌البلاغه — همیشه در جیب شما، بدون نیاز به اینترنت.',
      showLogo: true,
    ),
    _Slide(
      icon: Icons.notifications_active_outlined,
      title: 'اعلان‌های روزانه',
      body: 'هر روز چهار پیام معنوی دریافت کنید: آیه صبحگاهی ۷:۰۰، حدیث ۱۰:۰۰، '
          'حکمت ۱۳:۰۰ و وصیت شهید ۱۶:۰۰. بعداً می‌توانید ساعت‌ها و نوع محتوا '
          'را در تنظیمات تغییر دهید.',
      showNotifyButton: true,
    ),
    _Slide(
      icon: Icons.ads_click,
      title: 'ذکرشمار با هدف روزانه',
      body: 'صلوات و ذکرهای منتخب را با یک لمس بشمارید؛ حلقه پیشرفت، هدف روزانه '
          'و آمار هر ذکر جداگانه ذخیره می‌شود و هیچ‌وقت گم نمی‌شود.',
    ),
    _Slide(
      icon: Icons.search,
      title: 'جست‌وجو و نشان‌گذاری',
      body: 'در کل گنجینه جست‌وجو کنید — اعراب و نگارش مهم نیست — و هر متنی را '
          'که دوست داشتید نشان کنید تا همیشه یک لمس با شما فاصله داشته باشد.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    widget.onDone();
  }

  /// Slide 2's action: enable the master notification switch right here — this
  /// also seeds the four default schedules (07/10/13/16).
  Future<void> _enableNotifications() async {
    if (_enabling) return;
    setState(() {
      _enabling = true;
      _enableResult = null;
    });
    final Map<String, dynamic> status =
        await NotificationService.setMasterEnabled(true);
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
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final bool isLast = _page == _slides.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: PatternLayer(
                color: Colors.white.withOpacity(0.06),
                tile: 74,
              ),
            ),
            Positioned(
              top: -120,
              right: -90,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        HodaColors.goldLight.withOpacity(0.22),
                        HodaColors.goldLight.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('رد شدن'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (int i) => setState(() => _page = i),
                      itemBuilder: (BuildContext context, int i) {
                        final _Slide slide = _slides[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(30, 8, 30, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (slide.showLogo)
                                const HodaLogo(
                                  size: 124,
                                  ring: true,
                                  glow: true,
                                )
                              else
                                _SlideIcon(icon: slide.icon),
                              const SizedBox(height: 34),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              const OrnamentDivider(
                                width: 130,
                                color: HodaColors.goldGlow,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                slide.body,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.90),
                                  height: 2.0,
                                ),
                              ),
                              if (slide.showNotifyButton) ...<Widget>[
                                const SizedBox(height: 26),
                                if (_enableResult == true)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.check_circle,
                                        color: HodaColors.goldGlow,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'اعلان‌ها فعال شد! 🌿',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: _enabling
                                        ? null
                                        : _enableNotifications,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.16),
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.32),
                                      ),
                                    ),
                                    icon: _enabling
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .notifications_active_outlined,
                                            size: 19,
                                          ),
                                    label: const Text('فعال‌سازی اعلان‌ها'),
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
                    children: List<Widget>.generate(
                      _slides.length,
                      (int i) => AnimatedContainer(
                        duration: HodaMotion.medium,
                        curve: HodaMotion.enter,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? HodaColors.goldGlow
                              : Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLast
                            ? _finish
                            : () => _controller.nextPage(
                                  duration: HodaMotion.medium,
                                  curve: HodaMotion.enter,
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: HodaColors.goldLight,
                          foregroundColor: HodaColors.inkGreen,
                        ),
                        icon: Icon(
                          isLast
                              ? Icons.auto_awesome
                              : Icons.arrow_back,
                          size: 19,
                        ),
                        label: Text(isLast ? 'شروع کنیم' : 'بعدی'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular gradient badge behind a slide icon.
class _SlideIcon extends StatelessWidget {
  const _SlideIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: HodaColors.goldLight.withOpacity(0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: HodaColors.turquoiseLight.withOpacity(0.28),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: PatternLayer(
              color: Colors.white.withOpacity(0.10),
              tile: 46,
              drawGrid: false,
            ),
          ),
          Center(child: Icon(icon, size: 58, color: Colors.white)),
        ],
      ),
    );
  }
}
