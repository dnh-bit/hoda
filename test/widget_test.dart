import 'package:flutter_test/flutter_test.dart';
import 'package:hoda/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HodaApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HodaApp), findsOneWidget);
  });
}
