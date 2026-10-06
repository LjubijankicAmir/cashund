import 'package:cashund/app.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(configureDependencies);
  tearDown(getIt.reset);

  testWidgets('CashundApp opens on the home screen', (tester) async {
    await tester.pumpWidget(const CashundApp());
    await tester.pumpAndSettle();

    expect(find.text('Cashund'), findsOneWidget);
  });
}
