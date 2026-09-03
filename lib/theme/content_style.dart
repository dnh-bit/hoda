import 'package:flutter/material.dart';

import '../models/daily_content.dart';
import 'hoda_theme.dart';

/// The five content families Hoda ships.
enum ContentKind { verse, hadith, nahj, martyr, zekr }

/// Visual identity of a content family: label, icon and a light/dark hue.
///
/// Every card, chip, list header, filter and detail page derives its colour and
/// icon from here, so a verse looks like a verse everywhere in the app and the
/// user learns the language of the UI after one screen.
@immutable
class ContentStyle {
  const ContentStyle({
    required this.kind,
    required this.label,
    required this.plural,
    required this.icon,
    required this.iconOutlined,
    required this.lightColor,
    required this.darkColor,
  });

  final ContentKind kind;

  /// Singular Persian label («آیه»).
  final String label;

  /// Plural / section label («آیات قرآن»).
  final String plural;

  final IconData icon;
  final IconData iconOutlined;
  final Color lightColor;
  final Color darkColor;

  Color color(bool isDark) => isDark ? darkColor : lightColor;

  Color colorOf(BuildContext context) =>
      color(HodaPalette.of(context).isDark);

  static const ContentStyle verse = ContentStyle(
    kind: ContentKind.verse,
    label: 'آیه',
    plural: 'آیات قرآن',
    icon: Icons.menu_book,
    iconOutlined: Icons.menu_book_outlined,
    lightColor: HodaColors.goldDeep,
    darkColor: HodaColors.goldLight,
  );

  static const ContentStyle hadith = ContentStyle(
    kind: ContentKind.hadith,
    label: 'حدیث',
    plural: 'احادیث معصومین',
    icon: Icons.format_quote,
    iconOutlined: Icons.format_quote_outlined,
    lightColor: HodaColors.deepTurquoise,
    darkColor: HodaColors.turquoiseLight,
  );

  static const ContentStyle nahj = ContentStyle(
    kind: ContentKind.nahj,
    label: 'حکمت',
    plural: 'حکمت‌های نهج‌البلاغه',
    icon: Icons.auto_stories,
    iconOutlined: Icons.auto_stories_outlined,
    lightColor: HodaColors.forestGreen,
    darkColor: HodaColors.mint,
  );

  static const ContentStyle martyr = ContentStyle(
    kind: ContentKind.martyr,
    label: 'وصیت',
    plural: 'وصایای شهدا',
    icon: Icons.volunteer_activism,
    iconOutlined: Icons.volunteer_activism_outlined,
    lightColor: HodaColors.clay,
    darkColor: HodaColors.clayLight,
  );

  static const ContentStyle zekr = ContentStyle(
    kind: ContentKind.zekr,
    label: 'ذکر روز',
    plural: 'ذکر و اعمال روز',
    icon: Icons.auto_awesome,
    iconOutlined: Icons.auto_awesome_outlined,
    lightColor: HodaColors.turquoise,
    darkColor: HodaColors.turquoiseGlow,
  );

  static const List<ContentStyle> all = <ContentStyle>[
    verse,
    hadith,
    nahj,
    martyr,
    zekr,
  ];

  static ContentStyle of(ContentKind kind) {
    switch (kind) {
      case ContentKind.verse:
        return verse;
      case ContentKind.hadith:
        return hadith;
      case ContentKind.nahj:
        return nahj;
      case ContentKind.martyr:
        return martyr;
      case ContentKind.zekr:
        return zekr;
    }
  }

  /// Resolves the family from a [DailyContent.uid] (`<table>:<id>`), falling
  /// back to [verse] for hand-built placeholders.
  static ContentStyle forUid(String? uid) {
    final String table = (uid ?? '').split(':').first;
    switch (table) {
      case 'verses':
        return verse;
      case 'hadiths':
        return hadith;
      case 'nahj_wisdoms':
        return nahj;
      case 'martyrs':
        return martyr;
      case 'zekr':
        return zekr;
      default:
        return verse;
    }
  }

  static ContentStyle forContent(DailyContent content) => forUid(content.uid);

  /// The notification payload type string used by `NotificationService`.
  String get payloadType {
    switch (kind) {
      case ContentKind.verse:
        return 'verse';
      case ContentKind.hadith:
        return 'hadith';
      case ContentKind.nahj:
        return 'nahj';
      case ContentKind.martyr:
        return 'martyr';
      case ContentKind.zekr:
        return 'random';
    }
  }
}
