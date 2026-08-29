import 'dart:convert';

import 'package:flutter/material.dart' show TimeOfDay;

import '../utils/fa_num.dart';

/// One user-managed daily notification.
///
/// Hoda keeps up to [maxCount] of these; each one is armed as its own plugin
/// notification whose id is [notificationId], so schedules can be cancelled and
/// re-armed individually. The whole list is persisted as a JSON array in
/// SharedPreferences (see `NotificationService`).
class NotificationSchedule {
  /// Hard cap on how many daily notifications a user may create.
  static const int maxCount = 5;

  /// Plugin notification ids are `_baseNotificationId + id`, i.e. 1000..1004.
  static const int baseNotificationId = 1000;

  /// The content types a schedule may pick, in UI order.
  static const List<String> types = <String>[
    'random',
    'verse',
    'hadith',
    'martyr',
    'nahj',
  ];

  /// Stable slot in 0..[maxCount]-1. Also drives [notificationId].
  final int id;
  final bool enabled;
  final int hour;
  final int minute;

  /// One of [types].
  final String type;

  const NotificationSchedule({
    required this.id,
    this.enabled = true,
    this.hour = 8,
    this.minute = 0,
    this.type = 'random',
  });

  /// Unique plugin notification id for this schedule.
  int get notificationId => baseNotificationId + id;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  /// Minutes since midnight — used for sorting and duplicate detection.
  int get minutesOfDay => hour * 60 + minute;

  /// `۰۸:۳۰`
  String get timeLabelFa => FaNum.time(hour, minute);

  String get typeLabelFa => labelForType(type);

  NotificationSchedule copyWith({
    int? id,
    bool? enabled,
    int? hour,
    int? minute,
    String? type,
  }) {
    return NotificationSchedule(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      type: normalizeType(type ?? this.type),
    );
  }

  NotificationSchedule withTime(TimeOfDay value) =>
      copyWith(hour: value.hour, minute: value.minute);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'type': normalizeType(type),
      };

  /// Tolerant of anything SharedPreferences may hand back: missing keys, string
  /// numbers and out-of-range values all normalise instead of throwing.
  factory NotificationSchedule.fromJson(Map<dynamic, dynamic> json) {
    return NotificationSchedule(
      id: _int(json['id'], 0) % maxCount,
      enabled: json['enabled'] == true,
      hour: _int(json['hour'], 8) % 24,
      minute: _int(json['minute'], 0) % 60,
      type: normalizeType(json['type']?.toString()),
    );
  }

  static int _int(Object? value, int fallback) {
    if (value is int) return value.abs();
    if (value is num) return value.toInt().abs();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed?.abs() ?? fallback;
  }

  /// Falls back to `random` for unknown/legacy type strings.
  static String normalizeType(String? value) =>
      types.contains(value) ? value! : 'random';

  static String labelForType(String type) {
    switch (type) {
      case 'verse':
        return 'آیه قرآن';
      case 'hadith':
        return 'حدیث معصومین';
      case 'martyr':
        return 'وصیت شهید';
      case 'nahj':
        return 'حکمت نهج‌البلاغه';
      default:
        return 'تصادفی (گزیده روز)';
    }
  }

  /// Short label for chips and notification sub-headers.
  static String shortLabelForType(String type) {
    switch (type) {
      case 'verse':
        return 'آیه';
      case 'hadith':
        return 'حدیث';
      case 'martyr':
        return 'وصیت شهید';
      case 'nahj':
        return 'نهج‌البلاغه';
      default:
        return 'تصادفی';
    }
  }

  // ---------------- list helpers ----------------

  /// Sorted by fire time; the copy is safe to hand to the UI.
  static List<NotificationSchedule> sorted(
      List<NotificationSchedule> schedules) {
    final list = List<NotificationSchedule>.of(schedules);
    list.sort((a, b) {
      final byTime = a.minutesOfDay.compareTo(b.minutesOfDay);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return list;
  }

  /// Lowest unused slot, or null when the list is already full.
  static int? nextFreeId(List<NotificationSchedule> schedules) {
    for (var id = 0; id < maxCount; id++) {
      if (!schedules.any((s) => s.id == id)) return id;
    }
    return null;
  }

  /// True when another schedule already fires at the same minute.
  static bool hasTimeClash(
    List<NotificationSchedule> schedules,
    NotificationSchedule candidate,
  ) {
    return schedules.any(
      (s) => s.id != candidate.id && s.minutesOfDay == candidate.minutesOfDay,
    );
  }

  static String encodeList(List<NotificationSchedule> schedules) =>
      jsonEncode(schedules.map((s) => s.toJson()).toList());

  /// Reverse of [encodeList]. Returns an empty list for anything unparsable,
  /// drops duplicate ids and caps the result at [maxCount].
  static List<NotificationSchedule> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NotificationSchedule>[];
      final result = <NotificationSchedule>[];
      final seen = <int>{};
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final schedule = NotificationSchedule.fromJson(entry);
        if (!seen.add(schedule.id)) continue;
        result.add(schedule);
        if (result.length >= maxCount) break;
      }
      return result;
    } catch (_) {
      return const <NotificationSchedule>[];
    }
  }

  @override
  String toString() =>
      'NotificationSchedule(#$id, ${enabled ? 'on' : 'off'}, '
      '$hour:$minute, $type)';
}
