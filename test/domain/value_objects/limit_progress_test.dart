import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday Oct 5 to Sunday Oct 11.
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  final limit = SpendingLimit(
    id: 1,
    period: LimitPeriod.week,
    currencyCode: 'USD',
    createdAt: DateTime(2026, 9),
    categoryId: 2,
  );

  LimitProgress spent(int spentMinor, {int amountMinor = 10000}) =>
      LimitProgress(
        limit: limit,
        range: week,
        amountMinor: amountMinor,
        spentMinor: spentMinor,
      );

  test('status turns near at 80% and over past 100%', () {
    expect(spent(7999).status, LimitStatus.under);
    expect(spent(8000).status, LimitStatus.near);
    expect(spent(10000).status, LimitStatus.near);
    expect(spent(10001).status, LimitStatus.over);
  });

  test('percent rounds down, so 79.9% never reads as 80%', () {
    expect(spent(7999).percent, 79);
    expect(spent(8640).percent, 86);
    expect(spent(11240).percent, 112);
  });

  test('what is left, or how far over', () {
    expect((spent(8640).leftMinor, spent(8640).overByMinor), (1360, 0));
    expect((spent(11240).leftMinor, spent(11240).overByMinor), (0, 1240));
  });

  test('days left count today and stop at the end of the period', () {
    expect(spent(0).daysLeft(DateTime(2026, 10, 8, 21)), 4);
    expect(spent(0).daysLeft(DateTime(2026, 10, 11)), 1);
    expect(spent(0).daysLeft(DateTime(2026, 10, 12)), 0);
  });

  test('sorts by share used, then by amount spent', () {
    final a = spent(5000);
    final b = spent(9000);
    final c = spent(5000 * 2, amountMinor: 20000);

    expect([a, b, c]..sort(LimitProgress.byUse), [b, c, a]);
  });

  group('LimitPeriod', () {
    test('weeks follow the first day of the week; months the calendar', () {
      final thursday = DateTime(2026, 10, 8);

      expect(
        LimitPeriod.week.rangeContaining(thursday, weekStart: WeekStart.sunday),
        DateRange(start: DateTime(2026, 10, 4), end: DateTime(2026, 10, 11)),
      );
      expect(
        LimitPeriod.month.rangeContaining(
          thursday,
          weekStart: WeekStart.monday,
        ),
        DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11)),
      );
    });

    test('rangesUpTo lists the last periods, oldest first', () {
      final months = LimitPeriod.month.rangesUpTo(
        DateTime(2026, 2, 10),
        weekStart: WeekStart.monday,
        count: 3,
      );

      expect(
        [for (final m in months) m.start],
        [DateTime(2025, 12), DateTime(2026), DateTime(2026, 2)],
      );
    });
  });
}
