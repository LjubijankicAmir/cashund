import 'package:cashund/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CashundApp renders', (tester) async {
    await tester.pumpWidget(const CashundApp());

    expect(find.text('Cashund'), findsOneWidget);
  });
}
