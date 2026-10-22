part of 'insights_bloc.dart';

@freezed
sealed class InsightsEvent with _$InsightsEvent {
  /// Opens on the current [period], following every change.
  const factory InsightsEvent.started(InsightsPeriod period) = _Started;

  /// Switches to the current week, month or year.
  const factory InsightsEvent.periodSelected(InsightsPeriod period) =
      _PeriodSelected;
  const factory InsightsEvent.previousPressed() = _PreviousPressed;
  const factory InsightsEvent.nextPressed() = _NextPressed;

  /// From an empty period: to the first one with data, or the current one.
  const factory InsightsEvent.jumpedToData() = _JumpedToData;

  /// Internal: follows the data for the shown range and currency.
  const factory InsightsEvent.dataWatched() = _DataWatched;
}
