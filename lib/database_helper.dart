import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'hoda.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    try {
      final file = File(path);
      if (!await file.exists()) {
        final data = await rootBundle.load('assets/hoda.db');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      }
      // Verify the copied db is readable; if corrupt, re-copy
      final test = await openDatabase(path, version: 1);
      final count = (await test.rawQuery('SELECT COUNT(*) as c FROM verses')).first['c'] as int;
      await test.close();
      if (count == 0) throw Exception('db empty, re-copying');
      return await openDatabase(path, version: 1);
    } catch (e) {
      // Corrupt or missing: force fresh copy
      final file = File(path);
      if (await file.exists()) await file.delete();
      final data = await rootBundle.load('assets/hoda.db');
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      return await openDatabase(path, version: 1);
    }
  }

  /// Pick one row by day-of-year so content rotates daily.
  static Future<List<Map<String, dynamic>>> _pickDaily(
      Database db, String table) async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final rows = await db.query(table);
    if (rows.isEmpty) return [];
    return [rows[dayOfYear % rows.length]];
  }

  static Future<Map<String, dynamic>?> getDailyContent() async {
    try {
      final db = await database;

      final verseRows = await _pickDaily(db, 'verses');
      final hadithRows = await _pickDaily(db, 'hadiths');
      final nahjRows = await _pickDaily(db, 'nahj_wisdoms');
      final martyrRows = await _pickDaily(db, 'martyrs');

      // Zekr by Persian weekday name
      const daysFa = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
      final dayIndex = DateTime.now().weekday % 7;
      var zekrRows = await db.query('zekr', where: 'day = ?', whereArgs: [daysFa[dayIndex]]);
      zekrRows = zekrRows.isNotEmpty ? zekrRows : await db.query('zekr', limit: 1);

      return {
        'verse': verseRows.isNotEmpty ? verseRows.first : null,
        'hadith': hadithRows.isNotEmpty ? hadithRows.first : null,
        'nahj': nahjRows.isNotEmpty ? nahjRows.first : null,
        'martyr': martyrRows.isNotEmpty ? martyrRows.first : null,
        'zekr': zekrRows.isNotEmpty ? zekrRows.first : null,
      };
    } catch (e) {
      return null; // caller shows fallback UI
    }
  }

  static Future<List<Map<String, dynamic>>> getAllVerses() async {
    final db = await database;
    return await db.query('verses');
  }

  static Future<List<Map<String, dynamic>>> getAllHadiths() async {
    final db = await database;
    return await db.query('hadiths');
  }

  static Future<List<Map<String, dynamic>>> getAllMartyrs() async {
    final db = await database;
    return await db.query('martyrs');
  }

  static Future<List<Map<String, dynamic>>> getAllNahj() async {
    final db = await database;
    return await db.query('nahj_wisdoms');
  }
}
