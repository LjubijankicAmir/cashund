import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';

/// The span Insights looks at, stepped through one at a time.
enum InsightsPeriod {
  week,
  month,
  year;

  /// The period around [day].
  DateRange rangeContaining(DateTime day, {required WeekStart weekStart}) {
    return switch (this) {
      week => Period.week.rangeContaining(day, weekStart: weekStart),
      month => Period.month.rangeContaining(day, weekStart: weekStart),
      year => DateRange(start: DateTime(day.year), end: DateTime(day.year + 1)),
    };
  }

  /// The period just before [range].
  DateRange previous(DateRange range, {required WeekStart weekStart}) =>
      rangeContaining(_dayBefore(range.start), weekStart: weekStart);

  /// The period just after [range].
  DateRange next(DateRange range, {required WeekStart weekStart}) =>
      rangeContaining(range.end, weekStart: weekStart);

  /// The trend's bars for [range]: the last 5 weeks or 6 months up to it,
  /// or every month of the year. Oldest first.
  List<DateRange> trendRanges(DateRange range, {required WeekStart weekStart}) {
    return switch (this) {
      week || month => () {
        final ranges = [range];
        while (ranges.length < (this == week ? 5 : 6)) {
          ranges.insert(0, previous(ranges.first, weekStart: weekStart));
        }
        return ranges;
      }(),
      year => [
        for (var month = 1; month <= 12; month++)
          DateRange(
            start: DateTime(range.start.year, month),
            end: DateTime(range.start.year, month + 1),
          ),
      ],
    };
  }

  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);
}
