import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/theme_controller.dart';
import 'theme/hoda_theme.dart';
import 'utils/app_error.dart';

class HodaApp extends StatelessWidget {
  const HodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppError.last,
      builder: (context, error, __) {
        if (error != null) return ErrorFallback(message: error);
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'هُدا',
              debugShowCheckedModeBanner: false,
              theme: HodaTheme.light,
              darkTheme: HodaTheme.dark,
              themeMode: mode,
              locale: const Locale('fa', 'IR'),
              supportedLocales: const [
                Locale('fa', 'IR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
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
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // One frame at most — the preference read is a millisecond or two.
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: HodaColors.turquoise),
            ),
          );
        }
        if (snapshot.data == true) {
          return OnboardingScreen(
            onDone: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          );
        }
        return const HomeScreen();
      },
    );
  }
}

/// Full-screen readable error page used when the app cannot start.
class ErrorFallback extends StatelessWidget {
  final String? message;
  const ErrorFallback({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          title: const Text('هُدا - خطا'),
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
          actions: [
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
