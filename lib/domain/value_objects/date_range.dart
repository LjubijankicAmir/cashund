import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range.freezed.dart';

/// A span of whole days: from [start] up to, but not including, [end].
///
/// Both are local midnights. The end being exclusive keeps ranges simple to
/// compare and chain: one range's [end] is the next one's [start].
@freezed
abstract class DateRange with _$DateRange {
  const factory DateRange({required DateTime start, required DateTime end}) =
      _DateRange;

  const DateRange._();

  /// The last day inside the range.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}
