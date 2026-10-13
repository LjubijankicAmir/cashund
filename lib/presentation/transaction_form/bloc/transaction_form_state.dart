part of 'transaction_form_bloc.dart';

enum TransactionFormStatus { editing, saving, saved, deleted, failure }

@freezed
abstract class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    required DateTime today,
    required DateTime date,
    @Default(TransactionType.expense) TransactionType type,

    /// The amount as typed, e.g. "18." while typing "18.40".
    @Default('') String amountText,

    /// `null` until the preferences are loaded.
    Currency? currency,
    int? categoryId,
    @Default('') String title,
    @Default(<Category>[]) List<Category> categories,
    @Default(<Category>[]) List<Category> recentCategories,
    @Default(TransactionFormStatus.editing) TransactionFormStatus status,

    /// The transaction being changed, as it was; `null` when adding.
    Transaction? original,
  }) = _TransactionFormState;

  const TransactionFormState._();

  bool get isEditing => original != null;

  /// How many recently used categories the picker shows.
  static const recentCount = 3;

  int? get amountMinor => switch (currency) {
    final currency? => parseAmount(amountText, currency),
    null => null,
  };

  Category? get selectedCategory {
    for (final category in [...categories, ...recentCategories]) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  bool get canSave =>
      (amountMinor ?? 0) > 0 &&
      selectedCategory != null &&
      status != TransactionFormStatus.saving;
}
