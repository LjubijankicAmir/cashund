import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/seed/predefined_categories.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/data/datasources/local/tables/dismissed_messages_table.dart';
import 'package:cashund/data/datasources/local/tables/limits_table.dart';
import 'package:cashund/data/datasources/local/tables/preferences_table.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:cashund/data/dtos/backup_dto.dart';
import 'package:drift/drift.dart';

part 'backup_dao.g.dart';

/// The whole database at once: for backups, restores and starting over.
@DriftAccessor(
  tables: [
    PreferencesTable,
    CategoriesTable,
    TransactionsTable,
    LimitsTable,
    LimitAmountsTable,
    DismissedMessagesTable,
  ],
)
class BackupDao extends DatabaseAccessor<AppDatabase> with _$BackupDaoMixin {
  BackupDao(super.attachedDatabase);

  /// Everything, read in one transaction so it's consistent.
  Future<BackupDto> dump(DateTime createdAt) {
    return transaction(
      () async => BackupDto(
        schemaVersion: attachedDatabase.schemaVersion,
        createdAt: createdAt,
        preferences: await select(preferencesTable).get(),
        categories: await select(categoriesTable).get(),
        transactions: await select(transactionsTable).get(),
        limits: await select(limitsTable).get(),
        limitAmounts: await select(limitAmountsTable).get(),
        dismissedMessages: await select(dismissedMessagesTable).get(),
      ),
    );
  }

  /// Replaces everything with [backup]. All or nothing: if anything fails,
  /// what was there stays.
  Future<void> replaceWith(BackupDto backup) {
    return transaction(() async {
      await _deleteAll();
      await batch((batch) {
        // Parents before children, for the foreign keys.
        batch
          ..insertAll(preferencesTable, backup.preferences)
          ..insertAll(categoriesTable, backup.categories)
          ..insertAll(transactionsTable, backup.transactions)
          ..insertAll(limitsTable, backup.limits)
          ..insertAll(limitAmountsTable, backup.limitAmounts)
          ..insertAll(dismissedMessagesTable, backup.dismissedMessages);
      });
    });
  }

  /// Deletes everything and puts back the built-in categories, as on a
  /// fresh install. Without preferences, the app starts with onboarding.
  Future<void> wipe() {
    return transaction(() async {
      await _deleteAll();
      await seedPredefinedCategories(attachedDatabase);
    });
  }

  /// Children before parents, for the foreign keys.
  Future<void> _deleteAll() async {
    for (final table in <TableInfo<Table, Object?>>[
      limitAmountsTable,
      limitsTable,
      transactionsTable,
      categoriesTable,
      preferencesTable,
      dismissedMessagesTable,
    ]) {
      await delete(table).go();
    }
  }

  /// How many transactions, categories and limits there are.
  Stream<({int transactions, int categories, int limits})> watchCounts() {
    return customSelect(
      'SELECT (SELECT COUNT(*) FROM transactions) AS transactions, '
      '(SELECT COUNT(*) FROM categories) AS categories, '
      '(SELECT COUNT(*) FROM limits) AS limits',
      readsFrom: {transactionsTable, categoriesTable, limitsTable},
    ).watchSingle().map(
      (row) => (
        transactions: row.read<int>('transactions'),
        categories: row.read<int>('categories'),
        limits: row.read<int>('limits'),
      ),
    );
  }
}
