import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';

extension TransactionDisplay on Transaction {
  /// The currency it was logged in, even one no longer offered.
  Currency get currency =>
      currencyByCode(currencyCode) ??
      Currency(code: currencyCode, symbol: currencyCode, decimalDigits: 2);

  /// "−$42.75" for an expense, "+$2,400.00" for an income.
  String get signedAmount => formatMoney(
    type == TransactionType.income ? amountMinor : -amountMinor,
    currency,
    signed: true,
  );
}
