part of 'home_bloc.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    required DateTime today,
    @Default(Period.week) Period period,

    /// Closed until the app restarts. Kept here rather than saved: dismissing
    /// for good needs message ids, which come with the buddy's messages.
    @Default(false) bool buddyMessageDismissed,

    /// `null` until loaded.
    UserPreferences? preferences,
  }) = _HomeState;

  const HomeState._();

  /// The days the overview covers, or `null` until preferences are loaded.
  DateRange? get range => switch (preferences) {
    final preferences? => period.rangeContaining(
      today,
      weekStart: preferences.weekStart,
    ),
    null => null,
  };
}
