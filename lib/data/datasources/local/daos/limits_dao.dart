import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/data/datasources/local/tables/limits_table.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:drift/drift.dart';

part 'limits_dao.g.dart';

/// A limit with its category (`null` for the overall limit), its amount for
/// a period and what was spent in it.
typedef LimitSpendingRow = ({
  LimitRow limit,
  CategoryRow? category,
  int amountMinor,
  int spentMinor,
});

@DriftAccessor(
  tables: [LimitsTable, LimitAmountsTable, CategoriesTable, TransactionsTable],
)
class LimitsDao extends DatabaseAccessor<AppDatabase> with _$LimitsDaoMixin {
  LimitsDao(super.attachedDatabase);

  static const _dates = DateOnlyConverter();

  /// `l.id AS "l.id", ...`, so a joined row can be read back per table.
  static String _prefixed(String alias, TableInfo<Table, Object?> table) => [
    for (final column in table.$columns)
      '$alias.${column.name} AS "$alias.${column.name}"',
  ].join(', ');

  /// The [period] limits in [currencyCode] with their amount and spending in
  /// [range]. Limits on archived categories are left out, and so are limits
  /// created after the range began.
  Stream<List<LimitSpendingRow>> watchSpending({
    required LimitPeriod period,
    required String currencyCode,
    required DateRange range,
  }) {
    final start = _dates.toSql(range.start);
    final end = _dates.toSql(range.end);

    return customSelect(
      'SELECT ${_prefixed('l', limitsTable)}, ${_prefixed('c', categoriesTable)}, '
      '(SELECT a.amount_minor FROM limit_amounts a WHERE a.limit_id = l.id '
      'AND a.effective_from <= ? ORDER BY a.effective_from DESC LIMIT 1) AS amount, '
      '(SELECT COALESCE(SUM(t.amount_minor), 0) FROM transactions t '
      "WHERE t.type = 'expense' AND t.currency_code = l.currency_code "
      'AND t.occurred_on >= ? AND t.occurred_on < ? '
      'AND (l.category_id IS NULL OR t.category_id = l.category_id)) AS spent '
      'FROM limits l LEFT JOIN categories c ON c.id = l.category_id '
      'WHERE l.period = ? AND l.currency_code = ? '
      'AND (c.id IS NULL OR c.is_archived = 0) AND amount IS NOT NULL',
      variables: [
        Variable.withString(start),
        Variable.withString(start),
        Variable.withString(end),
        Variable.withString(period.name),
        Variable.withString(currencyCode),
      ],
      readsFrom: {
        limitsTable,
        limitAmountsTable,
        categoriesTable,
        transactionsTable,
      },
    ).watch().map(
      (rows) => [
        for (final row in rows)
          (
            limit: limitsTable.map(row.data, tablePrefix: 'l'),
            category: row.data['c.id'] == null
                ? null
                : categoriesTable.map(row.data, tablePrefix: 'c'),
            amountMinor: row.read<int>('amount'),
            spentMinor: row.read<int>('spent'),
          ),
      ],
    );
  }

  /// Every limit in [currencyCode] whose category isn't archived.
  Stream<List<LimitRow>> watchAll(String currencyCode) {
    final query =
        select(limitsTable).join([
          leftOuterJoin(
            categoriesTable,
            categoriesTable.id.equalsExp(limitsTable.categoryId),
          ),
        ])..where(
          limitsTable.currencyCode.equals(currencyCode) &
              (categoriesTable.id.isNull() | categoriesTable.isArchived.not()),
        );
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(limitsTable)],
    );
  }

  Stream<LimitRow?> watchById(int id) =>
      (select(limitsTable)..where((l) => l.id.equals(id))).watchSingleOrNull();

  Future<LimitRow?> findById(int id) =>
      (select(limitsTable)..where((l) => l.id.equals(id))).getSingleOrNull();

  /// The overall limit for [period] in [currencyCode], if there is one.
  Future<LimitRow?> findOverall(LimitPeriod period, String currencyCode) {
    final query = select(limitsTable)
      ..where(
        (l) =>
            l.categoryId.isNull() &
            l.period.equalsValue(period) &
            l.currencyCode.equals(currencyCode),
      );
    return query.getSingleOrNull();
  }

  Stream<List<LimitAmountRow>> watchAmounts(int limitId) =>
      _amountsQuery(limitId).watch();

  Future<List<LimitAmountRow>> amounts(int limitId) =>
      _amountsQuery(limitId).get();

  SimpleSelectStatement<$LimitAmountsTableTable, LimitAmountRow> _amountsQuery(
    int limitId,
  ) {
    return select(limitAmountsTable)
      ..where((a) => a.limitId.equals(limitId))
      ..orderBy([(a) => OrderingTerm(expression: a.effectiveFrom)]);
  }

  /// Inserts a limit with its first amount, at once.
  Future<LimitRow> insert(
    LimitsTableCompanion limit, {
    required LimitAmountsTableCompanion Function(int limitId) amount,
  }) {
    return transaction(() async {
      final row = await into(limitsTable).insertReturning(limit);
      await into(limitAmountsTable).insert(amount(row.id));
      return row;
    });
  }

  /// Sets the amount from a period on, replacing one set for that period.
  Future<void> upsertAmount(LimitAmountsTableCompanion amount) =>
      into(limitAmountsTable).insertOnConflictUpdate(amount);

  /// Deletes a limit; its amounts go with it.
  Future<void> deleteById(int id) =>
      (delete(limitsTable)..where((l) => l.id.equals(id))).go();

  /// Puts back a deleted limit and its amounts as they were.
  Future<void> restore(LimitRow limit, List<LimitAmountRow> amounts) {
    return transaction(() async {
      await into(limitsTable).insert(limit);
      await batch((batch) => batch.insertAll(limitAmountsTable, amounts));
    });
  }
}
