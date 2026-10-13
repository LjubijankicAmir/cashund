part of 'activity_bloc.dart';

@freezed
abstract class ActivityState with _$ActivityState {
  const factory ActivityState({
    required DateTime today,
    @Default(TransactionFilter()) TransactionFilter filter,
    @Default('') String query,

    /// Matching the filter, before the search; `null` until loaded.
    List<TransactionWithCategory>? entries,

    /// `null` until the preferences are loaded.
    UserPreferences? preferences,

    /// Swiped away and being deleted. A swiped row has to leave the list
    /// at once, before the database catches up.
    @Default(<int>{}) Set<int> hiddenIds,
  }) = _ActivityState;

  const ActivityState._();

  /// The entries to show: matching the filter, minus the swiped-away ones.
  List<TransactionWithCategory>? get shownEntries => switch (entries) {
    final entries? => [
      for (final entry in entries)
        if (!hiddenIds.contains(entry.transaction.id)) entry,
    ],
    null => null,
  };
}
