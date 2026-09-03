import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_content.dart';
import '../services/favorites_store.dart';
import '../theme/hoda_theme.dart';

/// Shared actions available on every piece of content (copy, bookmark) plus the
/// snackbar styling they use, so a card, a list row and the detail page all
/// behave identically.
class ContentActions {
  ContentActions._();

  /// The item as shareable plain text.
  static String plainText(DailyContent content) {
    final List<String> parts = <String>[
      if (content.hasArabic) content.arabic.trim(),
      if (content.hasPersian) content.persian.trim(),
      if (content.hasSource) '— ${content.source.trim()}',
    ];
    return parts.join('\n\n');
  }

  static void toast(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline,
  }) {
    final HodaPalette palette = HodaPalette.of(context);
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static Future<void> copy(BuildContext context, DailyContent content) async {
    await Clipboard.setData(ClipboardData(text: plainText(content)));
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    toast(context, 'متن کپی شد', icon: Icons.copy_outlined);
  }

  /// Adds/removes the bookmark and confirms it with a toast.
  static Future<void> toggleFavorite(
    BuildContext context,
    DailyContent content,
  ) async {
    if (content.uid == null || content.uid!.isEmpty) {
      toast(context, 'این مورد قابل نشان‌گذاری نیست',
          icon: Icons.info_outline);
      return;
    }
    final bool added = await FavoritesStore.toggle(content.uid);
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    toast(
      context,
      added ? 'به نشان‌شده‌ها اضافه شد' : 'از نشان‌شده‌ها حذف شد',
      icon: added ? Icons.bookmark : Icons.bookmark_border,
    );
  }
}
