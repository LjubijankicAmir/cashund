part of 'insights_bloc.dart';

/// One bar of a trend: a period's spending.
typedef TrendPoint = ({
  DateRange range,
  int totalMinor,
  bool isCurrent,
  bool isFuture,
});

@freezed
abstract class InsightsState with _$InsightsState {
  const factory InsightsState({
    required DateTime today,
    @Default(InsightsPeriod.month) InsightsPeriod period,

    /// The span shown; `null` until preferences load.
    DateRange? range,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// The shown range's totals; `null` until loaded.
    PeriodSummary? summary,
    @Default(<CategorySpending>[]) List<CategorySpending> spending,

    /// Expenses per day across [trendRanges].
    @Default(<DateTime, int>{}) Map<DateTime, int> expensesByDay,

    /// The earliest transaction's day; `null` before there is one.
    DateTime? firstDay,
  }) = _InsightsState;

  const InsightsState._();

  /// Below this many transactions, there's too little to compare.
  static const minForComparison = 5;

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  WeekStart get _weekStart => preferences?.weekStart ?? WeekStart.monday;

  DateTime get _day => DateTime(today.year, today.month, today.day);

  /// The period still running: "so far".
  bool get isCurrent => range?.contains(_day) ?? false;

  bool get canGoForward => switch (range) {
    final range? => range.end.isBefore(_day) || range.end == _day,
    null => false,
  };

  /// Back stops at the first period with data.
  bool get canGoBack => switch ((range, firstDay)) {
    (final range?, final firstDay?) => range.start.isAfter(firstDay),
    _ => false,
  };

  bool get isEmpty => summary?.transactionCount == 0;

  /// Where jumping to data goes: the first period with data when before it,
  /// otherwise the current one.
  DateRange? get dataRange {
    final range = this.range;
    if (range == null) return null;
    final firstDay = this.firstDay;
    if (firstDay != null && range.end.isBefore(firstDay) ||
        firstDay != null && range.end == firstDay) {
      return period.rangeContaining(firstDay, weekStart: _weekStart);
    }
    return period.rangeContaining(today, weekStart: _weekStart);
  }

  List<DateRange> get trendRanges => switch (range) {
    final range? => period.trendRanges(range, weekStart: _weekStart),
    null => const [],
  };

  List<TrendPoint> get trend => [
    for (final trendRange in trendRanges)
      (
        range: trendRange,
        totalMinor: PeriodTotals.sumIn(expensesByDay, trendRange),
        isCurrent: trendRange == range,
        isFuture: trendRange.start.isAfter(_day),
      ),
  ];

  /// The trend's average over periods that have anything in them.
  int get averageMinor => PeriodTotals.average([
    for (final point in trend)
      if (!point.isFuture) point.totalMinor,
  ]);

  List<SpendingSlice> get slices => SpendingBreakdown.slicesOf(spending);

  /// Spent in the shown period against the one before, "by this point" while
  /// it's running. `null` for a year, or with too little to compare.
  ({int current, int previous})? get comparison {
    final (range, summary) = (this.range, this.summary);
    if (range == null ||
        summary == null ||
        period == InsightsPeriod.year ||
        summary.transactionCount < minForComparison) {
      return null;
    }
    final previous = PeriodTotals.samePoint(
      period.previous(range, weekStart: _weekStart),
      running: range,
      today: today,
    );
    final previousMinor = PeriodTotals.sumIn(expensesByDay, previous);
    if (previousMinor == 0) return null;
    return (current: summary.expenseMinor, previous: previousMinor);
  }

  /// How many months of the shown year have passed, for "about $X a month".
  int get monthsSoFar {
    final range = this.range;
    if (range == null) return 1;
    if (!isCurrent) return 12;
    return today.month;
  }
}
