part of 'category_insights_bloc.dart';

@freezed
sealed class CategoryInsightsEvent with _$CategoryInsightsEvent {
  /// Follows the category's spending, trend, transactions and limits.
  const factory CategoryInsightsEvent.started() = _Started;

  /// Internal: follows the data for the current currency.
  const factory CategoryInsightsEvent.dataWatched() = _DataWatched;
}
