import 'package:flutter_test/flutter_test.dart';
import 'package:pcrm_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PCRMApp());
    expect(find.byType(PCRMApp), findsOneWidget);
  });
}
