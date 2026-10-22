import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/period_totals.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'insights_bloc.freezed.dart';
part 'insights_event.dart';
part 'insights_state.dart';

/// Insights: one week, month or year at a time.
@injectable
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc(this._transactions, this._preferences, Clock clock)
    : super(InsightsState(today: clock.now())) {
    on<_Started>((event, emit) {
      emit(state.copyWith(period: event.period));
      return emit.forEach(
        _preferences.watch(),
        onData: (result) {
          final preferences =
              result.getRight().toNullable() ?? state.preferences;
          var next = state.copyWith(preferences: preferences);
          if (next.range == null && preferences != null) {
            next = next.copyWith(range: _currentRange(next));
          }
          _watchFor(next);
          return next;
        },
      );
    });
    on<_PeriodSelected>((event, emit) {
      if (event.period == state.period) return;
      _show(emit, state.copyWith(period: event.period), _currentRange);
    });
    on<_PreviousPressed>((event, emit) {
      if (!state.canGoBack) return;
      _show(
        emit,
        state,
        (s) => s.period.previous(s.range!, weekStart: s.preferences!.weekStart),
      );
    });
    on<_NextPressed>((event, emit) {
      if (!state.canGoForward) return;
      _show(
        emit,
        state,
        (s) => s.period.next(s.range!, weekStart: s.preferences!.weekStart),
      );
    });
    on<_JumpedToData>((event, emit) {
      final target = state.dataRange;
      if (target != null) _show(emit, state, (_) => target);
    });
    // A new range or currency replaces the old subscriptions.
    on<_DataWatched>(_onDataWatched, transformer: restartable());
  }

  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  (String, InsightsPeriod, DateRange)? _watching;

  static DateRange? _currentRange(InsightsState state) =>
      switch (state.preferences) {
        final preferences? => state.period.rangeContaining(
          state.today,
          weekStart: preferences.weekStart,
        ),
        null => null,
      };

  void _show(
    Emitter<InsightsState> emit,
    InsightsState base,
    DateRange? Function(InsightsState) rangeOf,
  ) {
    if (base.preferences == null) return;
    final next = base.copyWith(range: rangeOf(base), summary: null);
    emit(next);
    _watchFor(next);
  }

  void _watchFor(InsightsState state) {
    final (range, preferences) = (state.range, state.preferences);
    if (range == null || preferences == null) return;
    final key = (preferences.currencyCode, state.period, range);
    if (key == _watching) return;
    _watching = key;
    add(const InsightsEvent.dataWatched());
  }

  Future<void> _onDataWatched(
    _DataWatched event,
    Emitter<InsightsState> emit,
  ) async {
    final (range, preferences) = (state.range, state.preferences);
    if (range == null || preferences == null) return;
    final currencyCode = preferences.currencyCode;
    final trend = state.trendRanges;

    await Future.wait([
      emit.forEach(
        _transactions.watchSummary(range, currencyCode: currencyCode),
        onData: (result) => state.copyWith(
          summary: result.getRight().toNullable() ?? state.summary,
        ),
      ),
      emit.forEach(
        _transactions.watchSpendingByCategory(
          range,
          currencyCode: currencyCode,
        ),
        onData: (result) => state.copyWith(
          spending: result.getRight().toNullable() ?? state.spending,
        ),
      ),
      emit.forEach(
        _transactions.watchExpensesByDay(
          DateRange(start: trend.first.start, end: trend.last.end),
          currencyCode: currencyCode,
        ),
        onData: (result) => state.copyWith(
          expensesByDay: result.getRight().toNullable() ?? state.expensesByDay,
        ),
      ),
      emit.forEach(
        _transactions.watchFirstDay(currencyCode),
        onData: (result) => result.isRight()
            ? state.copyWith(firstDay: result.getRight().toNullable())
            : state,
      ),
    ]);
  }
}
