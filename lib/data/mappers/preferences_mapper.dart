import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:drift/drift.dart';

extension PreferencesRowMapper on PreferencesRow {
  UserPreferences toEntity() {
    return UserPreferences(
      currencyCode: currencyCode,
      buddyName: buddyName,
      weekStart: weekStart,
      onboardingCompleted: onboardingCompleted,
      themePreference: themePreference,
      reactionFrequency: reactionFrequency,
      reactionInterval: reactionInterval,
      limitsPromptDismissed: limitsPromptDismissed,
    );
  }
}

extension UserPreferencesMapper on UserPreferences {
  PreferencesTableCompanion toCompanion() {
    return PreferencesTableCompanion.insert(
      currencyCode: currencyCode,
      buddyName: buddyName,
      weekStart: weekStart,
      onboardingCompleted: onboardingCompleted,
      themePreference: Value(themePreference),
      reactionFrequency: Value(reactionFrequency),
      reactionInterval: Value(reactionInterval),
      limitsPromptDismissed: Value(limitsPromptDismissed),
    );
  }
}
