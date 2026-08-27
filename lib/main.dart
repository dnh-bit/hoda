import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedIsDark = prefs.getBool('hoda_theme_is_dark') ?? false;
  ThemeController.mode.value = savedIsDark ? ThemeMode.dark : ThemeMode.light;

  ThemeController.mode.addListener(() async {
    await prefs.setBool('hoda_theme_is_dark', ThemeController.mode.value == ThemeMode.dark);
  });

  runApp(const HodaApp());
}

class HodaApp extends StatelessWidget {
  const HodaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
          builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const HomeScreen(),
        );
      },
    );
  }
}
