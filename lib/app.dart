import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/content_repository.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';
import 'theme/hoda_theme.dart';
import 'utils/app_error.dart';
import 'widgets/hoda_logo.dart';
import 'widgets/hoda_pattern.dart';

class HodaApp extends StatelessWidget {
  const HodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppError.last,
      builder: (BuildContext context, String? error, _) {
        if (error != null) return ErrorFallback(message: error);
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (BuildContext context, ThemeMode mode, __) {
            return MaterialApp(
              title: 'هُدا',
              debugShowCheckedModeBanner: false,
              theme: HodaTheme.light,
              darkTheme: HodaTheme.dark,
              themeMode: mode,
              locale: const Locale('fa', 'IR'),
              supportedLocales: const <Locale>[
                Locale('fa', 'IR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // A very large system font setting used to break the dense cards
              // and the nav bar; clamping keeps the layout intact while still
              // honouring accessibility (the reader has its own size control).
              builder: (BuildContext context, Widget? child) {
                return MediaQuery.withClampedTextScaling(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.25,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              // First launch shows the onboarding slides; afterwards the shell
              // (the gate resolves on every app start, before the first frame
              // of the shell is built, via the FutureBuilder below).
              home: const _AppGate(),
            );
          },
        );
      },
    );
  }
}

/// Decides between the onboarding slides and the main shell on app start.
///
/// While the gate resolves it also performs the **day rollover**: daily
/// content lives in a local SQLite copy and each card is picked by a
/// day-indexed rotation, so a device that left the app open across midnight
/// (or resumed it the next morning) must re-query the database — otherwise
/// «محتوای امروز» keeps showing yesterday's picks until a full restart. The
/// refresh runs once per process per local day (keyed by the epoch-day) and
/// re-arms the daily notifications so their bodies match the new picks.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  /// Epoch-day the rollover last ran for; survives only within this process.
  static int? _lastRolloverDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the foreground is the one moment a day may have changed
    // while the process stayed alive (user left the app open overnight).
    if (state == AppLifecycleState.resumed) _maybeRollover();
  }

  /// Refreshes the daily selection when the local day changed since the last
  /// run. Never blocks the first frame and never throws.
  Future<void> _maybeRollover() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final epochDay = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    if (_lastRolloverDay == epochDay) return;
    _lastRolloverDay = epochDay;
    try {
      // Loading the daily selection advances the rotation state for the new
      // day (day-gap aware), and re-arming keeps the notification bodies in
      // step with what the home cards now show.
      await ContentRepository.loadDaily();
      await NotificationService.restoreSchedule();
    } catch (_) {
      // Rollover is best-effort; the app must always come up.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingScreen.shouldShow(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          // One frame at most — the preference read is a millisecond or two.
          return const _SplashScreen();
        }
        if (snapshot.data == true) {
          return OnboardingScreen(
            onDone: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            },
          );
        }
        return const HomeScreen();
      },
    );
  }
}

/// Branded first frame: the logo on the app gradient instead of a bare spinner.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const HodaLogo(size: 108, ring: true, glow: true),
                  const SizedBox(height: 20),
                  Text(
                    'هُدا',
                    style: HodaTheme.appNameStyle(
                      context,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: HodaColors.goldGlow,
                    ),
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

/// Full-screen readable error page used when the app cannot start.
class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: HodaTheme.dark,
      home: Scaffold(
        backgroundColor: HodaColors.nightBase,
        appBar: AppBar(
          title: const Text('هُدا — خطا'),
          backgroundColor: HodaColors.danger,
          foregroundColor: Colors.white,
          actions: <Widget>[
            IconButton(
              tooltip: 'تلاش دوباره',
              icon: const Icon(Icons.refresh),
              onPressed: AppError.clear,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              message ?? 'خطای ناشناخته',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
