import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
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
    @Default(ThemePreference.system) ThemePreference themePreference,
    @Default(ReactionFrequency.always) ReactionFrequency reactionFrequency,

    /// With [ReactionFrequency.sometimes], the buddy reacts to every n-th
    /// transaction.
    @Default(UserPreferences.defaultReactionInterval) int reactionInterval,

    /// The user said "Not now" to setting a limit, so Home stops asking.
    @Default(false) bool limitsPromptDismissed,

    /// When a backup was last shared; `null` before the first.
    DateTime? lastBackupAt,
  }) = _UserPreferences;

  static const defaultBuddyName = 'Biscuit';
  static const buddyNameMaxLength = 16;

  static const defaultReactionInterval = 3;
  static const minReactionInterval = 2;
  static const maxReactionInterval = 10;
}
