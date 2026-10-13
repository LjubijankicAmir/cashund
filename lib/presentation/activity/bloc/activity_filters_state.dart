part of 'activity_filters_bloc.dart';

@freezed
abstract class ActivityFiltersState with _$ActivityFiltersState {
  const factory ActivityFiltersState({
    required DateTime today,
    @Default(WeekStart.monday) WeekStart weekStart,

    /// What applying would set; not in use until applied.
    @Default(TransactionFilter()) TransactionFilter draft,

    /// The chosen date chip; `null` for all time.
    DatePreset? preset,

    @Default(<Category>[]) List<Category> expenseCategories,
    @Default(<Category>[]) List<Category> incomeCategories,

    /// What the draft would show, before any search; `null` while loading.
    List<TransactionWithCategory>? results,
  }) = _ActivityFiltersState;

  const ActivityFiltersState._();

  /// The categories offered for the chosen type: both kinds for all.
  List<Category> get categories => switch (draft.type) {
    TransactionType.expense => expenseCategories,
    TransactionType.income => incomeCategories,
    null => [...expenseCategories, ...incomeCategories],
  };
}
