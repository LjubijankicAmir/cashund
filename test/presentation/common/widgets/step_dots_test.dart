import 'package:cashund/presentation/common/widgets/step_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  testWidgets('draws one dot per step with the current one wider', (
    tester,
  ) async {
    await tester.pumpThemed(
      const Center(child: StepDots(count: 4, current: 1)),
    );

    final dots = find.descendant(
      of: find.byType(StepDots),
      matching: find.byType(AnimatedContainer),
    );
    final widths = [
      for (final dot in dots.evaluate())
        tester.getSize(find.byWidget(dot.widget)).width,
    ];

    expect(widths, [8, 22, 8, 8]);
  });
}
