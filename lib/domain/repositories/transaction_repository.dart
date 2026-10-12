import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class TransactionRepository {
  /// Logs a new transaction. [amountMinor] must be above zero.
  FutureResult<Unit> add({
    required TransactionType type,
    required int amountMinor,
    required String currencyCode,
    required int categoryId,
    required DateTime occurredOn,
    String? title,
  });

  /// Totals over [range], counting only transactions in [currencyCode]:
  /// amounts in different currencies can't be added up.
  StreamResult<PeriodSummary> watchSummary(
    DateRange range, {
    required String currencyCode,
  });

  /// Expenses over [range] per category, in [currencyCode], largest first.
  StreamResult<List<CategorySpending>> watchSpendingByCategory(
    DateRange range, {
    required String currencyCode,
  });

  /// Whether anything has been logged at all, in any currency.
  StreamResult<bool> watchHasAny();
}
