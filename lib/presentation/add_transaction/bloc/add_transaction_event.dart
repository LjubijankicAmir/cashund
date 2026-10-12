part of 'add_transaction_bloc.dart';

@freezed
sealed class AddTransactionEvent with _$AddTransactionEvent {
  /// Opens the form for [type].
  const factory AddTransactionEvent.started(TransactionType type) = _Started;

  const factory AddTransactionEvent.typeChanged(TransactionType type) =
      _TypeChanged;
  const factory AddTransactionEvent.amountChanged(String text) = _AmountChanged;
  const factory AddTransactionEvent.categorySelected(int categoryId) =
      _CategorySelected;
  const factory AddTransactionEvent.titleChanged(String title) = _TitleChanged;
  const factory AddTransactionEvent.dateSelected(DateTime date) = _DateSelected;
  const factory AddTransactionEvent.savePressed() = _SavePressed;

  /// Internal: follows the category lists of [type]. A newer one replaces it.
  const factory AddTransactionEvent.categoriesWatched(TransactionType type) =
      _CategoriesWatched;
}
