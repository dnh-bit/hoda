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

    final file = File(path);
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/hoda.db');
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes);
    }

    return await openDatabase(path, version: 1);
  }

  static Future<Map<String, dynamic>> getDailyContent() async {
    final db = await database;
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    final verseCount = (await db.rawQuery('SELECT COUNT(*) as c FROM verses')).first['c'] as int;
    final hadithCount = (await db.rawQuery('SELECT COUNT(*) as c FROM hadiths')).first['c'] as int;
    final nahjCount = (await db.rawQuery('SELECT COUNT(*) as c FROM nahj_wisdoms')).first['c'] as int;
    final martyrCount = (await db.rawQuery('SELECT COUNT(*) as c FROM martyrs')).first['c'] as int;

    final verse = (await db.query('verses', limit: 1, offset: dayOfYear % verseCount)).first;
    final hadith = (await db.query('hadiths', limit: 1, offset: dayOfYear % hadithCount)).first;
    final nahj = (await db.query('nahj_wisdoms', limit: 1, offset: dayOfYear % nahjCount)).first;
    final martyr = (await db.query('martyrs', limit: 1, offset: dayOfYear % martyrCount)).first;

    final daysFa = ['شنبه','یکشنبه','دوشنبه','سه‌شنبه','چهارشنبه','پنجشنبه','جمعه'];
    final dayIndex = today.weekday % 7;
    final zekrRows = await db.query('zekr', where: 'day = ?', whereArgs: [daysFa[dayIndex]]);
    final zekr = zekrRows.isNotEmpty ? zekrRows.first : (await db.query('zekr', limit: 1)).first;

    return {
      'verse': verse,
      'hadith': hadith,
      'nahj': nahj,
      'martyr': martyr,
      'zekr': zekr,
    };
  }

  static Future<List<Map<String, dynamic>>> getAllVerses() async {
    final db = await database;
    return await db.query('verses');
  }

  static Future<List<Map<String, dynamic>>> getAllHadiths() async {
    final db = await database;
    return await db.query('hadiths');
  }

  static Future<List<Map<String, dynamic>>> getAllNahj() async {
    final db = await database;
    return await db.query('nahj_wisdoms');
  }

  static Future<List<Map<String, dynamic>>> getAllMartyrs() async {
    final db = await database;
    return await db.query('martyrs');
  }

  static Future<List<Map<String, dynamic>>> getAllZekr() async {
    final db = await database;
    return await db.query('zekr');
  }

  static Future<List<Map<String, dynamic>>> getAllSalawat() async {
    final db = await database;
    return await db.query('salawat');
  }
}
