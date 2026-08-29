import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Thin data-access layer over the bundled read-only content database.
class DatabaseHelper {
  DatabaseHelper._();

  static Database? _database;
  static const String dbName = 'hoda.db';
  static const String assetPath = 'assets/hoda.db';

  /// Content/schema stamp of the bundled database. Bump this whenever
  /// `assets/hoda.db` changes structurally (new tables/columns) or wholesale
  /// (v0.1.0 content refresh): existing installs then re-copy the bundled file
  /// over their stale copy. Pure row additions don't need a bump.
  static const int dbContentVersion = 2;

  static const String _stampKey = 'hoda_db_content_version';

  static Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), dbName);

    try {
      await _copyAssetIfMissing(path);
      await _reCopyIfStale(path);
      final db = await openDatabase(path, version: 1);
      if (await _verseCount(db) > 0) return db;
      // Present but empty/corrupt -> fall through and re-copy.
      await db.close();
    } catch (_) {
      // Missing directory, corrupt file, partial copy: re-copy below.
    }

    await _copyAsset(path, overwrite: true);
    await _writeStamp();
    return openDatabase(path, version: 1);
  }

  /// Re-copies the bundled database when the install's stamp is older than
  /// [dbContentVersion]. Runs before openDatabase so the new schema is what
  /// gets opened. Best-effort: any failure keeps the existing file.
  static Future<void> _reCopyIfStale(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_stampKey) ?? 1;
      if (current >= dbContentVersion) return;
      await _copyAsset(path, overwrite: true);
      await prefs.setInt(_stampKey, dbContentVersion);
    } catch (_) {
      // Stale-copy detection is an optimisation; never block start-up.
    }
  }

  static Future<void> _writeStamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_stampKey, dbContentVersion);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<int> _verseCount(Database db) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM verses');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  static Future<void> _copyAssetIfMissing(String path) async {
    if (await File(path).exists()) return;
    await _copyAsset(path, overwrite: false);
  }

  static Future<void> _copyAsset(String path,
      {required bool overwrite}) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (overwrite && await file.exists()) {
      await file.delete();
    }
    final data = await rootBundle.load(assetPath);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  /// Index of today's row so content rotates once per day.
  static int _dayOfYear([DateTime? now]) {
    final today = now ?? DateTime.now();
    return today.difference(DateTime(today.year, 1, 1)).inDays;
  }

  /// Picks today's row of [table] from a **no-repeat rotation**.
  ///
  /// The table's ids are shuffled with a deterministic per-table order (seeded
  /// by the table name, stable for a given content set), then the deck is
  /// sliced by an epoch counter that advances once per calendar day. A row is
  /// therefore shown exactly once every `n` days before the deck restarts —
  /// no repeats until every other row has had its turn. The epoch lives in the
  /// bundled `shuffle_state` table so it is shared across devices and
  /// re-installs.
  ///
  /// `forceSeed` (the «change content» button) shifts the deck start by one
  /// *within the same day* and immediately re-shuffles with a new random seed,
  /// so the user always sees fresh cards without breaking the daily cadence.
  static Future<Map<String, dynamic>?> _pickDaily(
      Database db, String table,
      {bool forceSeed = false}) async {
    final rows = await db.query(table, orderBy: 'id');
    if (rows.isEmpty) return null;

    final ids = rows.map((r) => (r['id'] as num).toInt()).toList();

    // Load (or create) the rotation state row for this table.
    final stateRows =
        await db.query('shuffle_state', where: 'table_name = ?', whereArgs: [table]);
    int epoch = 0;
    int seed = _stableSeed(table);
    if (stateRows.isNotEmpty) {
      final shown = (stateRows.first['shown_ids'] as String?) ?? '';
      final parsed = int.tryParse(shown);
      if (parsed != null && parsed >= 0) epoch = parsed;
      final storedSeed = (stateRows.first['last_index'] as num?)?.toInt();
      if (storedSeed != null && storedSeed > 0) seed = storedSeed;
      if (forceSeed) {
        seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
        epoch += 1; // next card in the deck, same-day override
      }
      await db.update(
        'shuffle_state',
        {'shown_ids': epoch.toString(), 'last_index': seed},
        where: 'table_name = ?',
        whereArgs: [table],
      );
    } else {
      // Persian day counts from Saturday; any stable day-based epoch works.
      epoch = _dayOfYear();
      if (forceSeed) {
        seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
        epoch += 1;
      }
      await db.insert('shuffle_state',
          {'table_name': table, 'shown_ids': epoch.toString(), 'last_index': seed});
    }

    final deck = _shuffledIds(ids, seed);
    final pickedId = deck[epoch % deck.length];
    for (final r in rows) {
      if ((r['id'] as num).toInt() == pickedId) return r;
    }
    return rows.first;
  }

  /// Deterministic seed per table (stable across launches for the same content).
  static int _stableSeed(String table) {
    var h = 0x811c9dc5;
    for (final code in table.codeUnits) {
      h = (h ^ code) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  /// Fisher–Yates shuffle of [ids] with [seed]; returns a new list.
  static List<int> _shuffledIds(List<int> ids, int seed) {
    final list = List<int>.of(ids);
    if (list.length < 2) return list;
    var state = seed & 0x7fffffff;
    int nextRandom(int max) {
      // xorshift32: small, fast, deterministic.
      var x = state;
      x ^= x << 13;
      x &= 0x7fffffff;
      x ^= x >> 17;
      x ^= x << 5;
      x &= 0x7fffffff;
      state = x;
      return x % max;
    }

    for (var i = list.length - 1; i > 0; i--) {
      final j = nextRandom(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  /// Forces a fresh random pick for every daily slot and returns the new
  /// daily selection. Wired to the «تغییر محتوا» button on the home tab.
  static Future<Map<String, dynamic>?> getDailyContentShuffled() {
    return _getDailyContentImpl(forceSeed: true);
  }

  /// Today's selection across all content tables. Returns `null` on failure so
  /// the caller can show a retry UI.
  static Future<Map<String, dynamic>?> getDailyContent() =>
      _getDailyContentImpl();

  static Future<Map<String, dynamic>?> _getDailyContentImpl(
      {bool forceSeed = false}) async {
    try {
      final db = await database;

      // Persian week starts on Saturday; DateTime.weekday is Mon=1..Sun=7.
      const daysFa = [
        'شنبه',
        'یکشنبه',
        'دوشنبه',
        'سه‌شنبه',
        'چهارشنبه',
        'پنجشنبه',
        'جمعه',
      ];
      final dayName = daysFa[(DateTime.now().weekday + 1) % 7];
      var zekrRows =
          await db.query('zekr', where: 'day = ?', whereArgs: [dayName]);
      if (zekrRows.isEmpty) {
        zekrRows = await db.query('zekr', limit: 1);
      }

      return {
        'verse': await _pickDaily(db, 'verses', forceSeed: forceSeed),
        'hadith': await _pickDaily(db, 'hadiths', forceSeed: forceSeed),
        'nahj': await _pickDaily(db, 'nahj_wisdoms', forceSeed: forceSeed),
        'martyr': await _pickDaily(db, 'martyrs', forceSeed: forceSeed),
        'zekr': zekrRows.isNotEmpty ? zekrRows.first : null,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllVerses() =>
      _all('verses');

  static Future<List<Map<String, dynamic>>> getAllHadiths() =>
      _all('hadiths');

  static Future<List<Map<String, dynamic>>> getAllMartyrs() =>
      _all('martyrs');

  static Future<List<Map<String, dynamic>>> getAllNahj() =>
      _all('nahj_wisdoms');

  /// Rows for the dhikr counter: title, arabic, benefits, instruction,
  /// source and kind (salawat | dua). The salawat rows come first.
  static Future<List<Map<String, dynamic>>> getAllSalawat() async {
    final db = await database;
    return db.query('salawat', orderBy: 'kind DESC, id');
  }

  static Future<List<Map<String, dynamic>>> _all(String table) async {
    final db = await database;
    return db.query(table);
  }
}
