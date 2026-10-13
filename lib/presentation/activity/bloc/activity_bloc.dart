import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'activity_bloc.freezed.dart';
part 'activity_event.dart';
part 'activity_state.dart';

/// The full history: what matches the filter, searched by the user.
@injectable
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc(this._transactions, this._preferences, Clock clock)
    : super(ActivityState(today: _dateOnly(clock.now()))) {
    on<_Started>(_onStarted);
    on<_SearchChanged>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
    on<_FilterChanged>((event, emit) {
      emit(state.copyWith(filter: event.filter));
      add(ActivityEvent.entriesWatched(event.filter));
    });
    on<_SwipedAway>(_onSwipedAway);
    on<_DeletionUndone>(_onDeletionUndone);
    // A new filter replaces the old subscription.
    on<_EntriesWatched>(_onEntriesWatched, transformer: restartable());
  }

  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  static DateTime _dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  Future<void> _onStarted(_Started event, Emitter<ActivityState> emit) async {
    add(ActivityEvent.entriesWatched(state.filter));
    await emit.forEach(
      _preferences.watch(),
      onData: (result) => state.copyWith(
        preferences: result.getRight().toNullable() ?? state.preferences,
      ),
    );
  }

  Future<void> _onEntriesWatched(
    _EntriesWatched event,
    Emitter<ActivityState> emit,
  ) {
    return emit.forEach(
      _transactions.watchFiltered(event.filter),
      onData: (result) => state.copyWith(
        entries: result.getRight().toNullable() ?? state.entries,
      ),
    );
  }

  Future<void> _onSwipedAway(
    _SwipedAway event,
    Emitter<ActivityState> emit,
  ) async {
    final id = event.transaction.id;
    emit(state.copyWith(hiddenIds: {...state.hiddenIds, id}));

    final result = await _transactions.delete(id);
    // It's still there: show it again.
    if (result.isLeft()) {
      emit(state.copyWith(hiddenIds: {...state.hiddenIds}..remove(id)));
    }
  }

  Future<void> _onDeletionUndone(
    _DeletionUndone event,
    Emitter<ActivityState> emit,
  ) async {
    final transaction = event.transaction;
    await _transactions.restore(transaction);
    emit(
      state.copyWith(hiddenIds: {...state.hiddenIds}..remove(transaction.id)),
    );
  }
}
