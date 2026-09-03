import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bookmarks («نشان‌شده‌ها»).
///
/// Only the stable `<table>:<id>` uid of each item is stored, so the list keeps
/// working when the bundled database is refreshed and it costs a few bytes in
/// SharedPreferences. The actual content is resolved from the loaded snapshot
/// through `HodaContent.findByUid`.
///
/// [uids] is a notifier so every bookmark button, the counter in the app bar and
/// the favourites screen stay in sync without any plumbing.
class FavoritesStore {
  FavoritesStore._();

  static const String _key = 'hoda_favorites_v1';

  static final ValueNotifier<Set<String>> uids =
      ValueNotifier<Set<String>>(<String>{});

  static bool _loaded = false;

  static int get count => uids.value.length;

  static bool contains(String? uid) =>
      uid != null && uid.isNotEmpty && uids.value.contains(uid);

  /// Reads the stored bookmarks once per process.
  static Future<Set<String>> ensureLoaded() async {
    if (_loaded) return uids.value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      uids.value = (prefs.getStringList(_key) ?? const <String>[])
          .where((String e) => e.trim().isNotEmpty)
          .toSet();
    } catch (_) {
      // Bookmarks are a nicety; never let a failed read break a screen.
    }
    _loaded = true;
    return uids.value;
  }

  /// Adds or removes [uid]; returns the new membership state.
  static Future<bool> toggle(String? uid) async {
    if (uid == null || uid.isEmpty) return false;
    final Set<String> next = Set<String>.of(uids.value);
    final bool added = next.add(uid);
    if (!added) next.remove(uid);
    uids.value = next;
    await _persist();
    return added;
  }

  static Future<void> remove(String uid) async {
    if (!uids.value.contains(uid)) return;
    final Set<String> next = Set<String>.of(uids.value)..remove(uid);
    uids.value = next;
    await _persist();
  }

  static Future<void> clear() async {
    uids.value = <String>{};
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, uids.value.toList());
    } catch (_) {
      // Best-effort: the in-memory set still drives this session.
    }
  }
}
