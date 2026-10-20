part of 'limit_detail_bloc.dart';

@freezed
abstract class LimitDetailState with _$LimitDetailState {
  const factory LimitDetailState({
    required DateTime today,
    required SpendingLimit limit,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// This period's progress; `null` until loaded.
    LimitProgress? progress,
    @Default(<LimitAmount>[]) List<LimitAmount> amounts,

    /// Spending per day across [ranges].
    @Default(<DateTime, int>{}) Map<DateTime, int> spentByDay,

    /// This period's transactions, newest first.
    @Default(<TransactionWithCategory>[])
    List<TransactionWithCategory> transactions,

    /// Set once the limit is gone, e.g. deleted from the editor.
    @Default(false) bool isDeleted,
  }) = _LimitDetailState;

  const LimitDetailState._();

  /// How many periods the history shows, the current one included.
  static const historyCount = 5;

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  /// The periods in the history, oldest first; the last one is current.
  List<DateRange> get ranges => switch (preferences) {
    final preferences? => limit.period.rangesUpTo(
      today,
      weekStart: preferences.weekStart,
      count: historyCount,
    ),
    null => const [],
  };

  List<LimitPeriodResult> get history => LimitHistory.results(
    ranges: ranges,
    amounts: amounts,
    spentByDay: spentByDay,
  );

  ({int kept, int of}) get kept => LimitHistory.kept(history, today: today);
}
