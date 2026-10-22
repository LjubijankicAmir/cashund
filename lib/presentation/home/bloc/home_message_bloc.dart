import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/dismissed_message_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'home_message_bloc.freezed.dart';
part 'home_message_event.dart';
part 'home_message_state.dart';

/// Home's priority messages: limit warnings and recaps of the last week
/// and month.
@injectable
class HomeMessageBloc extends Bloc<HomeMessageEvent, HomeMessageState> {
  HomeMessageBloc(
    this._limits,
    this._transactions,
    this._preferences,
    this._dismissed,
    Clock clock,
  ) : super(HomeMessageState(today: clock.now())) {
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
          _dismissed.watchAll(),
          onData: (result) => state.copyWith(
            dismissed: result.getRight().toNullable() ?? state.dismissed,
          ),
        ),
      ]),
    );
    on<_Closed>(
      (event, emit) =>
          _dismissed.dismiss(HomeMessages.keyOf(event.message), state.today),
    );
    on<_DataWatched>(_onDataWatched, transformer: restartable());
  }

  final LimitRepository _limits;
  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;
  final DismissedMessageRepository _dismissed;

  (String, Object)? _watching;

  void _watchFor(HomeMessageState state) {
    final preferences = state.preferences;
    if (preferences == null) return;
    final key = (preferences.currencyCode, preferences.weekStart);
    if (key == _watching) return;
    _watching = key;
    add(const HomeMessageEvent.dataWatched());
  }

  Future<void> _onDataWatched(
    _DataWatched event,
    Emitter<HomeMessageState> emit,
  ) async {
    final preferences = state.preferences;
    if (preferences == null) return;
    final currencyCode = preferences.currencyCode;

    Iterable<Future<void>> follow(LimitPeriod period) {
      final [beforeLast, last, current] = period.rangesUpTo(
        state.today,
        weekStart: preferences.weekStart,
        count: 3,
      );

      HomeMessageState recap(RecapData Function(RecapData) change) {
        final data = state.recaps[period] ?? RecapData(range: last);
        return state.copyWith(recaps: {...state.recaps, period: change(data)});
      }

      return [
        emit.forEach(
          _limits.watchProgress(
            period: period,
            currencyCode: currencyCode,
            range: current,
          ),
          onData: (result) => switch (result.getRight().toNullable()) {
            final limits? => state.copyWith(
              limits: {...state.limits, period: limits},
            ),
            null => state,
          },
        ),
        emit.forEach(
          _transactions.watchSummary(last, currencyCode: currencyCode),
          onData: (result) => switch (result.getRight().toNullable()) {
            final summary? => recap((data) => data.copyWith(summary: summary)),
            null => state,
          },
        ),
        emit.forEach(
          _transactions.watchSummary(beforeLast, currencyCode: currencyCode),
          onData: (result) => switch (result.getRight().toNullable()) {
            final summary? => recap(
              (data) => data.copyWith(previousSpentMinor: summary.expenseMinor),
            ),
            null => state,
          },
        ),
        emit.forEach(
          _transactions.watchSpendingByCategory(
            last,
            currencyCode: currencyCode,
          ),
          onData: (result) => switch (result.getRight().toNullable()) {
            final spending? => recap(
              (data) => data.copyWith(top: spending.firstOrNull),
            ),
            null => state,
          },
        ),
        emit.forEach(
          _limits.watchProgress(
            period: period,
            currencyCode: currencyCode,
            range: last,
          ),
          onData: (result) => switch (result.getRight().toNullable()) {
            final limits? => recap((data) => data.copyWith(limits: limits)),
            null => state,
          },
        ),
      ];
    }

    await Future.wait([
      ...follow(LimitPeriod.week),
      ...follow(LimitPeriod.month),
    ]);
  }
}
