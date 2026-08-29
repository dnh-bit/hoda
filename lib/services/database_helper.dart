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

  /// Picks one row of [table] based on the day of the year.
  static Future<Map<String, dynamic>?> _pickDaily(
      Database db, String table) async {
    final rows = await db.query(table);
    if (rows.isEmpty) return null;
    return rows[_dayOfYear() % rows.length];
  }

  /// Today's selection across all content tables. Returns `null` on failure so
  /// the caller can show a retry UI.
  static Future<Map<String, dynamic>?> getDailyContent() async {
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
        'verse': await _pickDaily(db, 'verses'),
        'hadith': await _pickDaily(db, 'hadiths'),
        'nahj': await _pickDaily(db, 'nahj_wisdoms'),
        'martyr': await _pickDaily(db, 'martyrs'),
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
