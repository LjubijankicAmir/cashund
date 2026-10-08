import 'dart:ui';

import 'package:cashund/core/locale/locale_defaults.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currencyCode', () {
    test('follows the device country', () {
      expect(LocaleDefaults.currencyCode(const Locale('de', 'DE')), 'EUR');
      expect(LocaleDefaults.currencyCode(const Locale('en', 'GB')), 'GBP');
      expect(LocaleDefaults.currencyCode(const Locale('en', 'CH')), 'CHF');
      expect(LocaleDefaults.currencyCode(const Locale('en', 'BA')), 'BAM');
    });

    test('falls back when only the language is known', () {
      expect(
        LocaleDefaults.currencyCode(const Locale('en')),
        LocaleDefaults.fallbackCurrencyCode,
      );
    });
  });

  group('weekStart', () {
    test('follows the device country', () {
      expect(
        LocaleDefaults.weekStart(const Locale('en', 'US')),
        WeekStart.sunday,
      );
      expect(
        LocaleDefaults.weekStart(const Locale('de', 'DE')),
        WeekStart.monday,
      );
    });

    test('falls back when only the language is known', () {
      expect(
        LocaleDefaults.weekStart(const Locale('en')),
        LocaleDefaults.fallbackWeekStart,
      );
    });
  });
}
