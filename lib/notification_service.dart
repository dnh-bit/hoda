import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _keyEnabled = 'hoda_notif_enabled';
  static const String _keyHour = 'hoda_notif_hour';
  static const String _keyMinute = 'hoda_notif_minute';
  static const String _keyType = 'hoda_notif_type'; // verse, hadith, martyr, nahj, random

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_keyHour) ?? 8;
    final m = prefs.getInt(_keyMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<String> getType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyType) ?? 'random';
  }

  static Future<void> saveSettings({
    required bool enabled,
    required TimeOfDay time,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
    await prefs.setString(_keyType, type);
  }
}
