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

  /// Short excerpt made for notification bodies. Populated only for martyr
  /// wills (column `notif_excerpt`); when present the notification system
  /// prefers it over the full [persian] text.
  final String? notifPersian;

  /// Stable identity of the database row this item came from, formatted as
  /// `<table>:<id>` (`verses:17`, `martyrs:3`, …). Populated by
  /// `ContentRepository`'s row mappers.
  ///
  /// It travels in the notification payload so a tap can reopen this exact card
  /// (see `NotificationService.onNotificationOpen`). Null for content that has
  /// no row behind it — placeholders and hand-built items.
  final String? uid;

  const DailyContent({
    required this.title,
    this.arabic = '',
    required this.persian,
    this.source = '',
    this.note = '',
    this.notifPersian,
    this.uid,
  });

  bool get hasArabic => arabic.trim().isNotEmpty;
  bool get hasPersian => persian.trim().isNotEmpty;
  bool get hasSource => source.trim().isNotEmpty;
  bool get hasNote => note.trim().isNotEmpty;
}
