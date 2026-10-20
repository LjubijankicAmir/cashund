import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/limit_history.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Right;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'limit_detail_bloc.freezed.dart';
part 'limit_detail_event.dart';
part 'limit_detail_state.dart';

/// One limit: this period's progress, recent periods and transactions.
@injectable
class LimitDetailBloc extends Bloc<LimitDetailEvent, LimitDetailState> {
  LimitDetailBloc(
    @factoryParam SpendingLimit limit,
    this._limits,
    this._transactions,
    this._preferences,
    Clock clock,
  ) : super(LimitDetailState(today: clock.now(), limit: limit)) {
    on<_Started>(
      (event, emit) => Future.wait([
        emit.forEach(
          _preferences.watch(),
          onData: (result) {
            final next = state.copyWith(
              preferences: result.getRight().toNullable() ?? state.preferences,
            );
            _watchFor(next);
            return next;
          },
        ),
        emit.forEach(
          _limits.watch(limit.id),
          onData: (result) => switch (result) {
            // Gone, e.g. deleted from the editor.
            Right(value: null) => state.copyWith(isDeleted: true),
            _ => state,
          },
        ),
        emit.forEach(
          _limits.watchAmounts(limit.id),
          onData: (result) => state.copyWith(
            amounts: result.getRight().toNullable() ?? state.amounts,
          ),
        ),
      ]),
    );
    on<_TransactionRestored>(
      (event, emit) => _transactions.restore(event.transaction),
    );
    on<_DataWatched>(_onDataWatched, transformer: restartable());
  }

  final LimitRepository _limits;
  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  (String, List<DateRange>)? _watching;

  void _watchFor(LimitDetailState state) {
    final (preferences, ranges) = (state.preferences, state.ranges);
    if (preferences == null || ranges.isEmpty) return;
    final key = (preferences.currencyCode, ranges);
    if (key == _watching) return;
    _watching = key;
    add(const LimitDetailEvent.dataWatched());
  }

  Future<void> _onDataWatched(
    _DataWatched event,
    Emitter<LimitDetailState> emit,
  ) async {
    final (preferences, ranges, limit) = (
      state.preferences,
      state.ranges,
      state.limit,
    );
    if (preferences == null || ranges.isEmpty) return;
    final current = ranges.last;
    final categoryId = limit.categoryId;

    await Future.wait([
      emit.forEach(
        _limits.watchProgress(
          period: limit.period,
          currencyCode: preferences.currencyCode,
          range: current,
        ),
        onData: (result) {
          for (final progress
              in result.getRight().toNullable() ?? const <LimitProgress>[]) {
            if (progress.limit.id == limit.id) {
              return state.copyWith(progress: progress);
            }
          }
          return state;
        },
      ),
      emit.forEach(
        _transactions.watchExpensesByDay(
          DateRange(start: ranges.first.start, end: current.end),
          currencyCode: preferences.currencyCode,
          categoryId: categoryId,
        ),
        onData: (result) => state.copyWith(
          spentByDay: result.getRight().toNullable() ?? state.spentByDay,
        ),
      ),
      emit.forEach(
        _transactions.watchFiltered(
          TransactionFilter(
            type: TransactionType.expense,
            categoryIds: {?categoryId},
            range: current,
          ),
        ),
        onData: (result) => state.copyWith(
          transactions: [
            // Only this limit's currency counts, like everywhere else.
            for (final entry
                in result.getRight().toNullable() ?? state.transactions)
              if (entry.transaction.currencyCode == preferences.currencyCode)
                entry,
          ],
        ),
      ),
    ]);
  }
}
