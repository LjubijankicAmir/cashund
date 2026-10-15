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

    /// The [original]'s category when it's archived, so not in [categories]
    /// but still its category until another is picked.
    Category? archivedCategory,

    /// The transaction as saved, once [status] is `saved`.
    Transaction? saved,
  }) = _TransactionFormState;

  const TransactionFormState._();

  bool get isEditing => original != null;

  /// How many recently used categories the picker shows.
  static const recentCount = 3;

  /// How many categories are offered as chips under the category field.
  static const quickPickCount = 3;

  /// The first categories in the user's order, for one-tap picks.
  List<Category> get quickPicks => categories.take(quickPickCount).toList();

  int? get amountMinor => switch (currency) {
    final currency? => parseAmount(amountText, currency),
    null => null,
  };

  Category? get selectedCategory {
    for (final category in [
      ...categories,
      ...recentCategories,
      ?archivedCategory,
    ]) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  bool get canSave =>
      (amountMinor ?? 0) > 0 &&
      selectedCategory != null &&
      status != TransactionFormStatus.saving;
}
