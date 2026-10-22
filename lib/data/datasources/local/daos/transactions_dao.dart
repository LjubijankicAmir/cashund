import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, CategoriesTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  static const _dates = DateOnlyConverter();

  Future<TransactionRow> insert(TransactionsTableCompanion row) =>
      into(transactionsTable).insertReturning(row);

  /// Whether anything has been logged at all.
  Stream<bool> watchHasAny() {
    return customSelect(
      'SELECT EXISTS (SELECT 1 FROM transactions) AS has_any',
      readsFrom: {transactionsTable},
    ).watchSingle().map((row) => row.read<bool>('has_any'));
  }

  Future<int> countAll() {
    final count = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// How many transactions were logged after [moment], in any currency.
  Stream<int> watchCountCreatedAfter(DateTime moment) {
    final count = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)
      ..addColumns([count])
      ..where(transactionsTable.createdAt.isBiggerThanValue(moment));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Stream<int> watchCountInCurrency(String currencyCode) {
    final count = transactionsTable.id.count();
    final query = selectOnly(transactionsTable)
      ..addColumns([count])
      ..where(transactionsTable.currencyCode.equals(currencyCode));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// Total and count per type over [range] in [currencyCode]. Types without
  /// transactions are missing from the map.
  Stream<Map<TransactionType, ({int totalMinor, int count})>> watchTotalsByType(
    DateRange range,
    String currencyCode,
  ) {
    return customSelect(
      'SELECT type, SUM(amount_minor) AS total, COUNT(*) AS count FROM transactions '
      'WHERE currency_code = ? AND occurred_on >= ? AND occurred_on < ? '
      'GROUP BY type',
      variables: _rangeVariables(range, currencyCode),
      readsFrom: {transactionsTable},
    ).watch().map(
      (rows) => {
        for (final row in rows)
          TransactionType.values.byName(row.read<String>('type')): (
            totalMinor: row.read<int>('total'),
            count: row.read<int>('count'),
          ),
      },
    );
  }

  /// Expenses over [range] in [currencyCode] per category, largest first.
  Stream<List<(CategoryRow, int)>> watchExpensesByCategory(
    DateRange range,
    String currencyCode,
  ) {
    return customSelect(
      'SELECT categories.*, SUM(transactions.amount_minor) AS total FROM transactions '
      'JOIN categories ON categories.id = transactions.category_id '
      "WHERE transactions.type = 'expense' AND transactions.currency_code = ? "
      'AND transactions.occurred_on >= ? AND transactions.occurred_on < ? '
      'GROUP BY categories.id ORDER BY total DESC',
      variables: _rangeVariables(range, currencyCode),
      readsFrom: {transactionsTable, categoriesTable},
    ).watch().map(
      (rows) => [
        for (final row in rows)
          (categoriesTable.map(row.data), row.read<int>('total')),
      ],
    );
  }

  /// Expenses per day over [range] in [currencyCode], for one category or
  /// all of them. Days without any are missing from the map.
  Stream<Map<DateTime, int>> watchExpensesByDay(
    DateRange range,
    String currencyCode, {
    int? categoryId,
  }) {
    return customSelect(
      'SELECT occurred_on, SUM(amount_minor) AS total FROM transactions '
      "WHERE type = 'expense' AND currency_code = ? "
      'AND occurred_on >= ? AND occurred_on < ? '
      '${categoryId == null ? '' : 'AND category_id = ? '}'
      'GROUP BY occurred_on',
      variables: [
        ..._rangeVariables(range, currencyCode),
        if (categoryId != null) Variable.withInt(categoryId),
      ],
      readsFrom: {transactionsTable},
    ).watch().map(
      (rows) => {
        for (final row in rows)
          _dates.fromSql(row.read<String>('occurred_on')): row.read<int>(
            'total',
          ),
      },
    );
  }

  /// The day of the earliest transaction in [currencyCode], or `null`
  /// before there is one.
  Stream<DateTime?> watchFirstDay(String currencyCode) {
    return customSelect(
      'SELECT MIN(occurred_on) AS first_day FROM transactions '
      'WHERE currency_code = ?',
      variables: [Variable.withString(currencyCode)],
      readsFrom: {transactionsTable},
    ).watchSingle().map((row) {
      final day = row.read<String?>('first_day');
      return day == null ? null : _dates.fromSql(day);
    });
  }

  /// Dates are stored as yyyy-MM-dd text, which sorts like the dates
  /// themselves, so ranges are plain text comparisons.
  List<Variable<Object>> _rangeVariables(
    DateRange range,
    String currencyCode,
  ) => [
    Variable.withString(currencyCode),
    Variable.withString(_dates.toSql(range.start)),
    Variable.withString(_dates.toSql(range.end)),
  ];

  /// Transactions matching [filter] with their categories, newest first:
  /// by day, then by when they were logged.
  Stream<List<(TransactionRow, CategoryRow)>> watchFiltered(
    TransactionFilter filter,
  ) {
    final query = select(transactionsTable).join([
      innerJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(transactionsTable.categoryId),
      ),
    ]);

    if (filter.type case final type?) {
      query.where(transactionsTable.type.equalsValue(type));
    }
    if (filter.categoryIds.isNotEmpty) {
      query.where(transactionsTable.categoryId.isIn(filter.categoryIds));
    }
    if (filter.range case final range?) {
      query.where(
        transactionsTable.occurredOn.isBiggerOrEqual(
              Variable(_dates.toSql(range.start)),
            ) &
            transactionsTable.occurredOn.isSmallerThan(
              Variable(_dates.toSql(range.end)),
            ),
      );
    }
    query.orderBy([
      OrderingTerm.desc(transactionsTable.occurredOn),
      OrderingTerm.desc(transactionsTable.id),
    ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (row.readTable(transactionsTable), row.readTable(categoriesTable)),
      ],
    );
  }

  /// Updates the given columns of transaction [id].
  Future<void> updateById(int id, TransactionsTableCompanion changes) {
    return (update(
      transactionsTable,
    )..where((row) => row.id.equals(id))).write(changes);
  }

  Future<void> deleteById(int id) =>
      (delete(transactionsTable)..where((row) => row.id.equals(id))).go();
}
