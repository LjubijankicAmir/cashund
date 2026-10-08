import 'dart:ui';

import 'package:cashund/domain/value_objects/week_start.dart';

/// First-run guesses from the device's region, e.g. `de_DE` → EUR and Monday.
///
/// Only the country decides: a language alone (`en`) says nothing about where
/// someone lives, so devices without a country get the fallbacks.
abstract final class LocaleDefaults {
  static const fallbackCurrencyCode = 'USD';
  static const WeekStart fallbackWeekStart = WeekStart.monday;

  static String currencyCode(Locale locale) {
    return _currencyByCountry[locale.countryCode] ?? fallbackCurrencyCode;
  }

  static WeekStart weekStart(Locale locale) {
    final country = locale.countryCode;
    if (country == null) return fallbackWeekStart;
    if (_sundayFirst.contains(country)) return WeekStart.sunday;
    if (_saturdayFirst.contains(country)) return WeekStart.saturday;
    return WeekStart.monday;
  }

  // dart format off
  /// Countries using one of the supported currencies.
  static const _currencyByCountry = {
    'US': 'USD', 'GB': 'GBP', 'CH': 'CHF', 'LI': 'CHF', 'BA': 'BAM', 'RS': 'RSD',
    'PL': 'PLN', 'CZ': 'CZK', 'HU': 'HUF', 'RO': 'RON', 'SE': 'SEK', 'NO': 'NOK',
    'DK': 'DKK', 'TR': 'TRY', 'CA': 'CAD', 'AU': 'AUD', 'NZ': 'NZD', 'MX': 'MXN',
    'BR': 'BRL', 'JP': 'JPY', 'CN': 'CNY', 'KR': 'KRW', 'IN': 'INR', 'SG': 'SGD',
    'AE': 'AED', 'ZA': 'ZAR',
    // Euro area, plus Montenegro and Kosovo, which also use the euro.
    'AT': 'EUR', 'BE': 'EUR', 'BG': 'EUR', 'CY': 'EUR', 'DE': 'EUR', 'EE': 'EUR',
    'ES': 'EUR', 'FI': 'EUR', 'FR': 'EUR', 'GR': 'EUR', 'HR': 'EUR', 'IE': 'EUR',
    'IT': 'EUR', 'LT': 'EUR', 'LU': 'EUR', 'LV': 'EUR', 'MT': 'EUR', 'NL': 'EUR',
    'PT': 'EUR', 'SI': 'EUR', 'SK': 'EUR', 'ME': 'EUR', 'XK': 'EUR',
  };

  // First day of the week per Unicode CLDR week data. Everyone else: Monday.
  static const _sundayFirst = {
    'AG', 'AS', 'BD', 'BR', 'BS', 'BT', 'BW', 'BZ', 'CA', 'CN', 'CO', 'DM', 'DO',
    'ET', 'GT', 'GU', 'HK', 'HN', 'ID', 'IL', 'IN', 'JM', 'JP', 'KE', 'KH', 'KR',
    'LA', 'MH', 'MM', 'MO', 'MT', 'MX', 'MZ', 'NI', 'NP', 'PA', 'PE', 'PH', 'PK',
    'PR', 'PT', 'PY', 'SA', 'SG', 'SV', 'TH', 'TT', 'TW', 'UM', 'US', 'VE', 'VI',
    'WS', 'YE', 'ZA', 'ZW',
  };
  static const _saturdayFirst = {
    'AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM', 'QA',
    'SD', 'SY',
  };
  // dart format on
}
