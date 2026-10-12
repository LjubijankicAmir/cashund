import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';

typedef PredefinedCategorySeed = (
  TransactionType type,
  String key,
  String emoji,
  CategoryColor color,
);

/// The built-in categories, in their default order per type. Names come from
/// the translations, by key.
const List<PredefinedCategorySeed> predefinedCategories = [
  (TransactionType.expense, 'groceries', '🛒', CategoryColor.olive),
  (TransactionType.expense, 'eating_out', '🍔', CategoryColor.apricot),
  (TransactionType.expense, 'transport', '🚌', CategoryColor.sky),
  (TransactionType.expense, 'housing', '🏠', CategoryColor.periwinkle),
  (TransactionType.expense, 'bills', '🧾', CategoryColor.slate),
  (TransactionType.expense, 'household', '🧺', CategoryColor.teal),
  (TransactionType.expense, 'health', '💊', CategoryColor.coral),
  (TransactionType.expense, 'personal_care', '💄', CategoryColor.rose),
  (TransactionType.expense, 'clothing', '👕', CategoryColor.plum),
  (TransactionType.expense, 'social_life', '🎉', CategoryColor.mustard),
  (TransactionType.expense, 'gifts', '🎁', CategoryColor.lavender),
  (TransactionType.expense, 'travel', '✈️', CategoryColor.sky),
  (TransactionType.expense, 'pets', '🐾', CategoryColor.cocoa),
  (TransactionType.expense, 'other', '📦', CategoryColor.slate),
  (TransactionType.income, 'salary', '💼', CategoryColor.teal),
  (TransactionType.income, 'bonus', '🏆', CategoryColor.mustard),
  (TransactionType.income, 'side_income', '💻', CategoryColor.periwinkle),
  (TransactionType.income, 'gifts', '🎁', CategoryColor.lavender),
  (TransactionType.income, 'refunds', '🔁', CategoryColor.sky),
  (TransactionType.income, 'interest', '📈', CategoryColor.olive),
  (TransactionType.income, 'other', '📦', CategoryColor.slate),
];

/// Inserts the built-in categories that don't exist yet.
///
/// Plain SQL on purpose: migrations run forever, so they mustn't depend on the
/// table classes, which keep changing.
Future<void> seedPredefinedCategories(DatabaseConnectionUser database) async {
  final sortOrders = <TransactionType, int>{};
  for (final (type, key, emoji, color) in predefinedCategories) {
    final sortOrder = sortOrders[type] = (sortOrders[type] ?? -1) + 1;
    await database.customStatement(
      'INSERT OR IGNORE INTO categories (type, predefined_key, emoji, color, sort_order) VALUES (?, ?, ?, ?, ?)',
      [type.name, key, emoji, color.name, sortOrder],
    );
  }
}
