part of 'transaction_form_bloc.dart';

@freezed
sealed class TransactionFormEvent with _$TransactionFormEvent {
  /// Opens the form for [type].
  const factory TransactionFormEvent.started(TransactionType type) = _Started;

  /// Opens the form on an existing [transaction] to change or delete it.
  const factory TransactionFormEvent.editStarted(Transaction transaction) =
      _EditStarted;

  const factory TransactionFormEvent.deletePressed() = _DeletePressed;
  const factory TransactionFormEvent.typeChanged(TransactionType type) =
      _TypeChanged;
  const factory TransactionFormEvent.amountChanged(String text) =
      _AmountChanged;
  const factory TransactionFormEvent.categorySelected(int categoryId) =
      _CategorySelected;
  const factory TransactionFormEvent.titleChanged(String title) = _TitleChanged;
  const factory TransactionFormEvent.dateSelected(DateTime date) =
      _DateSelected;
  const factory TransactionFormEvent.savePressed() = _SavePressed;

  /// Internal: follows the category lists of [type]. A newer one replaces it.
  const factory TransactionFormEvent.categoriesWatched(TransactionType type) =
      _CategoriesWatched;
}
