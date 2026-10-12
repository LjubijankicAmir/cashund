import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';

/// An expense or an income.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required int id,
    required TransactionType type,

    /// Always positive, in the currency's smallest unit (cents). [type] says
    /// which way the money went.
    required int amountMinor,

    /// ISO 4217 code of the currency it was logged in.
    required String currencyCode,
    required int categoryId,

    /// The day it happened, at local midnight.
    required DateTime occurredOn,

    /// When it was logged; orders transactions within a day.
    required DateTime createdAt,
    String? title,
  }) = _Transaction;
}
