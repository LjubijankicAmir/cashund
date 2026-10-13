import 'package:cashund/core/utils/amount_input.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final eur = currencyByCode('EUR')!;
  final jpy = currencyByCode('JPY')!;

  group('parseAmount', () {
    test('reads whole and decimal amounts exactly', () {
      expect(parseAmount('18.40', eur), 1840);
      expect(parseAmount('18.4', eur), 1840);
      expect(parseAmount('18.', eur), 1800);
      expect(parseAmount('18', eur), 1800);
      expect(parseAmount('.5', eur), 50);
      expect(parseAmount('0.07', eur), 7);
    });

    test('is exact where doubles are not', () {
      expect(parseAmount('0.29', eur), 29);
      expect(parseAmount('1234567.89', eur), 123456789);
    });

    test('uses the currency decimals', () {
      expect(parseAmount('620', jpy), 620);
    });

    test('has nothing to read when empty', () {
      expect(parseAmount('', eur), isNull);
      expect(parseAmount('.', eur), isNull);
    });
  });

  group('AmountInputFormatter', () {
    String type(String old, String next, {int decimals = 2}) {
      return AmountInputFormatter(decimalDigits: decimals)
          .formatEditUpdate(
            TextEditingValue(text: old),
            TextEditingValue(text: next),
          )
          .text;
    }

    test(
      'turns a comma into a decimal point',
      () => expect(type('18', '18,'), '18.'),
    );
    test(
      'starts a bare decimal point with a zero',
      () => expect(type('', '.'), '0.'),
    );
    test('drops leading zeros', () => expect(type('0', '05'), '5'));
    test(
      'keeps a single zero before the point',
      () => expect(type('0', '0.'), '0.'),
    );
    test(
      'refuses a second decimal point',
      () => expect(type('1.2', '1.2.'), '1.2'),
    );
    test(
      'refuses more decimals than the currency has',
      () => expect(type('1.25', '1.255'), '1.25'),
    );
    test(
      'refuses decimals for currencies without them',
      () => expect(type('62', '62.', decimals: 0), '62'),
    );
    test('refuses letters', () => expect(type('12', '12a'), '12'));
    test(
      'refuses too many digits',
      () => expect(type('123456789', '1234567890'), '123456789'),
    );
  });

  group('formatAmountText', () {
    test('writes minor units back as typed text', () {
      expect(formatAmountText(1840, eur), '18.40');
      expect(formatAmountText(7, eur), '0.07');
      expect(formatAmountText(62, jpy), '62');
    });

    test('reads back to the same amount', () {
      for (final amount in [1, 50, 1840, 123456789]) {
        expect(parseAmount(formatAmountText(amount, eur), eur), amount);
      }
    });
  });
}
