import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_with_category.freezed.dart';

/// A transaction together with its category, as lists show it.
@freezed
abstract class TransactionWithCategory with _$TransactionWithCategory {
  const factory TransactionWithCategory({
    required Transaction transaction,
    required Category category,
  }) = _TransactionWithCategory;
}
