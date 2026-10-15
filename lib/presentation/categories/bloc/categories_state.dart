part of 'categories_bloc.dart';

@freezed
abstract class CategoriesState with _$CategoriesState {
  const factory CategoriesState({
    @Default(TransactionType.expense) TransactionType type,

    /// All categories of [type] in their order, archived ones included.
    /// `null` until loaded.
    List<Category>? categories,

    /// Set when saving a change failed; the list shows the saved state again.
    @Default(false) bool saveFailed,
  }) = _CategoriesState;

  const CategoriesState._();

  List<Category> get active => [
    for (final category in categories ?? const <Category>[])
      if (!category.isArchived) category,
  ];

  List<Category> get archived => [
    for (final category in categories ?? const <Category>[])
      if (category.isArchived) category,
  ];
}
