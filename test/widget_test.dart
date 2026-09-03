import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoda/app.dart';
import 'package:hoda/models/daily_content.dart';
import 'package:hoda/screens/settings_screen.dart';
import 'package:hoda/services/content_repository.dart';
import 'package:hoda/services/notification_service.dart';
import 'package:hoda/services/salawat_store.dart';
import 'package:hoda/utils/fa_num.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HodaApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HodaApp), findsOneWidget);
  });

  test('FaNum converts digits and times to Persian', () {
    expect(FaNum.number(2024), '۲۰۲۴');
    expect(FaNum.time(8, 5), '۰۸:۰۵');
    expect(FaNum.digits('حکمت 12'), 'حکمت ۱۲');
  });

  test('FaNum relative day labels', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(FaNum.relativeDay(DateTime(2026, 1, 10, 8), from: now), 'امروز');
    expect(FaNum.relativeDay(DateTime(2026, 1, 11, 8), from: now), 'فردا');
  });

  group('SalawatCounts', () {
    test('increment bumps today and total', () {
      const counts = SalawatCounts(today: 2, total: 41);
      final next = counts.incremented();
      expect(next.today, 3);
      expect(next.total, 42);
    });

    test('value equality keeps the AppBar badge from rebuilding', () {
      expect(const SalawatCounts(today: 1, total: 9),
          const SalawatCounts(today: 1, total: 9));
      expect(const SalawatCounts(today: 1, total: 9),
          isNot(const SalawatCounts(today: 1, total: 10)));
    });
  });

  group('notification payload', () {
    test('three-segment payload yields type and uid', () {
      const payload = 'random|verse|verses:12';
      expect(NotificationService.typeFromPayload(payload), 'verse');
      expect(NotificationService.uidFromPayload(payload), 'verses:12');
    });

    test('legacy two-segment payload still routes, without a uid', () {
      const payload = 'random|nahj';
      expect(NotificationService.typeFromPayload(payload), 'nahj');
      expect(NotificationService.uidFromPayload(payload), isNull);
    });

    test('empty payload routes nowhere', () {
      expect(NotificationService.typeFromPayload(null), isNull);
      expect(NotificationService.typeFromPayload(''), isNull);
      expect(NotificationService.uidFromPayload(null), isNull);
    });
  });

  group('HodaContent.findByUid', () {
    const verse = DailyContent(
      title: 'بقره ۲۵۵',
      persian: 'ترجمه',
      uid: 'verses:1',
    );
    const daily = DailyContent(
      title: 'حکمت روز',
      persian: 'متن',
      uid: 'nahj_wisdoms:7',
    );
    const content = HodaContent(
      dailyNahj: daily,
      verses: <DailyContent>[verse],
    );

    test('finds a list item by uid', () {
      expect(content.findByUid('verses:1'), same(verse));
    });

    test('falls back to the daily picks', () {
      expect(content.findByUid('nahj_wisdoms:7'), same(daily));
    });

    test('unknown or missing uid resolves to null', () {
      expect(content.findByUid('verses:999'), isNull);
      expect(content.findByUid(null), isNull);
      expect(content.findByUid(''), isNull);
    });
  });

  group('settings version const', () {
    test('kHodaVersionFa matches pubspec version', () {
      // Guards against the settings screen showing a stale version.
      // The const may carry a suffix («۰.۱.۵ بتا» for a beta build) — the
      // numeric prefix must still match pubspec's X.Y.Z.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final m =
          RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)').firstMatch(pubspec)!;
      final expected = '${FaNum.digits(m.group(1)!)}'
          '‏.${FaNum.digits(m.group(2)!)}'
          '‏.${FaNum.digits(m.group(3)!)}';
      // Compare only the numeric prefix; ignore ZWNJ and any suffix (بتا…).
      String strip(String s) => s
          .replaceAll('\u200c', '')
          .replaceAll('\u200f', '')
          .split(' ')
          .first;
      expect(strip(kHodaVersionFa), strip(expected));
    });
  });
}
