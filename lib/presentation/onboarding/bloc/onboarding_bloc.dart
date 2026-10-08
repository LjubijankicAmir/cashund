import 'package:cashund/core/locale/locale_defaults.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'onboarding_bloc.freezed.dart';
part 'onboarding_event.dart';
part 'onboarding_state.dart';

@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._preferences) : super(const OnboardingState()) {
    on<OnboardingEvent>(
      (event, emit) => switch (event) {
        _Started(:final currencyCode, :final weekStart) => emit(
          state.copyWith(currencyCode: currencyCode, weekStart: weekStart),
        ),
        _NextPressed() => emit(
          state.copyWith(
            step: (state.step + 1).clamp(0, OnboardingState.stepCount - 1),
          ),
        ),
        _BackPressed() => emit(
          state.copyWith(
            step: (state.step - 1).clamp(0, OnboardingState.stepCount - 1),
          ),
        ),
        _CurrencySelected(:final currencyCode) => emit(
          state.copyWith(currencyCode: currencyCode),
        ),
        _BuddyNameChanged(:final buddyName) => emit(
          state.copyWith(buddyName: buddyName),
        ),
        _WeekStartSelected(:final weekStart) => emit(
          state.copyWith(weekStart: weekStart),
        ),
        _SkipPressed() || _FinishPressed() => _complete(emit),
      },
    );
  }

  final PreferencesRepository _preferences;

  Future<void> _complete(Emitter<OnboardingState> emit) async {
    if (state.status == OnboardingStatus.saving) return;
    emit(state.copyWith(status: OnboardingStatus.saving));

    final buddyName = state.buddyName.trim();
    final result = await _preferences.save(
      UserPreferences(
        currencyCode: state.currencyCode,
        buddyName: buddyName.isEmpty
            ? UserPreferences.defaultBuddyName
            : buddyName,
        weekStart: state.weekStart,
        onboardingCompleted: true,
      ),
    );

    emit(
      state.copyWith(
        status: result.isRight()
            ? OnboardingStatus.completed
            : OnboardingStatus.failure,
      ),
    );
  }
}
