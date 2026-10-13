import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';

/// The quick date choices in the filters.
enum DatePreset {
  thisWeek,
  thisMonth,
  lastMonth,

  /// Any range the user picks; it has no range of its own.
  custom;

  /// The days this preset covers around [today], or `null` for [custom].
  DateRange? rangeAround(DateTime today, WeekStart weekStart) => switch (this) {
    DatePreset.thisWeek => Period.week.rangeContaining(
      today,
      weekStart: weekStart,
    ),
    DatePreset.thisMonth => Period.month.rangeContaining(
      today,
      weekStart: weekStart,
    ),
    DatePreset.lastMonth => Period.month.rangeContaining(
      DateTime(today.year, today.month - 1),
      weekStart: weekStart,
    ),
    DatePreset.custom => null,
  };

  /// Which preset [range] is, or [custom] for any other range.
  static DatePreset of(DateRange range, DateTime today, WeekStart weekStart) {
    for (final preset in values) {
      if (preset.rangeAround(today, weekStart) == range) return preset;
    }
    return custom;
  }
}
