import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClock extends Mock implements Clock;

void main() {
  final now = DateTime(2026, 10, 8, 12, 30);
  late AppDatabase database;
  late TransactionRepositoryImpl repository;
  late int groceriesId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final clock = _MockClock();
    when(clock.now).thenReturn(now);
    repository = TransactionRepositoryImpl(database.transactionsDao, clock);
    groceriesId =
        (await database.select(database.categoriesTable).get()).first.id;
  });
  tearDown(() => database.close());

  test(
    'stores the transaction with a trimmed title and a date-only day',
    () async {
      final result = await repository.add(
        type: TransactionType.expense,
        amountMinor: 1840,
        currencyCode: 'EUR',
        categoryId: groceriesId,
        occurredOn: DateTime(2026, 10, 7, 21, 15),
        title: '  Lunch with Sara ',
      );

      final row = await database.select(database.transactionsTable).getSingle();
      expect(result.isRight(), isTrue);
      expect(row.amountMinor, 1840);
      expect(row.title, 'Lunch with Sara');
      expect(row.occurredOn, DateTime(2026, 10, 7));
      expect(row.createdAt, now);
    },
  );

  test('counts transactions in one currency only', () async {
    Future<void> add(String currencyCode) => repository.add(
      type: TransactionType.expense,
      amountMinor: 100,
      currencyCode: currencyCode,
      categoryId: groceriesId,
      occurredOn: DateTime(2026, 10, 8),
    );
    await add('EUR');
    await add('EUR');
    await add('USD');

    final count = await repository.watchCountInCurrency('EUR').first;
    expect(count.getRight().toNullable(), 2);
    expect((await repository.count()).getRight().toNullable(), 3);
  });

  test('stores a blank title as no title', () async {
    await repository.add(
      type: TransactionType.expense,
      amountMinor: 100,
      currencyCode: 'EUR',
      categoryId: groceriesId,
      occurredOn: now,
      title: '   ',
    );

    expect(
      (await database.select(database.transactionsTable).getSingle()).title,
      isNull,
    );
  });

  test('rejects an amount of zero before touching the database', () async {
    final result = await repository.add(
      type: TransactionType.expense,
      amountMinor: 0,
      currencyCode: 'EUR',
      categoryId: groceriesId,
      occurredOn: now,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(await database.select(database.transactionsTable).get(), isEmpty);
  });

  test('rejects a category that does not exist', () async {
    final result = await repository.add(
      type: TransactionType.expense,
      amountMinor: 100,
      currencyCode: 'EUR',
      categoryId: 9999,
      occurredOn: now,
    );

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });

  group('changing a transaction', () {
    late int id;
    late int eatingOutId;

    setUp(() async {
      eatingOutId =
          (await database.select(database.categoriesTable).get())[1].id;
      await repository.add(
        type: TransactionType.expense,
        amountMinor: 1840,
        currencyCode: 'EUR',
        categoryId: groceriesId,
        occurredOn: DateTime(2026, 10, 8),
        title: 'Lunch',
      );
      id = (await database.select(database.transactionsTable).getSingle()).id;
    });

    test('update changes the details but keeps the currency and when it was logged', () async {
      final result = await repository.update(
        id: id,
        type: TransactionType.expense,
        amountMinor: 2500,
        categoryId: eatingOutId,
        occurredOn: DateTime(2026, 10, 7, 20),
        title: ' Dinner ',
      );

      final row = await database.select(database.transactionsTable).getSingle();
      expect(result.isRight(), isTrue);
      expect(
        (row.amountMinor, row.categoryId, row.title, row.occurredOn),
        (2500, eatingOutId, 'Dinner', DateTime(2026, 10, 7)),
      );
      expect((row.currencyCode, row.createdAt), ('EUR', now));
    });

    test('update rejects an amount of zero', () async {
      final result = await repository.update(
        id: id,
        type: TransactionType.expense,
        amountMinor: 0,
        categoryId: groceriesId,
        occurredOn: now,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test(
      'delete removes it and restore brings it back exactly as it was',
      () async {
        final before = await database
            .select(database.transactionsTable)
            .getSingle();

        await repository.delete(id);
        expect(
          await database.select(database.transactionsTable).get(),
          isEmpty,
        );

        final restored = Transaction(
          id: before.id,
          type: before.type,
          amountMinor: before.amountMinor,
          currencyCode: before.currencyCode,
          categoryId: before.categoryId,
          title: before.title,
          occurredOn: before.occurredOn,
          createdAt: before.createdAt,
        );
        expect((await repository.restore(restored)).isRight(), isTrue);
        expect(
          await database.select(database.transactionsTable).getSingle(),
          before,
        );
      },
    );
  });
}
