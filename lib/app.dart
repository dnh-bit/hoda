import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
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
class _AppGate extends StatelessWidget {
  const _AppGate();

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
