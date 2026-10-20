part of 'limit_detail_bloc.dart';

@freezed
sealed class LimitDetailEvent with _$LimitDetailEvent {
  /// Follows the limit, its recent periods and this period's transactions.
  const factory LimitDetailEvent.started() = _Started;

  /// Undoes deleting one of this period's transactions.
  const factory LimitDetailEvent.transactionRestored(Transaction transaction) =
      _TransactionRestored;

  /// Internal: follows the data for the current currency and week start.
  const factory LimitDetailEvent.dataWatched() = _DataWatched;
}
