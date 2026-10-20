import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/limit_repository_impl.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday Oct 5 to Sunday Oct 11, and the week before.
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  final lastWeek = DateRange(start: DateTime(2026, 9, 28), end: week.start);

  late AppDatabase database;
  late LimitRepositoryImpl limits;
  late TransactionRepositoryImpl transactions;
  late int groceries;
  late int eatingOut;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    limits = LimitRepositoryImpl(database.limitsDao, Clock());
    transactions = TransactionRepositoryImpl(database.transactionsDao, Clock());
    final categories = await database.select(database.categoriesTable).get();
    int idOf(String key) => categories
        .firstWhere(
          (c) => c.predefinedKey == key && c.type == TransactionType.expense,
        )
        .id;
    groceries = idOf('groceries');
    eatingOut = idOf('eating_out');
  });
  tearDown(() => database.close());

  Future<int> limit({
    int? categoryId,
    int amountMinor = 10000,
    LimitPeriod period = LimitPeriod.week,
    String currencyCode = 'USD',
    DateTime? from,
  }) async {
    final created = await limits.create(
      period: period,
      currencyCode: currencyCode,
      categoryId: categoryId,
      amountMinor: amountMinor,
      effectiveFrom: from ?? week.start,
    );
    return created.getRight().toNullable()!.id;
  }

  Future<void> spend(
    int categoryId,
    int amountMinor, {
    String currencyCode = 'USD',
    DateTime? on,
  }) async {
    final logged = await transactions.add(
      type: TransactionType.expense,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      categoryId: categoryId,
      occurredOn: on ?? DateTime(2026, 10, 7),
    );
    expect(logged.isRight(), isTrue);
  }

  Future<List<LimitProgress>> progress({
    DateRange? range,
    String currencyCode = 'USD',
  }) async =>
      (await limits
              .watchProgress(
                period: LimitPeriod.week,
                currencyCode: currencyCode,
                range: range ?? week,
              )
              .first)
          .getRight()
          .toNullable()!;

  test('counts the period’s spending in the category and currency', () async {
    await limit(categoryId: groceries);
    await spend(groceries, 4000);
    await spend(groceries, 5000);
    await spend(groceries, 9999, currencyCode: 'EUR');
    await spend(groceries, 9999, on: DateTime(2026, 10));
    await spend(eatingOut, 3000);

    final [only] = await progress();
    expect(only.category?.id, groceries);
    expect((only.spentMinor, only.amountMinor), (9000, 10000));
    expect(only.status, LimitStatus.near);
  });

  test('the overall limit counts every expense, most used first', () async {
    await limit(categoryId: groceries, amountMinor: 20000);
    await limit();
    await spend(groceries, 4000);
    await spend(eatingOut, 3000);

    final [first, second] = await progress();
    expect((first.limit.isOverall, first.spentMinor), (true, 7000));
    expect((second.category?.id, second.spentMinor), (groceries, 4000));
  });

  test('only limits in the selected currency show', () async {
    await limit(categoryId: groceries, currencyCode: 'EUR');

    expect(await progress(), isEmpty);
    expect(await progress(currencyCode: 'EUR'), hasLength(1));
  });

  test('limits on archived categories are hidden', () async {
    await limit(categoryId: groceries);
    await (database.update(database.categoriesTable)
          ..where((c) => c.id.equals(groceries)))
        .write(const CategoriesTableCompanion(isArchived: Value(true)));

    expect(await progress(), isEmpty);
    expect(
      (await limits.watchAll('USD').first).getRight().toNullable(),
      isEmpty,
    );
  });

  test(
    'a new amount applies from its period on; earlier ones keep theirs',
    () async {
      final id = await limit(categoryId: groceries, from: lastWeek.start);
      await limits.changeAmount(
        id,
        amountMinor: 15000,
        effectiveFrom: week.start,
      );

      expect((await progress(range: lastWeek)).single.amountMinor, 10000);
      expect((await progress()).single.amountMinor, 15000);
    },
  );

  test('a limit doesn’t show in periods before it existed', () async {
    await limit(categoryId: groceries);

    expect(await progress(range: lastWeek), isEmpty);
  });

  test('one limit per category, period and currency', () async {
    await limit(categoryId: groceries);
    await limit();

    Future<Failure?> second({int? categoryId, LimitPeriod? period}) async =>
        (await limits.create(
          period: period ?? LimitPeriod.week,
          currencyCode: 'USD',
          categoryId: categoryId,
          amountMinor: 5000,
          effectiveFrom: week.start,
        )).getLeft().toNullable();

    expect(await second(categoryId: groceries), isA<ValidationFailure>());
    expect(await second(), isA<ValidationFailure>());
    expect(
      await second(categoryId: groceries, period: LimitPeriod.month),
      isNull,
    );
  });

  test('rejects an amount of zero', () async {
    final result = await limits.create(
      period: LimitPeriod.week,
      currencyCode: 'USD',
      categoryId: groceries,
      amountMinor: 0,
      effectiveFrom: week.start,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('delete and restore bring it back with its id and history', () async {
    final id = await limit(categoryId: groceries, from: lastWeek.start);
    await limits.changeAmount(
      id,
      amountMinor: 15000,
      effectiveFrom: week.start,
    );

    final snapshot = (await limits.delete(id)).getRight().toNullable()!;
    expect(await progress(), isEmpty);

    await limits.restore(snapshot);
    expect((await progress()).single.limit.id, id);
    final amounts = (await limits.watchAmounts(id).first)
        .getRight()
        .toNullable()!;
    expect([for (final a in amounts) a.amountMinor], [10000, 15000]);
  });

  test('expenses by day add up each day in one category or all', () async {
    await spend(groceries, 4000);
    await spend(eatingOut, 3000);
    await spend(groceries, 1000, on: DateTime(2026, 10, 9));

    Future<Map<DateTime, int>> byDay({int? categoryId}) async =>
        (await transactions
                .watchExpensesByDay(
                  week,
                  currencyCode: 'USD',
                  categoryId: categoryId,
                )
                .first)
            .getRight()
            .toNullable()!;

    expect(await byDay(), {
      DateTime(2026, 10, 7): 7000,
      DateTime(2026, 10, 9): 1000,
    });
    expect((await byDay(categoryId: groceries))[DateTime(2026, 10, 7)], 4000);
  });
}
