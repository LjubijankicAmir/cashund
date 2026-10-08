import 'dart:math';

import 'package:cashund/domain/value_objects/currency.dart';
import 'package:intl/intl.dart';

/// The true minus sign (U+2212). Never use a hyphen for negative amounts.
const minusSign = '\u2212';

/// Formats an amount the Cashund way: symbol first, the currency's decimal
/// digits, and a true minus sign (U+2212) for negative amounts.
///
/// [minorUnits] is the amount in the currency's smallest unit (cents for
/// EUR). Set [signed] to also show `+` on positive amounts, e.g. incomes.
String formatMoney(int minorUnits, Currency currency, {bool signed = false}) {
  final digits = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: currency.decimalDigits,
  );
  final number = digits.format(
    minorUnits.abs() / pow(10, currency.decimalDigits),
  );
  final sign = minorUnits < 0
      ? minusSign
      : (signed && minorUnits > 0 ? '+' : '');
  final gap = _isWordSymbol(currency.symbol) ? ' ' : '';

  return '$sign${currency.symbol}$gap$number';
}

/// Letter symbols like "KM" or "Fr" read better with a space before the number.
bool _isWordSymbol(String symbol) =>
    RegExp(r'^\p{L}{2,}$', unicode: true).hasMatch(symbol);

/// Converts an amount in major units (dollars) to [currency]'s minor units
/// (cents), e.g. 62.10 USD → 6210.
int minorUnitsOf(num major, Currency currency) =>
    (major * pow(10, currency.decimalDigits)).round();
