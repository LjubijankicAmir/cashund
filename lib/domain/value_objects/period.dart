import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/week_start.dart';

/// How much time an overview covers.
enum Period {
  day,
  week,
  month;

  /// The period around [day]: that day, its week (starting on [weekStart]),
  /// or its calendar month.
  DateRange rangeContaining(DateTime day, {required WeekStart weekStart}) {
    final date = DateTime(day.year, day.month, day.day);

    return switch (this) {
      Period.day => DateRange(start: date, end: _addDays(date, 1)),
      Period.week => () {
        final start = _addDays(
          date,
          -((date.weekday - weekStart.weekday) % DateTime.daysPerWeek),
        );
        return DateRange(
          start: start,
          end: _addDays(start, DateTime.daysPerWeek),
        );
      }(),
      Period.month => DateRange(
        start: DateTime(date.year, date.month),
        end: DateTime(date.year, date.month + 1),
      ),
    };
  }

  /// Calendar-day arithmetic that stays on midnight across daylight saving.
  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
}
