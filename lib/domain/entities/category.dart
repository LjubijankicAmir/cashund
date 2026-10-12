import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// What a transaction is for, e.g. Groceries or Salary.
///
/// Predefined categories have a [predefinedKey] and no [customName], so their
/// name comes from the translations. A user-chosen name takes priority.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    required TransactionType type,
    required String emoji,
    required CategoryColor color,
    required int sortOrder,

    /// Stable id of a built-in category, e.g. `eating_out`. Unique per type.
    String? predefinedKey,
    String? customName,
    @Default(false) bool isArchived,
  }) = _Category;
}
