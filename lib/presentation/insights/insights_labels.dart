import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:intl/intl.dart';

/// How Insights names its periods.
extension InsightsLabels on InsightsPeriod {
  /// "Week of Oct 5", "October 2026" or "2026".
  String title(AppLocalizations l10n, String locale, DateRange range) =>
      switch (this) {
        InsightsPeriod.week => l10n.insightsWeekOf(
          DateFormat.MMMd(locale).format(range.start),
        ),
        InsightsPeriod.month => DateFormat.yMMMM(locale).format(range.start),
        InsightsPeriod.year => DateFormat.y(locale).format(range.start),
      };

  /// The days covered, up to [today] while it's running: "Oct 1 – 22 · so
  /// far", or "Sep 1 – 30".
  String subtitle(
    AppLocalizations l10n,
    String locale,
    DateRange range,
    DateTime today,
  ) {
    final day = DateTime(today.year, today.month, today.day);
    if (!range.contains(day)) return formatDateRange(range, locale);
    final soFar = DateRange(
      start: range.start,
      end: DateTime(day.year, day.month, day.day + 1),
    );
    return l10n.insightsSoFar(formatDateRange(soFar, locale));
  }

  /// A short name for legends and buttons: "October", "Week of Oct 5" or
  /// "2026".
  String shortLabel(AppLocalizations l10n, String locale, DateRange range) =>
      switch (this) {
        InsightsPeriod.month => DateFormat.MMMM(locale).format(range.start),
        _ => title(l10n, locale, range),
      };

  /// What the one before is called in comparisons: "last week" or
  /// "September".
  String previousLabel(
    AppLocalizations l10n,
    String locale,
    DateRange previous,
  ) => switch (this) {
    InsightsPeriod.week => l10n.insightsLastWeek,
    _ => shortLabel(l10n, locale, previous),
  };

  /// A bar's label on the trend axis.
  String barLabel(String locale, DateRange range) => switch (this) {
    InsightsPeriod.week => DateFormat.MMMd(locale).format(range.start),
    InsightsPeriod.month => DateFormat.MMM(locale).format(range.start),
    // One letter per month, like a calendar's year view.
    InsightsPeriod.year => DateFormat('MMMMM', locale).format(range.start),
  };
}
