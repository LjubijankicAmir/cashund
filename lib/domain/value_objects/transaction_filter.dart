import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';

/// Which transactions to show. Empty means everything.
@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    /// Only expenses or only incomes; `null` for both.
    TransactionType? type,

    /// Only these categories; empty for all.
    @Default(<int>{}) Set<int> categoryIds,

    /// Only this span of days; `null` for all time.
    DateRange? range,
  }) = _TransactionFilter;

  const TransactionFilter._();

  /// How many kinds of filter are in use: type, categories and dates.
  int get activeCount => [
    type != null,
    categoryIds.isNotEmpty,
    range != null,
  ].where((active) => active).length;

  bool get isEmpty => activeCount == 0;
}
