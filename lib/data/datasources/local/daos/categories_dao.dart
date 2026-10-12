import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable, TransactionsTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<CategoryRow>> watchActive(TransactionType type) {
    final query = select(categoriesTable)
      ..where(
        (category) =>
            category.type.equalsValue(type) & category.isArchived.not(),
      )
      ..orderBy([(category) => OrderingTerm(expression: category.sortOrder)]);
    return query.watch();
  }

  /// Categories of [type] by their latest transaction, newest first. Ids only
  /// grow, so the highest id is the most recently logged.
  Stream<List<CategoryRow>> watchRecent(TransactionType type, int limit) {
    return customSelect(
      'SELECT categories.* FROM categories '
      'JOIN (SELECT category_id, MAX(id) AS last_id FROM transactions WHERE type = ? GROUP BY category_id) recent '
      'ON recent.category_id = categories.id '
      'WHERE categories.is_archived = 0 '
      'ORDER BY recent.last_id DESC LIMIT ?',
      variables: [Variable.withString(type.name), Variable.withInt(limit)],
      readsFrom: {categoriesTable, transactionsTable},
    ).watch().map(
      (rows) => [for (final row in rows) categoriesTable.map(row.data)],
    );
  }
}
