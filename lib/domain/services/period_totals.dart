import 'package:cashund/domain/value_objects/date_range.dart';

/// Totals over spans of days, from amounts per day.
abstract final class PeriodTotals {
  /// The sum of [byDay] inside [range].
  static int sumIn(Map<DateTime, int> byDay, DateRange range) => byDay.entries
      .where((day) => range.contains(day.key))
      .fold(0, (sum, day) => sum + day.value);

  /// [range] cut off after as many days as have passed of [running] by
  /// [today], so a period that's still going compares "by this point".
  /// A [running] period that's over compares whole to whole.
  static DateRange samePoint(
    DateRange range, {
    required DateRange running,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    if (!running.contains(day)) return range;
    final elapsed = _daysBetween(running.start, day) + 1;
    final cut = DateTime(
      range.start.year,
      range.start.month,
      range.start.day + elapsed,
    );
    return DateRange(
      start: range.start,
      end: cut.isBefore(range.end) ? cut : range.end,
    );
  }

  /// The average of [totals], leaving out periods with nothing in them
  /// (before the first transaction, say). 0 when all are empty.
  static int average(Iterable<int> totals) {
    final counted = [
      for (final total in totals)
        if (total > 0) total,
    ];
    if (counted.isEmpty) return 0;
    return (counted.fold(0, (sum, total) => sum + total) / counted.length)
        .round();
  }

  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
