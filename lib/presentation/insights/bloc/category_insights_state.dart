part of 'category_insights_bloc.dart';

@freezed
abstract class CategoryInsightsState with _$CategoryInsightsState {
  const factory CategoryInsightsState({
    required DateTime today,
    required Category category,
    required InsightsPeriod period,
    required DateRange range,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// The category's expenses per day across the trend and the period before.
    @Default(<DateTime, int>{}) Map<DateTime, int> expensesByDay,

    /// All expenses in [range], for the category's share; `null` until loaded.
    int? totalExpenseMinor,

    /// The category's transactions in [range] in the selected currency.
    @Default(0) int transactionCount,

    /// The category's current weekly and monthly limits.
    @Default(<LimitProgress>[]) List<LimitProgress> limits,
  }) = _CategoryInsightsState;

  const CategoryInsightsState._();

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  WeekStart get _weekStart => preferences?.weekStart ?? WeekStart.monday;

  DateTime get _day => DateTime(today.year, today.month, today.day);

  bool get isCurrent => range.contains(_day);

  int get spentMinor => PeriodTotals.sumIn(expensesByDay, range);

  /// Whole percent of all spending in the period.
  int get sharePercent => switch (totalExpenseMinor) {
    final total? when total > 0 => spentMinor * 100 ~/ total,
    _ => 0,
  };

  DateRange get previousRange => period.previous(range, weekStart: _weekStart);

  /// Spent against the period before, "by this point" while it's running.
  /// `null` for a year, or when the period before had nothing.
  ({int current, int previous})? get comparison {
    if (period == InsightsPeriod.year) return null;
    final previous = PeriodTotals.sumIn(
      expensesByDay,
      PeriodTotals.samePoint(previousRange, running: range, today: today),
    );
    if (previous == 0) return null;
    return (current: spentMinor, previous: previous);
  }

  List<DateRange> get trendRanges =>
      period.trendRanges(range, weekStart: _weekStart);

  List<TrendPoint> get trend => [
    for (final trendRange in trendRanges)
      (
        range: trendRange,
        totalMinor: PeriodTotals.sumIn(expensesByDay, trendRange),
        isCurrent: trendRange == range,
        isFuture: trendRange.start.isAfter(_day),
      ),
  ];

  int get averageMinor => PeriodTotals.average([
    for (final point in trend)
      if (!point.isFuture) point.totalMinor,
  ]);
}
