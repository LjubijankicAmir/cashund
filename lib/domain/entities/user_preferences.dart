import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';

/// What the user chose during onboarding and can change in settings.
@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    /// ISO 4217 code of the currency all amounts are tracked in.
    required String currencyCode,
    required String buddyName,
    required WeekStart weekStart,
    required bool onboardingCompleted,
  }) = _UserPreferences;

  static const defaultBuddyName = 'Biscuit';
  static const buddyNameMaxLength = 16;
}
