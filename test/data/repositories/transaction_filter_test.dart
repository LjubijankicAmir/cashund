import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late TransactionRepositoryImpl repository;
  late Map<String, int> categoryIds;

  Future<void> log(String category, String title, DateTime day) async {
    await repository.add(
      type: category.startsWith('income')
          ? TransactionType.income
          : TransactionType.expense,
      amountMinor: 100,
      currencyCode: 'EUR',
      categoryId: categoryIds[category]!,
      occurredOn: day,
      title: title,
    );
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepositoryImpl(database.transactionsDao, Clock());
    categoryIds = {
      for (final row in await database.select(database.categoriesTable).get())
        '${row.type.name}.${row.predefinedKey}': row.id,
    };

    // Logged in this order on purpose: the list sorts by day, then newest.
    await log('expense.groceries', 'Weekly shop', DateTime(2026, 10, 7));
    await log('expense.eating_out', 'Lunch with Sara', DateTime(2026, 10, 8));
    await log('income.salary', 'October salary', DateTime(2026, 10, 5));
    await log('expense.transport', 'Bus ticket', DateTime(2026, 10, 7));
    await log('expense.groceries', 'September shop', DateTime(2026, 9, 30));
  });
  tearDown(() => database.close());

  Future<List<String?>> titles(TransactionFilter filter) async {
    final entries = (await repository.watchFiltered(filter).first)
        .getRight()
        .toNullable()!;
    return [for (final entry in entries) entry.transaction.title];
  }

  test('without filters lists everything, newest day first and newest within a day', () async {
    expect(await titles(const TransactionFilter()), [
      'Lunch with Sara',
      'Bus ticket',
      'Weekly shop',
      'October salary',
      'September shop',
    ]);
  });

  test('comes with each transaction’s category', () async {
    final entries =
        (await repository.watchFiltered(const TransactionFilter()).first)
            .getRight()
            .toNullable()!;

    expect(entries.first.category.predefinedKey, 'eating_out');
  });

  test('filters by type', () async {
    expect(
      await titles(const TransactionFilter(type: TransactionType.income)),
      ['October salary'],
    );
  });

  test('filters by categories', () async {
    final groceries = categoryIds['expense.groceries']!;
    final transport = categoryIds['expense.transport']!;

    expect(
      await titles(TransactionFilter(categoryIds: {groceries, transport})),
      ['Bus ticket', 'Weekly shop', 'September shop'],
    );
  });

  test('filters by days, including the first and excluding the end', () async {
    final range = DateRange(
      start: DateTime(2026, 10, 5),
      end: DateTime(2026, 10, 8),
    );

    expect(await titles(TransactionFilter(range: range)), [
      'Bus ticket',
      'Weekly shop',
      'October salary',
    ]);
  });

  test('combines filters', () async {
    final range = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
    final filter = TransactionFilter(
      type: TransactionType.expense,
      categoryIds: {categoryIds['expense.groceries']!},
      range: range,
    );

    expect(await titles(filter), ['Weekly shop']);
  });

  test('counts the active filters', () {
    expect(const TransactionFilter().activeCount, 0);
    expect(
      TransactionFilter(
        type: TransactionType.expense,
        categoryIds: const {1},
        range: DateRange(start: DateTime(2026), end: DateTime(2027)),
      ).activeCount,
      3,
    );
  });
}
