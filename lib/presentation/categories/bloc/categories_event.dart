part of 'categories_bloc.dart';

@freezed
sealed class CategoriesEvent with _$CategoriesEvent {
  /// Shows the categories of [type], following every change.
  const factory CategoriesEvent.typeSelected(TransactionType type) =
      _TypeSelected;

  /// The active category at [oldIndex] was dragged to [newIndex], counted
  /// among the active categories after it was taken out.
  const factory CategoriesEvent.reordered(int oldIndex, int newIndex) =
      _Reordered;

  const factory CategoriesEvent.archived(int id) = _Archived;
  const factory CategoriesEvent.restored(int id) = _Restored;
}
