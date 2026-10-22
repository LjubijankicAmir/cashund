part of 'home_message_bloc.dart';

/// The pieces of one finished period's recap, as they load.
@freezed
abstract class RecapData with _$RecapData {
  const factory RecapData({
    required DateRange range,
    PeriodSummary? summary,
    @Default(0) int previousSpentMinor,
    CategorySpending? top,
    @Default(<LimitProgress>[]) List<LimitProgress> limits,
  }) = _RecapData;
}

@freezed
abstract class HomeMessageState with _$HomeMessageState {
  const factory HomeMessageState({
    required DateTime today,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// This week's and this month's limits.
    @Default(<LimitPeriod, List<LimitProgress>>{})
    Map<LimitPeriod, List<LimitProgress>> limits,

    /// Last week's and last month's recaps, as they load.
    @Default(<LimitPeriod, RecapData>{}) Map<LimitPeriod, RecapData> recaps,

    /// Closed messages, by key; `null` until loaded, so nothing shows that
    /// was already closed.
    Map<String, DateTime>? dismissed,
  }) = _HomeMessageState;

  const HomeMessageState._();

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  /// What the buddy says on Home, if anything beyond the everyday messages.
  HomeMessage? get message {
    final dismissed = this.dismissed;
    if (dismissed == null || preferences == null) return null;
    return HomeMessages.pick(
      limits: [for (final limits in limits.values) ...limits],
      recaps: [
        // The month first: when both end together, the month wins.
        for (final period in [LimitPeriod.month, LimitPeriod.week])
          if (recaps[period] case RecapData(:final summary?) && final data)
            PeriodRecap(
              period: period,
              range: data.range,
              spentMinor: summary.expenseMinor,
              incomeMinor: summary.incomeMinor,
              previousSpentMinor: data.previousSpentMinor,
              top: data.top,
              limitsKept: data.limits.isEmpty
                  ? null
                  : (
                      kept: data.limits
                          .where((l) => l.status != LimitStatus.over)
                          .length,
                      of: data.limits.length,
                    ),
            ),
      ],
      dismissed: dismissed,
      today: today,
    );
  }
}
