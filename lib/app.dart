import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
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
              home: const HomeScreen(),
            );
          },
        );
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
