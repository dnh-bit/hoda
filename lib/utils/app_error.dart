import 'dart:async';

import 'package:flutter/foundation.dart';

/// Collects fatal errors during bootstrap/runtime so the UI can show a
/// readable message instead of a gray screen.
class AppError {
  AppError._();

  /// Last captured error, formatted for display. `null` when healthy.
  static final ValueNotifier<String?> last = ValueNotifier<String?>(null);

  static String format(Object? error, StackTrace? stack) {
    var message = error?.toString() ?? 'Unknown error';
    if (stack != null) {
      final lines = stack.toString().split('\n');
      if (lines.length > 6) {
        message += '\n\n${lines.sublist(0, 6).join('\n')}';
      } else {
        message += '\n\n${lines.join('\n')}';
      }
    }
    return message;
  }

  static void record(Object? error, StackTrace? stack) {
    final message = format(error, stack);
    // Deferred so listeners are never notified in the middle of a build.
    scheduleMicrotask(() => last.value = message);
  }

  static void clear() => last.value = null;
}
