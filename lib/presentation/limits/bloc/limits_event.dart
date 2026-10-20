part of 'limits_bloc.dart';

@freezed
sealed class LimitsEvent with _$LimitsEvent {
  /// Shows the [period] limits, following every change.
  const factory LimitsEvent.started(LimitPeriod period) = _Started;
  const factory LimitsEvent.periodSelected(LimitPeriod period) =
      _PeriodSelected;

  /// Undoes a delete.
  const factory LimitsEvent.restored(LimitSnapshot snapshot) = _Restored;

  /// Internal: follows the limits for the selected period and currency.
  const factory LimitsEvent.limitsWatched() = _LimitsWatched;
}
