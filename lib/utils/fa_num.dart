/// Helpers for rendering numbers, times and dates with Persian digits.
class FaNum {
  FaNum._();

  static const List<String> _persianDigits = <String>[
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  /// Replaces every ASCII digit in [input] with its Persian counterpart.
  static String digits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_persianDigits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String number(int value) => digits(value.toString());

  /// `08:05` -> `۰۸:۰۵`
  static String time(int hour, int minute) => digits(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );

  static const List<String> _weekDaysFa = <String>[
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  /// Persian weekday name for [date].
  ///
  /// The Persian week starts on Saturday while `DateTime.weekday` is
  /// Monday=1..Sunday=7, hence the `+1` shift.
  static String weekDay(DateTime date) => _weekDaysFa[(date.weekday + 1) % 7];

  /// A friendly Persian label: «امروز», «فردا» or the weekday name.
  static String relativeDay(DateTime target, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(target.year, target.month, target.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'امروز';
    if (diff == 1) return 'فردا';
    return weekDay(target);
  }
}
