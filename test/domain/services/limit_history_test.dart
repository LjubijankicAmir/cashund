import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/services/limit_history.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 8);
  final weeks = LimitPeriod.week.rangesUpTo(
    today,
    weekStart: WeekStart.monday,
    count: 5,
  ); // Sep 7, 14, 21, 28 and Oct 5.

  test('amountFor uses the amount in force when each period started', () {
    final amounts = [
      LimitAmount(effectiveFrom: DateTime(2026, 9, 14), amountMinor: 8000),
      LimitAmount(effectiveFrom: DateTime(2026, 9, 28), amountMinor: 10000),
    ];

    expect(LimitAmount.amountFor(amounts, DateTime(2026, 9, 7)), isNull);
    expect(LimitAmount.amountFor(amounts, DateTime(2026, 9, 21)), 8000);
    expect(LimitAmount.amountFor(amounts, DateTime(2026, 10, 5)), 10000);
  });

  test('results add up each period’s days against its own amount', () {
    final results = LimitHistory.results(
      ranges: weeks,
      amounts: [
        LimitAmount(effectiveFrom: DateTime(2026, 9, 14), amountMinor: 10000),
      ],
      spentByDay: {
        DateTime(2026, 9, 8): 2000,
        DateTime(2026, 9, 15): 6000,
        DateTime(2026, 9, 19): 5000,
        DateTime(2026, 10, 6): 3000,
      },
    );

    expect([for (final r in results) r.spentMinor], [2000, 11000, 0, 0, 3000]);
    expect(
      [for (final r in results) r.amountMinor],
      [null, 10000, 10000, 10000, 10000],
    );
    expect(results[1].isOver, isTrue);
  });

  test('kept counts finished periods the limit existed for', () {
    final results = LimitHistory.results(
      ranges: weeks,
      amounts: [
        LimitAmount(effectiveFrom: DateTime(2026, 9, 14), amountMinor: 10000),
      ],
      spentByDay: {
        DateTime(2026, 9, 15): 12000,
        // The running week is over, but it doesn't count yet.
        DateTime(2026, 10, 6): 15000,
      },
    );

    expect(LimitHistory.kept(results, today: today), (kept: 2, of: 3));
  });
}
