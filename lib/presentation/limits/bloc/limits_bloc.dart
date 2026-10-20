import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'limits_bloc.freezed.dart';
part 'limits_event.dart';
part 'limits_state.dart';

/// The Limits page: one period at a time, with this period's progress.
@injectable
class LimitsBloc extends Bloc<LimitsEvent, LimitsState> {
  LimitsBloc(this._limits, this._preferences, Clock clock)
    : super(LimitsState(today: clock.now())) {
    on<_Started>((event, emit) {
      emit(state.copyWith(period: event.period));
      return emit.forEach(
        _preferences.watch(),
        onData: (result) {
          final next = state.copyWith(
            preferences: result.getRight().toNullable() ?? state.preferences,
          );
          _watchFor(next);
          return next;
        },
      );
    });
    on<_PeriodSelected>((event, emit) {
      if (event.period == state.period) return;
      emit(state.copyWith(period: event.period, progress: null));
      _watchFor(state);
    });
    on<_Restored>((event, emit) async {
      final restored = await _limits.restore(event.snapshot);
      emit(state.copyWith(restoreFailed: restored.isLeft()));
    });
    // A new period or currency replaces the old subscriptions.
    on<_LimitsWatched>(_onLimitsWatched, transformer: restartable());
  }

  final LimitRepository _limits;
  final PreferencesRepository _preferences;

  /// What the subscriptions follow, to restart them only when it changes.
  (LimitPeriod, String, DateRange)? _watching;

  void _watchFor(LimitsState state) {
    final (range, preferences) = (state.range, state.preferences);
    if (range == null || preferences == null) return;
    final key = (state.period, preferences.currencyCode, range);
    if (key == _watching) return;
    _watching = key;
    add(const LimitsEvent.limitsWatched());
  }

  Future<void> _onLimitsWatched(
    _LimitsWatched event,
    Emitter<LimitsState> emit,
  ) async {
    final (range, preferences) = (state.range, state.preferences);
    if (range == null || preferences == null) return;

    await Future.wait([
      emit.forEach(
        _limits.watchProgress(
          period: state.period,
          currencyCode: preferences.currencyCode,
          range: range,
        ),
        onData: (result) => state.copyWith(
          progress: result.getRight().toNullable() ?? state.progress,
        ),
      ),
      emit.forEach(
        _limits.watchAll(preferences.currencyCode),
        onData: (result) => state.copyWith(
          limitCount:
              result.getRight().toNullable()?.length ?? state.limitCount,
        ),
      ),
    ]);
  }
}
