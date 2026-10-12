import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = DateOnlyConverter();

  test('stores a date as year-month-day text', () {
    expect(converter.toSql(DateTime(2026, 3, 7, 18, 45)), '2026-03-07');
  });

  test('reads the text back as local midnight', () {
    expect(converter.fromSql('2026-03-07'), DateTime(2026, 3, 7));
  });
}
