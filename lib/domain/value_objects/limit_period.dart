import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';

/// How long a spending limit runs before it starts over.
enum LimitPeriod {
  week(Period.week),
  month(Period.month);

  LimitPeriod(this.period);

  final Period period;

  /// The limit's period around [day].
  DateRange rangeContaining(DateTime day, {required WeekStart weekStart}) =>
      period.rangeContaining(day, weekStart: weekStart);

  /// The [count] periods up to and including the one around [day], oldest
  /// first.
  List<DateRange> rangesUpTo(
    DateTime day, {
    required WeekStart weekStart,
    required int count,
  }) {
    final ranges = [rangeContaining(day, weekStart: weekStart)];
    while (ranges.length < count) {
      final earliest = ranges.first.start;
      // The day before a range lies in the one before it.
      ranges.insert(
        0,
        rangeContaining(
          DateTime(earliest.year, earliest.month, earliest.day - 1),
          weekStart: weekStart,
        ),
      );
    }
    return ranges;
  }
}
