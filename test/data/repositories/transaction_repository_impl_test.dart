import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
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
}
