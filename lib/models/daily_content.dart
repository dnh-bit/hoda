/// A single piece of spiritual content shown in cards and detail views.
///
/// [arabic] holds the original Arabic text (rendered with the Arabic font),
/// [persian] holds the Farsi translation / body (rendered with Vazirmatn).
class DailyContent {
  final String title;
  final String arabic;
  final String persian;
  final String source;

  /// Optional extra note (e.g. place/year for a martyr, translator for Nahj).
  final String note;

  const DailyContent({
    required this.title,
    this.arabic = '',
    required this.persian,
    this.source = '',
    this.note = '',
  });

  bool get hasArabic => arabic.trim().isNotEmpty;
  bool get hasPersian => persian.trim().isNotEmpty;
  bool get hasSource => source.trim().isNotEmpty;
  bool get hasNote => note.trim().isNotEmpty;
}
