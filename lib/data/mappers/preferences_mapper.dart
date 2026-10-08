import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/user_preferences.dart';

extension PreferencesRowMapper on PreferencesRow {
  UserPreferences toEntity() {
    return UserPreferences(
      currencyCode: currencyCode,
      buddyName: buddyName,
      weekStart: weekStart,
      onboardingCompleted: onboardingCompleted,
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
    );
  }
}
