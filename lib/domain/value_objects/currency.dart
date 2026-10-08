import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';

/// A currency the user can track money in.
///
/// Names are display text and come from localization, not from here.
@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    /// ISO 4217 code, e.g. `EUR`.
    required String code,

    /// Symbol shown before amounts, e.g. `€`.
    required String symbol,

    /// Digits after the decimal point: 2 for EUR (cents), 0 for JPY.
    required int decimalDigits,
  }) = _Currency;
}

/// Currencies offered during onboarding and in settings.
const supportedCurrencies = <Currency>[
  Currency(code: 'USD', symbol: r'$', decimalDigits: 2),
  Currency(code: 'EUR', symbol: '€', decimalDigits: 2),
  Currency(code: 'GBP', symbol: '£', decimalDigits: 2),
  Currency(code: 'CHF', symbol: 'CHF', decimalDigits: 2),
  Currency(code: 'BAM', symbol: 'KM', decimalDigits: 2),
  Currency(code: 'RSD', symbol: 'RSD', decimalDigits: 2),
  Currency(code: 'PLN', symbol: 'zł', decimalDigits: 2),
  Currency(code: 'CZK', symbol: 'Kč', decimalDigits: 2),
  Currency(code: 'HUF', symbol: 'Ft', decimalDigits: 2),
  Currency(code: 'RON', symbol: 'lei', decimalDigits: 2),
  Currency(code: 'SEK', symbol: 'kr', decimalDigits: 2),
  Currency(code: 'NOK', symbol: 'kr', decimalDigits: 2),
  Currency(code: 'DKK', symbol: 'kr', decimalDigits: 2),
  Currency(code: 'TRY', symbol: '₺', decimalDigits: 2),
  Currency(code: 'CAD', symbol: r'$', decimalDigits: 2),
  Currency(code: 'AUD', symbol: r'$', decimalDigits: 2),
  Currency(code: 'NZD', symbol: r'$', decimalDigits: 2),
  Currency(code: 'MXN', symbol: r'$', decimalDigits: 2),
  Currency(code: 'BRL', symbol: r'R$', decimalDigits: 2),
  Currency(code: 'JPY', symbol: '¥', decimalDigits: 0),
  Currency(code: 'CNY', symbol: '¥', decimalDigits: 2),
  Currency(code: 'KRW', symbol: '₩', decimalDigits: 0),
  Currency(code: 'INR', symbol: '₹', decimalDigits: 2),
  Currency(code: 'SGD', symbol: r'$', decimalDigits: 2),
  Currency(code: 'AED', symbol: 'AED', decimalDigits: 2),
  Currency(code: 'ZAR', symbol: 'R', decimalDigits: 2),
];

/// The supported currency with this ISO [code], or `null`.
Currency? currencyByCode(String code) {
  for (final currency in supportedCurrencies) {
    if (currency.code == code) return currency;
  }
  return null;
}
