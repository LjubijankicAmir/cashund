import 'package:drift/drift.dart';

/// Stores a calendar date as text, e.g. "2026-10-08".
///
/// A date isn't a moment in time: as a timestamp, it could shift a day when
/// read in another time zone.
class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromSql(String fromDb) {
    final [year, month, day] = fromDb.split('-').map(int.parse).toList();
    return DateTime(year, month, day);
  }

  @override
  String toSql(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}';
  }
}
