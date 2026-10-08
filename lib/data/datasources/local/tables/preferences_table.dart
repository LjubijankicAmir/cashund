import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/drift.dart';

/// The user's preferences. Holds at most one row (`id` is always 1).
@DataClassName('PreferencesRow')
class PreferencesTable extends Table {
  @override
  String get tableName => 'preferences';

  /// Always 1, set by `PreferencesDao`, which keeps this table to one row.
  IntColumn get id => integer()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get buddyName =>
      text().withLength(min: 1, max: UserPreferences.buddyNameMaxLength)();
  TextColumn get weekStart => textEnum<WeekStart>()();
  BoolColumn get onboardingCompleted => boolean()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
