import 'package:cashund/presentation/common/widgets/animated_buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  late BuddyController controller;

  setUp(() => controller = BuddyController());
  tearDown(() => controller.dispose());

  Buddy buddy(WidgetTester tester) => tester.widget<Buddy>(find.byType(Buddy));
  double lift(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find
          .ancestor(of: find.byType(Buddy), matching: find.byType(Transform))
          .first,
    );
    return transform.transform.getTranslation().y;
  }

  testWidgets('rests at its expression', (tester) async {
    await tester.pumpThemed(
      Center(child: AnimatedBuddy(controller: controller)),
    );

    expect(buddy(tester).expression, BuddyExpression.listening);
    expect(lift(tester), 0);
  });

  testWidgets('cheering turns it happy and lifts it, then it settles back', (
    tester,
  ) async {
    await tester.pumpThemed(
      Center(child: AnimatedBuddy(controller: controller)),
    );

    controller.cheer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(buddy(tester).expression, BuddyExpression.happy);
    expect(lift(tester), lessThan(0));

    await tester.pumpAndSettle();

    expect(buddy(tester).expression, BuddyExpression.listening);
    expect(lift(tester), 0);
  });

  testWidgets('stays still when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpThemed(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(child: AnimatedBuddy(controller: controller)),
      ),
    );

    controller.cheer();
    await tester.pump(const Duration(milliseconds: 100));

    expect(buddy(tester).expression, BuddyExpression.listening);
    expect(lift(tester), 0);
  });
}
