import '../models/daily_content.dart';

/// Persian/Arabic aware text matching for the search screen.
///
/// Users type «الله» or «نماز» without diacritics, with Arabic yeh/kaf, or with
/// Persian digits — none of which match the database text byte for byte. Every
/// string is therefore folded to a canonical form before comparison:
/// vocalisation marks and tatweel are dropped, Arabic letter variants map onto
/// their Persian counterparts, ZWNJ becomes a space and Persian/Arabic digits
/// become ASCII.
class FaSearch {
  FaSearch._();

  static final RegExp _marks = RegExp(
    '[\u064B-\u065F\u0670\u0640\u06D6-\u06ED\u08F0-\u08F3]',
  );
  static final RegExp _spaces = RegExp(r'\s+');

  static const Map<String, String> _letters = <String, String>{
    'ي': 'ی',
    'ى': 'ی',
    'ئ': 'ی',
    'ك': 'ک',
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ء': '',
    'ة': 'ه',
    'ۀ': 'ه',
    'ؤ': 'و',
  };

  static const Map<String, String> _digits = <String, String>{
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };

  /// Canonical, comparable form of [input].
  static String fold(String input) {
    String out = input.replaceAll(_marks, '').replaceAll('\u200c', ' ');
    _letters.forEach((String from, String to) {
      out = out.replaceAll(from, to);
    });
    _digits.forEach((String from, String to) {
      out = out.replaceAll(from, to);
    });
    return out.replaceAll(_spaces, ' ').trim().toLowerCase();
  }

  /// All the searchable text of a content item, folded once.
  static String haystack(DailyContent content) => fold(<String>[
        content.title,
        content.arabic,
        content.persian,
        content.source,
        content.note,
        content.tafsir ?? '',
        content.family ?? '',
      ].join(' '));

  /// True when every whitespace-separated token of [query] appears in [content].
  static bool matches(DailyContent content, String query) {
    final String q = fold(query);
    if (q.isEmpty) return true;
    final String hay = haystack(content);
    for (final String token in q.split(' ')) {
      if (token.isEmpty) continue;
      if (!hay.contains(token)) return false;
    }
    return true;
  }

  static List<DailyContent> filter(
    List<DailyContent> items,
    String query, {
    int? limit,
  }) {
    final String q = fold(query);
    if (q.isEmpty) return items;
    final List<String> tokens =
        q.split(' ').where((String t) => t.isNotEmpty).toList();
    final List<DailyContent> out = <DailyContent>[];
    for (final DailyContent item in items) {
      final String hay = haystack(item);
      bool ok = true;
      for (final String token in tokens) {
        if (!hay.contains(token)) {
          ok = false;
          break;
        }
      }
      if (ok) {
        out.add(item);
        if (limit != null && out.length >= limit) break;
      }
    }
    return out;
  }
}
