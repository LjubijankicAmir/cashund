part of 'limits_bloc.dart';

@freezed
abstract class LimitsState with _$LimitsState {
  const factory LimitsState({
    required DateTime today,
    @Default(LimitPeriod.week) LimitPeriod period,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// The period's limits, most used first; `null` until loaded.
    List<LimitProgress>? progress,

    /// How many limits exist in either period; `null` until loaded.
    int? limitCount,

    /// Set when undoing a delete failed.
    @Default(false) bool restoreFailed,
  }) = _LimitsState;

  const LimitsState._();

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  DateRange? get range => switch (preferences) {
    final preferences? => period.rangeContaining(
      today,
      weekStart: preferences.weekStart,
    ),
    null => null,
  };

  LimitProgress? get overall {
    for (final limit in progress ?? const <LimitProgress>[]) {
      if (limit.limit.isOverall) return limit;
    }
    return null;
  }

  List<LimitProgress> get byCategory => [
    for (final limit in progress ?? const <LimitProgress>[])
      if (!limit.limit.isOverall) limit,
  ];
}
