import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:intl/intl.dart';

/// A range of days as compact text: "Oct 5 – 11", "Sep 28 – Oct 4", or with
/// the year on the end when it crosses into a new one.
String formatDateRange(DateRange range, String locale) {
  final first = range.start;
  final last = range.lastDay;

  if (first.year != last.year) {
    return '${DateFormat.yMMMd(locale).format(first)} – ${DateFormat.yMMMd(locale).format(last)}';
  }
  if (first.month != last.month) {
    return '${DateFormat.MMMd(locale).format(first)} – ${DateFormat.MMMd(locale).format(last)}';
  }
  return '${DateFormat.MMMd(locale).format(first)} – ${DateFormat.d(locale).format(last)}';
}
