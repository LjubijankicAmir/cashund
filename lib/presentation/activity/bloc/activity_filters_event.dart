part of 'activity_filters_bloc.dart';

@freezed
sealed class ActivityFiltersEvent with _$ActivityFiltersEvent {
  /// Opens the sheet on the filter currently in use.
  const factory ActivityFiltersEvent.started(TransactionFilter filter) =
      _Started;

  const factory ActivityFiltersEvent.typeChanged(TransactionType? type) =
      _TypeChanged;
  const factory ActivityFiltersEvent.categoryToggled(int categoryId) =
      _CategoryToggled;
  const factory ActivityFiltersEvent.categoriesCleared() = _CategoriesCleared;
  const factory ActivityFiltersEvent.presetSelected(DatePreset preset) =
      _PresetSelected;
  const factory ActivityFiltersEvent.customFromChanged(DateTime day) =
      _CustomFromChanged;
  const factory ActivityFiltersEvent.customToChanged(DateTime day) =
      _CustomToChanged;
  const factory ActivityFiltersEvent.reset() = _Reset;

  /// Internal: follows what the draft [filter] would show.
  const factory ActivityFiltersEvent.resultsWatched(TransactionFilter filter) =
      _ResultsWatched;
}
