import 'package:cashund/domain/services/period_totals.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const monday = WeekStart.monday;
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));

  group('InsightsPeriod', () {
    test('steps back and forth across years', () {
      final january = InsightsPeriod.month.rangeContaining(
        DateTime(2027, 1, 15),
        weekStart: monday,
      );

      expect(
        InsightsPeriod.month.previous(january, weekStart: monday).start,
        DateTime(2026, 12),
      );
      expect(
        InsightsPeriod.year.next(
          DateRange(start: DateTime(2026), end: DateTime(2027)),
          weekStart: monday,
        ),
        DateRange(start: DateTime(2027), end: DateTime(2028)),
      );
    });

    test('trends cover 5 weeks, 6 months or the 12 months of the year', () {
      final weeks = InsightsPeriod.week.trendRanges(
        InsightsPeriod.week.rangeContaining(
          DateTime(2026, 10, 8),
          weekStart: monday,
        ),
        weekStart: monday,
      );
      final months = InsightsPeriod.month.trendRanges(
        october,
        weekStart: monday,
      );
      final year = InsightsPeriod.year.trendRanges(
        DateRange(start: DateTime(2026), end: DateTime(2027)),
        weekStart: monday,
      );

      expect([for (final w in weeks) w.start.day], [7, 14, 21, 28, 5]);
      expect([for (final m in months) m.start.month], [5, 6, 7, 8, 9, 10]);
      expect(year, hasLength(12));
      expect(year.last.start, DateTime(2026, 12));
    });
  });

  group('PeriodTotals', () {
    test('sumIn adds the days inside the range only', () {
      final byDay = {
        DateTime(2026, 9, 30): 500,
        DateTime(2026, 10): 1000,
        DateTime(2026, 10, 31): 2000,
        DateTime(2026, 11): 4000,
      };

      expect(PeriodTotals.sumIn(byDay, october), 3000);
    });

    test('samePoint cuts a period to as far as the running one has got', () {
      final september = DateRange(
        start: DateTime(2026, 9),
        end: DateTime(2026, 10),
      );

      // October 22: 22 days in.
      expect(
        PeriodTotals.samePoint(
          september,
          running: october,
          today: DateTime(2026, 10, 22, 18),
        ),
        DateRange(start: DateTime(2026, 9), end: DateTime(2026, 9, 23)),
      );
      // On the 31st, September only has 30 days.
      expect(
        PeriodTotals.samePoint(
          september,
          running: october,
          today: DateTime(2026, 10, 31),
        ),
        september,
      );
      // A finished period compares whole.
      expect(
        PeriodTotals.samePoint(
          september,
          running: october,
          today: DateTime(2026, 11, 3),
        ),
        september,
      );
    });

    test('average leaves out empty periods', () {
      expect(PeriodTotals.average([0, 0, 2100, 2400, 2700]), 2400);
      expect(PeriodTotals.average([0, 0]), 0);
    });
  });
}
