import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday Oct 5 up to (not including) Monday Oct 12.
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );

  late AppDatabase database;
  late TransactionRepositoryImpl repository;
  late Map<String, int> categoryIds;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepositoryImpl(database.transactionsDao, Clock());
    categoryIds = {
      for (final row in await database.select(database.categoriesTable).get())
        '${row.type.name}.${row.predefinedKey}': row.id,
    };
  });
  tearDown(() => database.close());

  Future<void> log(
    String category,
    int amount,
    DateTime day, {
    String currency = 'EUR',
  }) async {
    final type = category.startsWith('income')
        ? TransactionType.income
        : TransactionType.expense;
    final result = await repository.add(
      type: type,
      amountMinor: amount,
      currencyCode: currency,
      categoryId: categoryIds[category]!,
      occurredOn: day,
    );
    expect(result.isRight(), isTrue);
  }

  Future<PeriodSummary> summary() async =>
      (await repository.watchSummary(week, currencyCode: 'EUR').first)
          .getRight()
          .toNullable()!;

  test('an empty period has nothing in it', () async {
    expect(await summary(), const PeriodSummary());
  });

  test('adds up income and expenses separately', () async {
    await log('income.salary', 240000, DateTime(2026, 10, 6));
    await log('expense.groceries', 6210, DateTime(2026, 10, 7));
    await log('expense.eating_out', 1840, DateTime(2026, 10, 8));

    expect(
      await summary(),
      const PeriodSummary(
        incomeMinor: 240000,
        expenseMinor: 8050,
        transactionCount: 3,
      ),
    );
  });

  test('counts the first day and leaves out the day after the end', () async {
    await log('expense.groceries', 100, DateTime(2026, 10, 5));
    await log('expense.groceries', 200, DateTime(2026, 10, 11));
    await log('expense.groceries', 400, DateTime(2026, 10, 12));
    await log('expense.groceries', 800, DateTime(2026, 10, 4));

    expect((await summary()).expenseMinor, 300);
  });

  test('leaves out other currencies', () async {
    await log('expense.groceries', 100, DateTime(2026, 10, 6));
    await log(
      'expense.groceries',
      5000,
      DateTime(2026, 10, 6),
      currency: 'USD',
    );

    expect((await summary()).expenseMinor, 100);
  });

  test('spending per category is expenses only, largest first', () async {
    await log('expense.groceries', 100, DateTime(2026, 10, 6));
    await log('expense.eating_out', 300, DateTime(2026, 10, 6));
    await log('expense.groceries', 50, DateTime(2026, 10, 7));
    await log('income.salary', 999999, DateTime(2026, 10, 7));

    final spending =
        (await repository
                .watchSpendingByCategory(week, currencyCode: 'EUR')
                .first)
            .getRight()
            .toNullable()!;

    expect(
      spending.map((item) => (item.category.predefinedKey, item.amountMinor)),
      [('eating_out', 300), ('groceries', 150)],
    );
  });

  test('the summary updates when something is logged', () async {
    final updates = repository
        .watchSummary(week, currencyCode: 'EUR')
        .take(2)
        .toList();
    await pumpEventQueue();

    await log('expense.groceries', 700, DateTime(2026, 10, 6));

    final [before, after] = await updates;
    expect(before.getRight().toNullable()!.isEmpty, isTrue);
    expect(after.getRight().toNullable()!.expenseMinor, 700);
  });

  test('knows whether anything was ever logged', () async {
    Future<bool> hasAny() async =>
        (await repository.watchHasAny().first).getRight().toNullable()!;

    expect(await hasAny(), isFalse);
    await log('expense.groceries', 100, DateTime(2026), currency: 'USD');
    expect(await hasAny(), isTrue);
  });
}
