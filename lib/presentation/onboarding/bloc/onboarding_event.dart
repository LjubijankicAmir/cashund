part of 'onboarding_bloc.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  /// Seeds the choices with guesses for the user's region.
  const factory OnboardingEvent.started({
    required String currencyCode,
    required WeekStart weekStart,
  }) = _Started;

  const factory OnboardingEvent.nextPressed() = _NextPressed;
  const factory OnboardingEvent.backPressed() = _BackPressed;
  const factory OnboardingEvent.currencySelected(String currencyCode) =
      _CurrencySelected;
  const factory OnboardingEvent.buddyNameChanged(String buddyName) =
      _BuddyNameChanged;
  const factory OnboardingEvent.weekStartSelected(WeekStart weekStart) =
      _WeekStartSelected;

  /// Finishes right away, keeping the defaults for steps not visited yet.
  const factory OnboardingEvent.skipPressed() = _SkipPressed;

  /// Finishes after the last step.
  const factory OnboardingEvent.finishPressed() = _FinishPressed;
}
