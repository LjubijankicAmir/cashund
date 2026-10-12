part of 'home_bloc.dart';

@freezed
sealed class HomeEvent with _$HomeEvent {
  /// Starts following the user's preferences.
  const factory HomeEvent.started() = _Started;

  const factory HomeEvent.periodSelected(Period period) = _PeriodSelected;

  /// The user closed the buddy's message.
  const factory HomeEvent.buddyMessageDismissed() = _BuddyMessageDismissed;

  /// Internal: follows the totals for [range] in [currencyCode].
  const factory HomeEvent.dataWatched(DateRange range, String currencyCode) =
      _DataWatched;
}
