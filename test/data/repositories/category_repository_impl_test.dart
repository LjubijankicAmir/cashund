import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/seed/predefined_categories.dart';
import 'package:cashund/data/repositories/category_repository_impl.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl categories;
  late TransactionRepositoryImpl transactions;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    categories = CategoryRepositoryImpl(database.categoriesDao);
    transactions = TransactionRepositoryImpl(database.transactionsDao, Clock());
  });
  tearDown(() => database.close());

  Future<List<Category>> active(TransactionType type) async =>
      (await categories.watchActive(type).first).getRight().toNullable()!;

  Future<List<Category>> recent(TransactionType type) async =>
      (await categories.watchRecent(type, limit: 3).first)
          .getRight()
          .toNullable()!;

  Future<void> log(Category category) async {
    final result = await transactions.add(
      type: category.type,
      amountMinor: 100,
      currencyCode: 'EUR',
      categoryId: category.id,
      occurredOn: DateTime(2026, 10, 8),
    );
    expect(result.isRight(), isTrue);
  }

  test('a new database has the predefined categories, in order', () async {
    final expenses = await active(TransactionType.expense);
    final incomes = await active(TransactionType.income);

    expect(expenses, hasLength(14));
    expect(incomes, hasLength(7));
    expect(expenses.map((c) => c.predefinedKey).take(3), [
      'groceries',
      'eating_out',
      'transport',
    ]);
    expect(expenses.every((c) => c.customName == null), isTrue);
  });

  test('seeding again adds nothing twice', () async {
    await seedPredefinedCategories(database);

    expect(await active(TransactionType.expense), hasLength(14));
  });

  test(
    'recent categories are the latest used first, without repeats',
    () async {
      final [groceries, eatingOut, transport, housing, ...] = await active(
        TransactionType.expense,
      );
      final salary = (await active(TransactionType.income)).first;

      await log(groceries);
      await log(eatingOut);
      await log(groceries);
      await log(transport);
      await log(housing);
      await log(salary);

      expect(
        (await recent(TransactionType.expense)).map((c) => c.predefinedKey),
        ['housing', 'transport', 'groceries'],
      );
      expect(
        (await recent(TransactionType.income)).map((c) => c.predefinedKey),
        ['salary'],
      );
    },
  );

  test('recent categories update when something is logged', () async {
    final groceries = (await active(TransactionType.expense)).first;
    final updates = categories
        .watchRecent(TransactionType.expense, limit: 3)
        .take(2)
        .toList();

    await pumpEventQueue();
    await log(groceries);

    final [before, after] = await updates;
    expect(before.getRight().toNullable(), isEmpty);
    expect(after.getRight().toNullable()!.single.id, groceries.id);
  });
}
