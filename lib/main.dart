import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';
import 'utils/app_error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface build errors as readable text instead of a gray box.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFECEC),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            AppError.format(details.exception, details.stack),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppError.record(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppError.record(error, stack);
    return true;
  };

  await runZonedGuarded(() async {
    await ThemeController.load();
    runApp(const HodaApp());

    // Re-arm every enabled daily notification after a reboot, an app update or
    // a force-stop (AlarmManager drops alarms in all three cases). Deliberately
    // not awaited so it never delays the first frame; it swallows its own
    // errors internally.
    unawaited(NotificationService.restoreSchedule());

    // Cold start from a notification tap: replay the payload once the shell is
    // mounted and listening, so it can switch to the matching tab. Also drains
    // a tap that the background isolate parked while the app was dead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.handleAppLaunchTap());
    });
  }, (error, stack) {
    AppError.record(error, stack);
  });
}
