part of 'add_transaction_bloc.dart';

enum AddTransactionStatus { editing, saving, saved, failure }

@freezed
abstract class AddTransactionState with _$AddTransactionState {
  const factory AddTransactionState({
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
    @Default(AddTransactionStatus.editing) AddTransactionStatus status,
  }) = _AddTransactionState;

  const AddTransactionState._();

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
      status != AddTransactionStatus.saving;
}
