import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_themed.dart';

void main() {
  testWidgets('shows the band, the sheet and the buddy over their seam', (
    tester,
  ) async {
    await tester.pumpThemed(
      const BrandBandLayout(
        band: SizedBox(height: 200, child: Text('band')),
        sheet: Text('sheet'),
      ),
    );

    final sheetTop = tester.getTopLeft(find.text('sheet')).dy;
    final buddy = tester.getRect(find.byType(Buddy));

    expect(find.text('band'), findsOneWidget);
    expect(buddy.top, lessThan(sheetTop));
    expect(buddy.bottom, greaterThan(sheetTop));
  });
}
