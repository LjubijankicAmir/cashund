import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/seed/predefined_categories.dart';
import 'package:cashund/data/repositories/category_repository_impl.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart' hide isNull;
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

  test('counts active categories per type, without archived ones', () async {
    Future<({int expense, int income})> counts() async =>
        (await categories.watchActiveCounts().first).getRight().toNullable()!;

    expect(await counts(), (expense: 14, income: 7));

    await (database.update(database.categoriesTable)
          ..where((c) => c.predefinedKey.equals('pets')))
        .write(const CategoriesTableCompanion(isArchived: Value(true)));

    expect(await counts(), (expense: 13, income: 7));
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

  group('managing categories', () {
    Future<List<Category>> all(TransactionType type) async =>
        (await categories.watchByType(type).first).getRight().toNullable()!;

    Future<Category> byKey(String key) async =>
        (await all(TransactionType.expense))
            .firstWhere((c) => c.predefinedKey == key);

    test('create adds a trimmed custom category after the others', () async {
      final result = await categories.create(
        type: TransactionType.expense,
        name: '  Hobbies ',
        emoji: '🎨',
        color: CategoryColor.plum,
      );

      final created = result.getRight().toNullable()!;
      expect(created.customName, 'Hobbies');
      expect(created.predefinedKey, isNull);
      expect(created.sortOrder, 14);
      expect((await active(TransactionType.expense)).last.id, created.id);
    });

    test('create rejects a blank name', () async {
      final result = await categories.create(
        type: TransactionType.expense,
        name: '   ',
        emoji: '🎨',
        color: CategoryColor.plum,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('update renames and recolors a built-in category', () async {
      final groceries = await byKey('groceries');

      await categories.update(
        id: groceries.id,
        customName: 'Food',
        emoji: groceries.emoji,
        color: CategoryColor.teal,
      );
      final renamed = await byKey('groceries');
      expect(renamed.customName, 'Food');
      expect(renamed.color, CategoryColor.teal);

      await categories.update(
        id: groceries.id,
        customName: null,
        emoji: groceries.emoji,
        color: CategoryColor.teal,
      );
      expect((await byKey('groceries')).customName, isNull);
    });

    test("update keeps a built-in category's emoji", () async {
      final groceries = await byKey('groceries');

      final result = await categories.update(
        id: groceries.id,
        customName: null,
        emoji: '🍕',
        color: groceries.color,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect((await byKey('groceries')).emoji, groceries.emoji);
    });

    test('update requires a name for a custom category', () async {
      final hobbies = (await categories.create(
        type: TransactionType.expense,
        name: 'Hobbies',
        emoji: '🎨',
        color: CategoryColor.plum,
      )).getRight().toNullable()!;

      final result = await categories.update(
        id: hobbies.id,
        customName: null,
        emoji: '🎮',
        color: CategoryColor.plum,
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());

      await categories.update(
        id: hobbies.id,
        customName: 'Games',
        emoji: '🎮',
        color: CategoryColor.sky,
      );
      final changed = (await all(TransactionType.expense))
          .firstWhere((c) => c.id == hobbies.id);
      expect(changed.customName, 'Games');
      expect(changed.emoji, '🎮');
    });

    test('reorder saves the new order', () async {
      final ids = [for (final c in await all(TransactionType.expense)) c.id];
      final reordered = [ids[2], ids[0], ids[1], ...ids.skip(3)];

      await categories.reorder(TransactionType.expense, reordered);

      expect([
        for (final c in await all(TransactionType.expense)) c.id,
      ], reordered);
    });

    test('archive hides a category from the active ones; restore brings it '
        'back in its place', () async {
      final transport = await byKey('transport');

      await categories.setArchived(transport.id, archived: true);
      expect(
        (await active(TransactionType.expense)).map((c) => c.id),
        isNot(contains(transport.id)),
      );
      expect((await byKey('transport')).isArchived, isTrue);

      await categories.setArchived(transport.id, archived: false);
      expect((await active(TransactionType.expense))[2].id, transport.id);
    });
  });
}
