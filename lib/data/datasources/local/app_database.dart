import 'package:cashund/data/datasources/local/app_database.steps.dart';
import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:cashund/data/datasources/local/daos/categories_dao.dart';
import 'package:cashund/data/datasources/local/daos/dismissed_messages_dao.dart';
import 'package:cashund/data/datasources/local/daos/limits_dao.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:cashund/data/datasources/local/daos/transactions_dao.dart';
import 'package:cashund/data/datasources/local/seed/predefined_categories.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/data/datasources/local/tables/dismissed_messages_table.dart';
import 'package:cashund/data/datasources/local/tables/limits_table.dart';
import 'package:cashund/data/datasources/local/tables/preferences_table.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The app's single SQLite database. Tables are added by the features that
/// own them.
@DriftDatabase(
  tables: [
    PreferencesTable,
    CategoriesTable,
    TransactionsTable,
    LimitsTable,
    LimitAmountsTable,
    DismissedMessagesTable,
  ],
  daos: [
    PreferencesDao,
    CategoriesDao,
    TransactionsDao,
    LimitsDao,
    DismissedMessagesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests, e.g. `NativeDatabase.memory()`.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'cashund'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await seedPredefinedCategories(this);
    },
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.createTable(schema.preferences);
      },
      from2To3: (migrator, schema) async {
        await migrator.createTable(schema.categories);
        await migrator.createTable(schema.transactions);
        await migrator.createIndex(schema.transactionsOccurredOn);
        await migrator.createIndex(schema.transactionsCategoryId);
        await seedPredefinedCategories(this);
      },
      from3To4: (migrator, schema) async {
        await migrator.addColumn(
          schema.preferences,
          schema.preferences.themePreference,
        );
      },
      from4To5: (migrator, schema) async {
        await migrator.addColumn(
          schema.preferences,
          schema.preferences.reactionFrequency,
        );
        await migrator.addColumn(
          schema.preferences,
          schema.preferences.reactionInterval,
        );
      },
      from5To6: (migrator, schema) async {
        await migrator.createTable(schema.limits);
        await migrator.createTable(schema.limitAmounts);
        await migrator.addColumn(
          schema.preferences,
          schema.preferences.limitsPromptDismissed,
        );
      },
      from6To7: (migrator, schema) async {
        await migrator.createTable(schema.dismissedMessages);
      },
    ),
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless they're enabled per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
