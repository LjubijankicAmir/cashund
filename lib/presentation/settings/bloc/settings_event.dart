part of 'settings_bloc.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  /// Starts following the preferences and the counts shown in Settings.
  const factory SettingsEvent.started() = _Started;

  /// Switches right away when nothing is logged in the current currency yet;
  /// otherwise asks first, through [SettingsState.pendingCurrencyCode].
  const factory SettingsEvent.currencyChosen(String currencyCode) =
      _CurrencyChosen;
  const factory SettingsEvent.currencySwitchConfirmed() =
      _CurrencySwitchConfirmed;
  const factory SettingsEvent.currencySwitchCancelled() =
      _CurrencySwitchCancelled;

  const factory SettingsEvent.weekStartChosen(WeekStart weekStart) =
      _WeekStartChosen;
  const factory SettingsEvent.themeChosen(ThemePreference theme) = _ThemeChosen;

  /// A blank name falls back to the default one.
  const factory SettingsEvent.buddyNameSaved(String buddyName) =
      _BuddyNameSaved;

  /// Internal: follows how many transactions are in [currencyCode].
  const factory SettingsEvent.currencyCountWatched(String currencyCode) =
      _CurrencyCountWatched;
}
