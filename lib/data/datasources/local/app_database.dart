import 'package:cashund/data/datasources/local/app_database.steps.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:cashund/data/datasources/local/tables/preferences_table.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The app's single SQLite database. Tables are added by the features that
/// own them.
@DriftDatabase(tables: [PreferencesTable], daos: [PreferencesDao])
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests, e.g. `NativeDatabase.memory()`.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cashund'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.createTable(schema.preferences);
      },
    ),
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless they're enabled per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
