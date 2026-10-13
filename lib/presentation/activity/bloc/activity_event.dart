part of 'activity_bloc.dart';

@freezed
sealed class ActivityEvent with _$ActivityEvent {
  const factory ActivityEvent.started() = _Started;
  const factory ActivityEvent.searchChanged(String query) = _SearchChanged;

  /// Replaces the whole filter, e.g. from the filters sheet or a chip.
  const factory ActivityEvent.filterChanged(TransactionFilter filter) =
      _FilterChanged;

  /// Deletes [transaction] after a swipe, hiding it right away.
  const factory ActivityEvent.swipedAway(Transaction transaction) = _SwipedAway;

  /// Puts back a deleted transaction.
  const factory ActivityEvent.deletionUndone(Transaction transaction) =
      _DeletionUndone;

  /// Internal: follows the transactions matching [filter].
  const factory ActivityEvent.entriesWatched(TransactionFilter filter) =
      _EntriesWatched;
}
