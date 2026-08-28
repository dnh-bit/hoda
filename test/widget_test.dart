import 'package:flutter_test/flutter_test.dart';
import 'package:hoda/app.dart';
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
}
