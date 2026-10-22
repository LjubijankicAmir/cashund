part of 'export_bloc.dart';

enum ExportOption { allTime, thisMonth, lastMonth, custom }

enum ExportStatus { editing, working, shared, failed }

@freezed
abstract class ExportState with _$ExportState {
  const factory ExportState({
    required DateTime today,

    /// The custom range's first and last day.
    required DateTime customFrom,
    required DateTime customTo,
    @Default(ExportOption.allTime) ExportOption option,

    /// How many transactions each option holds, as they load.
    @Default(<ExportOption, int>{}) Map<ExportOption, int> counts,
    @Default(ExportStatus.editing) ExportStatus status,
  }) = _ExportState;

  const ExportState._();

  factory ExportState.initial(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return ExportState(
      today: today,
      customFrom: DateTime(today.year, today.month - 1),
      customTo: today,
    );
  }

  /// The days [option] covers; `null` for all time.
  DateRange? rangeOf(ExportOption option) => switch (option) {
    ExportOption.allTime => null,
    ExportOption.thisMonth => DateRange(
      start: DateTime(today.year, today.month),
      end: DateTime(today.year, today.month + 1),
    ),
    ExportOption.lastMonth => DateRange(
      start: DateTime(today.year, today.month - 1),
      end: DateTime(today.year, today.month),
    ),
    ExportOption.custom => DateRange(
      start: customFrom,
      end: DateTime(customTo.year, customTo.month, customTo.day + 1),
    ),
  };

  int get count => counts[option] ?? 0;

  bool get canExport => count > 0 && status != ExportStatus.working;
}
