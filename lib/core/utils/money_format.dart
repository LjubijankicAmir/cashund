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

/// A rounded amount for tight spots like chart labels: "$108", "$2.4k",
/// "$12k". Never negative; signs are shown elsewhere.
String formatMoneyShort(int minorUnits, Currency currency) {
  final major = minorUnits.abs() / pow(10, currency.decimalDigits);
  final gap = _isWordSymbol(currency.symbol) ? ' ' : '';
  final String number;
  if (major >= 9999.5) {
    number = '${(major / 1000).round()}k';
  } else if (major >= 999.5) {
    final thousands = (major / 100).round() / 10;
    number =
        '${thousands == thousands.roundToDouble() ? thousands.toInt() : thousands}k';
  } else {
    number = '${major.round()}';
  }
  return '${currency.symbol}$gap$number';
}

/// An amount rounded to whole units, e.g. an average: "$2,343".
String formatMoneyWhole(int minorUnits, Currency currency) {
  final unit = pow(10, currency.decimalDigits).toInt();
  final whole = (minorUnits / unit).round();
  return formatMoney(
    whole * unit,
    currency,
  ).replaceFirst(RegExp(r'[.,]0+$'), '');
}
