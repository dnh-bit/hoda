import '../models/daily_content.dart';
import '../utils/fa_num.dart';
import 'database_helper.dart';

/// Everything the home screen needs in a single immutable snapshot.
class HodaContent {
  final DailyContent? dailyVerse;
  final DailyContent? dailyHadith;
  final DailyContent? dailyMartyr;
  final DailyContent? dailyNahj;
  final DailyContent? dailyZekr;
  final List<DailyContent> verses;
  final List<DailyContent> hadiths;
  final List<DailyContent> martyrs;
  final List<DailyContent> nahj;

  const HodaContent({
    this.dailyVerse,
    this.dailyHadith,
    this.dailyMartyr,
    this.dailyNahj,
    this.dailyZekr,
    this.verses = const [],
    this.hadiths = const [],
    this.martyrs = const [],
    this.nahj = const [],
  });

  bool get isEmpty =>
      verses.isEmpty && hadiths.isEmpty && martyrs.isEmpty && nahj.isEmpty;

  HodaContent withLists({
    required List<DailyContent> verses,
    required List<DailyContent> hadiths,
    required List<DailyContent> martyrs,
    required List<DailyContent> nahj,
  }) {
    return HodaContent(
      dailyVerse: dailyVerse,
      dailyHadith: dailyHadith,
      dailyMartyr: dailyMartyr,
      dailyNahj: dailyNahj,
      dailyZekr: dailyZekr,
      verses: verses,
      hadiths: hadiths,
      martyrs: martyrs,
      nahj: nahj,
    );
  }

  /// Today's items in a fixed order, used for the "random" notification type.
  List<DailyContent> get dailyItems => <DailyContent>[
        if (dailyVerse != null) dailyVerse!,
        if (dailyHadith != null) dailyHadith!,
        if (dailyMartyr != null) dailyMartyr!,
        if (dailyNahj != null) dailyNahj!,
      ];
}

/// Maps raw database rows onto [DailyContent] models.
///
/// Keeping the mapping here means screens never touch sqflite rows.
class ContentRepository {
  ContentRepository._();

  static String _s(Object? value) => value?.toString().trim() ?? '';

  static DailyContent verseFrom(Map<String, dynamic> row, {String? title}) {
    final ref = _s(row['ref']).isEmpty ? _s(row['source']) : _s(row['ref']);
    return DailyContent(
      title: title ?? (ref.isEmpty ? 'آیه قرآن' : ref),
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: ref.isEmpty ? 'قرآن کریم' : ref,
    );
  }

  static DailyContent hadithFrom(Map<String, dynamic> row, {String? title}) {
    return DailyContent(
      title: title ?? 'حدیث',
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: _s(row['source']),
    );
  }

  static DailyContent nahjFrom(Map<String, dynamic> row, {String? title}) {
    final number = _s(row['number']);
    return DailyContent(
      title: title ??
          (number.isEmpty ? 'حکمت' : 'حکمت ${FaNum.digits(number)}'),
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: 'نهج‌البلاغه',
      note: _s(row['translator']).isEmpty
          ? ''
          : 'ترجمه: ${_s(row['translator'])}',
    );
  }

  static DailyContent martyrFrom(Map<String, dynamic> row, {String? title}) {
    final name = _s(row['name']);
    final year = _s(row['year']);
    final place = _s(row['place']);
    final meta = [place, year].where((e) => e.isNotEmpty).join(' • ');
    return DailyContent(
      title: title ?? (name.isEmpty ? 'وصیت شهید' : name),
      persian: _s(row['excerpt']),
      source: name,
      note: meta,
    );
  }

  static DailyContent zekrFrom(Map<String, dynamic> row) {
    final day = _s(row['day']);
    final amal = _s(row['amal'])
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => '• $e')
        .join('\n');
    final note = [amal, _s(row['note'])].where((e) => e.isNotEmpty).join('\n\n');
    return DailyContent(
      title: day.isEmpty ? 'ذکر روز' : 'ذکر روز $day',
      arabic: _s(row['zekr_arabic']),
      persian: _s(row['zekr_farsi']),
      source: 'اعمال روز',
      note: note,
    );
  }

  /// Loads only today's selection (cheap enough for the notification engine).
  static Future<HodaContent> loadDaily() async {
    final daily = await DatabaseHelper.getDailyContent();

    Map<String, dynamic>? pick(String key) {
      final value = daily?[key];
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    }

    final verseRow = pick('verse');
    final hadithRow = pick('hadith');
    final martyrRow = pick('martyr');
    final nahjRow = pick('nahj');
    final zekrRow = pick('zekr');

    return HodaContent(
      dailyVerse:
          verseRow == null ? null : verseFrom(verseRow, title: 'آیه روز'),
      dailyHadith:
          hadithRow == null ? null : hadithFrom(hadithRow, title: 'حدیث روز'),
      dailyMartyr:
          martyrRow == null ? null : martyrFrom(martyrRow, title: 'وصیت شهید'),
      dailyNahj: nahjRow == null ? null : nahjFrom(nahjRow, title: 'حکمت روز'),
      dailyZekr: zekrRow == null ? null : zekrFrom(zekrRow),
    );
  }

  /// Loads the daily selection plus the full browsing lists.
  static Future<HodaContent> loadAll() async {
    final daily = await loadDaily();
    final verseRows = await DatabaseHelper.getAllVerses();
    final hadithRows = await DatabaseHelper.getAllHadiths();
    final martyrRows = await DatabaseHelper.getAllMartyrs();
    final nahjRows = await DatabaseHelper.getAllNahj();

    return daily.withLists(
      verses: verseRows.map((r) => verseFrom(r)).toList(),
      hadiths: hadithRows.map((r) => hadithFrom(r)).toList(),
      martyrs: martyrRows.map((r) => martyrFrom(r)).toList(),
      nahj: nahjRows.map((r) => nahjFrom(r)).toList(),
    );
  }
}
