import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  testWidgets('shows its texts and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpThemed(
      OptionCard(
        title: 'Euro',
        subtitle: 'EUR',
        trailing: const Text('€'),
        selected: false,
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.text('Euro'));

    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('€'), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('tells screen readers whether it is selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpThemed(
      OptionCard(title: 'Monday', selected: true, onTap: () {}),
    );

    expect(
      tester.getSemantics(find.byType(OptionCard)),
      matchesSemantics(
        label: 'Monday',
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}
