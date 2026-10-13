part of 'settings_bloc.dart';

enum SettingsStatus { idle, saving, saved, failure }

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    /// `null` until loaded.
    UserPreferences? preferences,
    ({int expense, int income})? categoryCounts,

    /// Transactions logged in the current currency, which stay in it when
    /// the user switches.
    @Default(0) int transactionsInCurrency,

    /// A currency waiting for the user to confirm the switch.
    String? pendingCurrencyCode,
    @Default(SettingsStatus.idle) SettingsStatus status,
  }) = _SettingsState;
}
