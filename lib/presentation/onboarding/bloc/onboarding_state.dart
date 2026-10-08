part of 'onboarding_bloc.dart';

enum OnboardingStatus { editing, saving, completed, failure }

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int step,
    @Default(LocaleDefaults.fallbackCurrencyCode) String currencyCode,
    @Default(UserPreferences.defaultBuddyName) String buddyName,
    @Default(LocaleDefaults.fallbackWeekStart) WeekStart weekStart,
    @Default(OnboardingStatus.editing) OnboardingStatus status,
  }) = _OnboardingState;

  const OnboardingState._();

  static const stepCount = 3;

  bool get isLastStep => step == stepCount - 1;
}
