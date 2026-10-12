import 'package:cashund/domain/value_objects/currency.dart';
import 'package:flutter/services.dart';

/// The amount typed so far, in [currency]'s minor units, or `null` when
/// there's nothing to parse. Works digit by digit, never through a double,
/// so "18.40" is exactly 1840.
int? parseAmount(String text, Currency currency) {
  final [whole, ...rest] = text.split('.');
  final fraction = rest.isEmpty ? '' : rest.first;
  if (whole.isEmpty && fraction.isEmpty) return null;

  final digits =
      '${whole.isEmpty ? '0' : whole}${fraction.padRight(currency.decimalDigits, '0')}';
  return int.tryParse(digits);
}

/// Keeps an amount field to what [parseAmount] understands: digits and one
/// decimal point (a typed comma becomes one), at most [decimalDigits] after
/// it, no leading zeros, and no more than [maxWholeDigits] before it.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({required this.decimalDigits, this.maxWholeDigits = 9});

  final int decimalDigits;
  final int maxWholeDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    final [whole, ...rest] = text.split('.');
    final tooManyDecimals =
        rest.isNotEmpty &&
        (decimalDigits == 0 || rest.first.length > decimalDigits);
    if (tooManyDecimals) return oldValue;

    final trimmedWhole = whole.replaceFirst(RegExp('^0+(?=.)'), '');
    if (trimmedWhole.length > maxWholeDigits) return oldValue;

    final formatted = rest.isEmpty
        ? trimmedWhole
        : '${trimmedWhole.isEmpty ? '0' : trimmedWhole}.${rest.first}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
