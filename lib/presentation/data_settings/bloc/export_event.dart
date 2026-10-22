part of 'export_bloc.dart';

@freezed
sealed class ExportEvent with _$ExportEvent {
  /// Counts the transactions each option would export.
  const factory ExportEvent.started() = _Started;
  const factory ExportEvent.optionSelected(ExportOption option) =
      _OptionSelected;

  /// Days inclusive, for the custom range.
  const factory ExportEvent.customRangeChanged({
    required DateTime from,
    required DateTime to,
  }) = _CustomRangeChanged;

  /// Writes the CSV and offers it in the share sheet. [categoryName] names
  /// categories the way the user sees them.
  const factory ExportEvent.exportPressed(
    String Function(Category category) categoryName,
  ) = _ExportPressed;

  /// Internal: counts the custom range's transactions.
  const factory ExportEvent.customCounted() = _CustomCounted;
}
