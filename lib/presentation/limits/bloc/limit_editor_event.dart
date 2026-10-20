part of 'limit_editor_bloc.dart';

@freezed
sealed class LimitEditorEvent with _$LimitEditorEvent {
  /// Opens on [period] for a new limit, or on [editing] to change it.
  const factory LimitEditorEvent.started({
    required LimitPeriod period,
    LimitProgress? editing,
  }) = _Started;

  /// New limits only; an existing limit keeps its period.
  const factory LimitEditorEvent.periodChanged(LimitPeriod period) =
      _PeriodChanged;

  /// New limits only; an existing limit keeps its category.
  const factory LimitEditorEvent.targetChosen(LimitTarget target) =
      _TargetChosen;
  const factory LimitEditorEvent.amountChanged(String text) = _AmountChanged;
  const factory LimitEditorEvent.savePressed() = _SavePressed;
  const factory LimitEditorEvent.deletePressed() = _DeletePressed;

  /// Internal: follows this period's spending on the chosen target.
  const factory LimitEditorEvent.previewWatched() = _PreviewWatched;
}
