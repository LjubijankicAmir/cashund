import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final usd = currencyByCode('USD')!;

  test('puts the symbol first with the currency decimals', () {
    expect(formatMoney(6210, usd), r'$62.10');
    expect(formatMoney(123456789, usd), r'$1,234,567.89');
  });

  test('uses a true minus for negative amounts', () {
    expect(formatMoney(-6210, usd), '$minusSign\$62.10');
  });

  test('shows a plus on positive amounts only when signed', () {
    expect(formatMoney(240000, usd, signed: true), r'+$2,400.00');
    expect(formatMoney(0, usd, signed: true), r'$0.00');
  });

  test('respects currencies without decimals', () {
    expect(formatMoney(-62, currencyByCode('JPY')!), '$minusSign¥62');
  });

  test('separates letter symbols from the number', () {
    expect(formatMoney(6210, currencyByCode('BAM')!), 'KM 62.10');
    expect(formatMoney(6210, currencyByCode('EUR')!), '€62.10');
  });

  test('converts major to minor units', () {
    expect(minorUnitsOf(62.10, usd), 6210);
    expect(minorUnitsOf(62.10, currencyByCode('JPY')!), 62);
  });
}
