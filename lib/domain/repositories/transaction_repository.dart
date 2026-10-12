import 'package:cashund/core/error/result.dart';
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
}
