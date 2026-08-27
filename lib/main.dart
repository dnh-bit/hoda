import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'home_screen.dart';

String? _lastError;

String _formatError(Object? error, StackTrace? stack) {
  String msg = error?.toString() ?? 'Unknown error';
  if (stack != null) {
    final lines = stack.toString().split('\n');
    if (lines.length > 6) {
      msg += '\n\n' + lines.sublist(0, 6).join('\n');
    }
  }
  return msg;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface build errors as text instead of a gray box.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFECEC),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            _formatError(details.exception, details.stack),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                color: Color(0xFF8B0000),
                fontSize: 13,
                fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _lastError = _formatError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _lastError = _formatError(error, stack);
    return true;
  };

  await runZonedGuarded(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIsDark = prefs.getBool('hoda_theme_is_dark') ?? false;
      ThemeController.mode.value =
          savedIsDark ? ThemeMode.dark : ThemeMode.light;

      ThemeController.mode.addListener(() async {
        try {
          final p = await SharedPreferences.getInstance();
          await p.setBool('hoda_theme_is_dark',
              ThemeController.mode.value == ThemeMode.dark);
        } catch (_) {}
      });
    } catch (e) {
      _lastError = _formatError(e, null);
    }

    runApp(const HodaApp());
  }, (error, stack) {
    _lastError = _formatError(error, stack);
  });
}

class ErrorFallback extends StatelessWidget {
  const ErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
            title: const Text('هُدا - خطا'),
            backgroundColor: Colors.red[900]),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              _lastError ?? 'خطای ناشناخته',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}

class HodaApp extends StatelessWidget {
  const HodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (_lastError != null) return const ErrorFallback();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'هُدا',
          debugShowCheckedModeBanner: false,
          theme: HodaTheme.light,
          darkTheme: HodaTheme.dark,
          themeMode: mode,
          // RTL layout for Persian content (text renders RTL natively via bidi).
          builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl, child: child!),
          home: const HomeScreen(),
        );
      },
    );
  }
}
