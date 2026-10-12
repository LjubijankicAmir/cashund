import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Thursday.
  final thursday = DateTime(2026, 10, 8, 15, 30);

  DateRange range(
    Period period, {
    WeekStart weekStart = WeekStart.monday,
    DateTime? on,
  }) {
    return period.rangeContaining(on ?? thursday, weekStart: weekStart);
  }

  test('a day runs from its midnight to the next', () {
    expect(
      range(Period.day),
      DateRange(start: DateTime(2026, 10, 8), end: DateTime(2026, 10, 9)),
    );
  });

  group('a week', () {
    test('starts on the chosen weekday', () {
      expect(range(Period.week).start, DateTime(2026, 10, 5));
      expect(
        range(Period.week, weekStart: WeekStart.sunday).start,
        DateTime(2026, 10, 4),
      );
      expect(
        range(Period.week, weekStart: WeekStart.saturday).start,
        DateTime(2026, 10, 3),
      );
    });

    test('lasts seven days', () {
      expect(range(Period.week).lastDay, DateTime(2026, 10, 11));
    });

    test('starts on the same day when that day is the first day', () {
      expect(
        range(Period.week, on: DateTime(2026, 10, 5)).start,
        DateTime(2026, 10, 5),
      );
    });

    test('can span two months', () {
      final week = range(Period.week, on: DateTime(2026, 10));

      expect(week.start, DateTime(2026, 9, 28));
      expect(week.lastDay, DateTime(2026, 10, 4));
    });
  });

  test('a month is the calendar month, also across a year end', () {
    expect(
      range(Period.month),
      DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11)),
    );
    expect(range(Period.month, on: DateTime(2026, 12, 31)).end, DateTime(2027));
  });

  test('contains includes the start and excludes the end', () {
    final day = range(Period.day);

    expect(day.contains(DateTime(2026, 10, 8)), isTrue);
    expect(day.contains(DateTime(2026, 10, 8, 23, 59)), isTrue);
    expect(day.contains(DateTime(2026, 10, 9)), isFalse);
  });
}
