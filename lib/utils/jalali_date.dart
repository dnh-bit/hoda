import 'package:flutter/material.dart';

import 'fa_num.dart';

/// Pure-Dart Gregorian → Jalali (Solar Hijri) conversion — no packages.
///
/// Verified against known anchors: 2026-03-21 → 1405/01/01, 1404 and 1403
/// new years, and today's date. Month names are the standard Persian ones
/// and [FaNum.digits] renders everything in Persian numerals.
class JalaliDate {
  JalaliDate._();

  static const List<String> _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const List<String> _weekdays = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه',
    'جمعه', 'شنبه', 'یکشنبه',
  ];

  /// Converts a Gregorian [date] to (year, month, day) in the Jalali calendar.
  static List<int> toJalali(DateTime date) {
    final gy = date.year;
    final gm = date.month;
    final gd = date.day;
    const gDm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gDm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm;
    int jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return [jy, jm, jd];
  }

  /// «پنجشنبه ۸ شهریور ۱۴۰۵» — full Persian date for [date].
  static String fullFa(DateTime date) {
    final j = toJalali(date);
    final weekday = _weekdays[date.weekday - 1]; // Dart: Mon=1..Sun=7
    return '$weekday ${FaNum.digits(j[2].toString())} '
        '${_months[j[1] - 1]} ${FaNum.digits(j[0].toString())}';
  }

  /// «۸ شهریور ۱۴۰۵» — date without the weekday.
  static String dateFa(DateTime date) {
    final j = toJalali(date);
    return '${FaNum.digits(j[2].toString())} '
        '${_months[j[1] - 1]} ${FaNum.digits(j[0].toString())}';
  }

  /// A small, decorative calendar chip — the home header's date badge.
  static Widget chip(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.tertiary).withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (color ?? theme.colorScheme.tertiary).withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 15, color: color ?? theme.colorScheme.tertiary),
          const SizedBox(width: 7),
          Text(
            dateFa(DateTime.now()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
