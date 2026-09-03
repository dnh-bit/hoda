# هُدا · Hoda

Offline Shia Islamic companion app for Android, built with Flutter: selected Quran
verses, hadiths of the Fourteen Infallibles, wills of martyrs, wisdoms of
Nahj al-Balagha, the dhikr of the day and a dhikr counter — all bundled in a
local SQLite database, with no network permission at all.

* Persian (fa-IR), fully right-to-left.
* No accounts, no analytics, no ads, no internet.
* Flutter 3.24.5 · Dart SDK ^3.5.4 · target `com.hoda.hoda`.

## v0.2.0 — the UI rebuild

Version 0.2.0 is a complete redesign of the presentation layer. The colour
identity (deep green · turquoise · gold · cream) is preserved; everything around
it was rebuilt as a proper design system. No new dependencies were added.

Highlights:

* **Design tokens** — colours, radii, spacing and motion live in
  `lib/theme/hoda_theme.dart` and are exposed through a `HodaPalette`
  `ThemeExtension`, so widgets never branch on light/dark themselves.
* **Islamic geometric ornament** — an eight-point star tessellation painted with
  a `CustomPainter` (`lib/widgets/hoda_pattern.dart`), used behind headers,
  scripture panels and the ambient page background. Zero image assets.
* **Content identity system** — `lib/theme/content_style.dart` gives every
  family (verse / hadith / wisdom / will / dhikr) one colour, one icon and one
  label, reused by cards, chips, the nav bar, the notification editor and search.
* **Dashboard home** — time-of-day greeting, Jalali date, live stat strip,
  today's content with family badges, and a quick-explore grid with item counts.
* **Floating pill nav bar** — `HodaNavBar`, animated and RTL-safe by
  construction (plain `Expanded` items, no mirrored offsets).
* **Unified search** — `lib/screens/search_screen.dart` with diacritic- and
  orthography-insensitive matching (`lib/utils/fa_search.dart`): «نماز» matches
  «نَماز», Arabic yeh/kaf fold onto Persian, Persian digits fold to ASCII.
* **Real bookmarks** — `FavoritesStore` persists uids; the favourites screen
  resolves them from the loaded snapshot, with type filters and clear-all.
* **Reading screen** — collapsing gradient header, framed scripture panel,
  collapsible «مفهوم», and a persistent text-size / justification control
  (`ReaderSettings`).
* **Dhikr counter** — progress ring with a daily goal, pulse feedback on every
  tap, graduated haptics, today/total stats and a −1 correction button.
* **Appearance** — light, dark or follow-system (`ThemeController`, migrating the
  old boolean preference).
* **Polish** — staggered entrance animations, press-scale feedback, shimmer
  skeletons instead of bare spinners, and clamped text scaling so large system
  fonts cannot break the layout.

## Project layout

```
lib/
  theme/        design tokens, ThemeData, content identity
  widgets/      reusable UI: cards, pattern, nav bar, app bar, motion, chips
  screens/      home shell + tabs, detail, search, favourites, counter, settings
  services/     database, content repository, notifications, stores
  models/       DailyContent, NotificationSchedule
  utils/        Persian digits, Jalali date, search folding, content actions
assets/
  hoda.db       bundled content database
  fonts/        Vazirmatn (UI), Lalezar (display), Amiri (Arabic scripture)
```

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

CI (`.github/workflows/build.yml`) builds a signed release APK on every push to
`main` and publishes it to GitHub Releases as `hoda-vX.Y.Z.apk`.

## Fonts & licences

Vazirmatn and Lalezar for Persian UI, Amiri (© Khaled Hosny) for Arabic
scripture — SIL Open Font License 1.1, full text in `assets/fonts/Amiri-OFL.txt`.
