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

  /// The item whose [DailyContent.uid] equals [uid], or null when this snapshot
  /// does not contain it.
  ///
  /// Used by the shell to open the exact card a notification was showing. The
  /// browsing lists are searched first on purpose: their items are the ones a
  /// tap on a card would open (same row, but titled «بقره ۲۵۵» instead of
  /// «آیه روز»). The daily picks are the fallback, which is what makes this
  /// work for `dailyZekr` too — it is not part of any list.
  DailyContent? findByUid(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    for (final list in <List<DailyContent>>[verses, hadiths, martyrs, nahj]) {
      for (final item in list) {
        if (item.uid == uid) return item;
      }
    }
    for (final item in <DailyContent?>[
      dailyVerse,
      dailyHadith,
      dailyMartyr,
      dailyNahj,
      dailyZekr,
    ]) {
      if (item != null && item.uid == uid) return item;
    }
    return null;
  }
}

/// Maps raw database rows onto [DailyContent] models.
///
/// Keeping the mapping here means screens never touch sqflite rows.
class ContentRepository {
  ContentRepository._();

  static String _s(Object? value) => value?.toString().trim() ?? '';

  /// Stable `<table>:<id>` identity for a row, or null when it cannot be
  /// derived.
  ///
  /// Every content table in `assets/hoda.db` (`verses`, `hadiths`,
  /// `nahj_wisdoms`, `martyrs`, `zekr`) has an `INTEGER PRIMARY KEY id`, and
  /// [DatabaseHelper] selects whole rows (`db.query(table)`), so `row['id']` is
  /// always present in practice — no `rowid AS id` alias is needed.
  ///
  /// The hash branch is a last resort for a future/rebuilt database whose table
  /// has no `id`: it keeps taps working within one app version, but it is *not*
  /// guaranteed stable across Dart SDK upgrades, so it must never become the
  /// normal path.
  static String? _uid(String table, Map<String, dynamic> row, String seed) {
    final id = _s(row['id']);
    if (id.isNotEmpty) return '$table:$id';
    final clean = seed.trim();
    if (clean.isEmpty) return null;
    return '$table:h${clean.hashCode.toRadixString(16)}';
  }

  static DailyContent verseFrom(Map<String, dynamic> row, {String? title}) {
    final ref = _s(row['ref']).isEmpty ? _s(row['source']) : _s(row['ref']);
    return DailyContent(
      title: title ?? (ref.isEmpty ? 'آیه قرآن' : ref),
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: ref.isEmpty ? 'قرآن کریم' : ref,
      uid: _uid('verses', row, '$ref|${_s(row['arabic'])}'),
    );
  }

  static DailyContent hadithFrom(Map<String, dynamic> row, {String? title}) {
    return DailyContent(
      title: title ?? 'حدیث',
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: _s(row['source']),
      uid: _uid(
        'hadiths',
        row,
        '${_s(row['source'])}|${_s(row['arabic'])}',
      ),
    );
  }

  static DailyContent nahjFrom(Map<String, dynamic> row, {String? title}) {
    final number = _s(row['number']);
    // «مفهوم (تفسیر)» — a short modern explanation of the wisdom. Empty when
    // the row predates the column or has none written for it.
    final tafsir = _s(row['tafsir']);
    return DailyContent(
      title: title ??
          (number.isEmpty ? 'حکمت' : 'حکمت ${FaNum.digits(number)}'),
      arabic: _s(row['arabic']),
      persian: _s(row['farsi']),
      source: 'نهج‌البلاغه',
      note: _s(row['translator']).isEmpty
          ? ''
          : 'ترجمه: ${_s(row['translator'])}',
      tafsir: tafsir.isEmpty ? null : tafsir,
      uid: _uid('nahj_wisdoms', row, '$number|${_s(row['arabic'])}'),
    );
  }

  static DailyContent martyrFrom(Map<String, dynamic> row, {String? title}) {
    final name = _s(row['name']);
    final year = _s(row['year']);
    final place = _s(row['place']);
    final meta = [place, year].where((e) => e.isNotEmpty).join(' • ');
    // `notif_excerpt` carries the short «فرازی از وصیت شهید» written for
    // notification bodies; null/empty falls back to the full will text.
    final notif = _s(row['notif_excerpt']);
    return DailyContent(
      title: title ?? (name.isEmpty ? 'وصیت شهید' : name),
      persian: _s(row['excerpt']),
      source: name,
      note: meta,
      notifPersian: notif.isEmpty ? null : notif,
      uid: _uid('martyrs', row, '$name|${_s(row['excerpt'])}'),
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
      uid: _uid('zekr', row, '$day|${_s(row['zekr_arabic'])}'),
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
