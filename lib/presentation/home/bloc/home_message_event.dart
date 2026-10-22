part of 'home_message_bloc.dart';

@freezed
sealed class HomeMessageEvent with _$HomeMessageEvent {
  /// Follows limits, recaps and closed messages.
  const factory HomeMessageEvent.started() = _Started;

  /// The user closed [message], or acted on it; it stays closed.
  const factory HomeMessageEvent.closed(HomeMessage message) = _Closed;

  /// Internal: follows the data for the current currency and week start.
  const factory HomeMessageEvent.dataWatched() = _DataWatched;
}
