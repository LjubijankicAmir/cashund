import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._preferences, this._transactions, this._limits, Clock clock)
    : super(HomeState(today: clock.now())) {
    on<_Started>(
      (event, emit) => Future.wait([
        _followPreferences(emit),
        emit.forEach(
          _transactions.watchHasAny(),
          onData: (result) => state.copyWith(
            hasTransactions:
                result.getRight().toNullable() ?? state.hasTransactions,
          ),
        ),
      ]),
    );
    on<_PeriodSelected>((event, emit) {
      emit(state.copyWith(period: event.period));
      _watchDataFor(state);
    });
    on<_BuddyMessageDismissed>(
      (event, emit) => emit(state.copyWith(buddyMessageDismissed: true)),
    );
    on<_LimitsPromptDismissed>((event, emit) async {
      final preferences = state.preferences;
      if (preferences == null) return;
      // Saved; the preferences stream brings the change back.
      await _preferences.save(
        preferences.copyWith(limitsPromptDismissed: true),
      );
    });
    // A new period or currency replaces the old subscription.
    on<_DataWatched>(_onDataWatched, transformer: restartable());
  }

  final PreferencesRepository _preferences;
  final TransactionRepository _transactions;
  final LimitRepository _limits;

  /// What the data subscription currently follows, to avoid restarting it
  /// for unrelated changes like a renamed buddy.
  (DateRange, String)? _watching;

  /// Keeps the state in sync with the saved preferences, e.g. after the
  /// buddy is renamed in Settings. A failed read keeps what's already shown.
  Future<void> _followPreferences(Emitter<HomeState> emit) {
    return emit.forEach(
      _preferences.watch(),
      onData: (result) {
        final next = state.copyWith(
          preferences: result.getRight().toNullable() ?? state.preferences,
        );
        _watchDataFor(next);
        return next;
      },
    );
  }

  void _watchDataFor(HomeState state) {
    final (range, currencyCode) = (
      state.range,
      state.preferences?.currencyCode,
    );
    if (range == null ||
        currencyCode == null ||
        _watching == (range, currencyCode)) {
      return;
    }
    _watching = (range, currencyCode);
    add(HomeEvent.dataWatched(range, currencyCode));
  }

  Future<void> _onDataWatched(
    _DataWatched event,
    Emitter<HomeState> emit,
  ) async {
    await Future.wait([
      emit.forEach(
        _transactions.watchSummary(
          event.range,
          currencyCode: event.currencyCode,
        ),
        onData: (result) => state.copyWith(
          summary: result.getRight().toNullable() ?? state.summary,
        ),
      ),
      emit.forEach(
        _limits.watchProgress(
          period: state.limitPeriod,
          currencyCode: event.currencyCode,
          range: state.limitPeriod.rangeContaining(
            state.today,
            weekStart: state.preferences!.weekStart,
          ),
        ),
        onData: (result) => switch (result.getRight().toNullable()) {
          final limits? => state.copyWith(
            limits: [
              for (final limit in limits)
                if (!limit.limit.isOverall) limit,
            ].take(HomeState.limitsShown).toList(),
          ),
          null => state,
        },
      ),
      emit.forEach(
        _transactions.watchSpendingByCategory(
          event.range,
          currencyCode: event.currencyCode,
        ),
        onData: (result) => switch (result.getRight().toNullable()) {
          final spending? => state.copyWith(
            slices: SpendingBreakdown.slicesOf(spending),
          ),
          null => state,
        },
      ),
    ]);
  }
}
