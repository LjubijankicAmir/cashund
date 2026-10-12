import 'package:cashund/domain/entities/category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_spending.freezed.dart';

/// How much went to one category over a period.
@freezed
abstract class CategorySpending with _$CategorySpending {
  const factory CategorySpending({
    required Category category,
    required int amountMinor,
  }) = _CategorySpending;
}
