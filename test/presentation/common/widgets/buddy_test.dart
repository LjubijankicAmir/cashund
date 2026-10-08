import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  testWidgets('draws the artwork for the expression at its proportions', (
    tester,
  ) async {
    await tester.pumpThemed(
      const Center(child: Buddy(expression: BuddyExpression.happy, width: 170)),
    );

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (picture.bytesLoader as SvgAssetLoader).assetName,
      'assets/buddy/biscuit-happy.svg',
    );
    expect(tester.getSize(find.byType(SvgPicture)), Buddy.artSize);
  });
}
