import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // The app gets this from flutter_localizations; plain tests load it here.
  setUpAll(() => initializeDateFormatting('en'));

  String format(DateTime start, DateTime end) =>
      formatDateRange(DateRange(start: start, end: end), 'en');

  test('names the month once when the range stays in it', () {
    expect(format(DateTime(2026, 10, 5), DateTime(2026, 10, 12)), 'Oct 5 – 11');
  });

  test('names both months when the range crosses one', () {
    expect(
      format(DateTime(2026, 9, 28), DateTime(2026, 10, 5)),
      'Sep 28 – Oct 4',
    );
  });

  test('adds the years when the range crosses into a new one', () {
    expect(
      format(DateTime(2026, 12, 28), DateTime(2027, 1, 4)),
      'Dec 28, 2026 – Jan 3, 2027',
    );
  });
}
