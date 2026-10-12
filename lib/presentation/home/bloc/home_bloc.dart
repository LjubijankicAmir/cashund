import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._preferences, Clock clock)
    : super(HomeState(today: clock.now())) {
    on<HomeEvent>(
      (event, emit) => switch (event) {
        _Started() => _followPreferences(emit),
        _PeriodSelected(:final period) => emit(state.copyWith(period: period)),
        _BuddyMessageDismissed() => emit(
          state.copyWith(buddyMessageDismissed: true),
        ),
      },
    );
  }

  final PreferencesRepository _preferences;

  /// Keeps the state in sync with the saved preferences, e.g. after the
  /// buddy is renamed in Settings. A failed read keeps what's already shown.
  Future<void> _followPreferences(Emitter<HomeState> emit) {
    return emit.forEach(
      _preferences.watch(),
      onData: (result) => state.copyWith(
        preferences: result.getRight().toNullable() ?? state.preferences,
      ),
    );
  }
}
