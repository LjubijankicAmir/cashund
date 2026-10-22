import 'dart:convert';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/repositories/data_repository_impl.dart';
import 'package:cashund/data/repositories/limit_repository_impl.dart';
import 'package:cashund/data/repositories/preferences_repository_impl.dart';
import 'package:cashund/data/repositories/transaction_repository_impl.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClock extends Mock implements Clock;

void main() {
  late AppDatabase database;
  late DataRepositoryImpl data;
  late TransactionRepositoryImpl transactions;
  late int groceries;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final clock = _MockClock();
    when(clock.now).thenReturn(DateTime(2026, 10, 22, 14, 32));
    data = DataRepositoryImpl(
      database.backupDao,
      database.transactionsDao,
      clock,
    );
    transactions = TransactionRepositoryImpl(database.transactionsDao, clock);
    groceries =
        (await database.select(database.categoriesTable).get()).first.id;

    await PreferencesRepositoryImpl(database.preferencesDao).save(
      const UserPreferences(
        currencyCode: 'USD',
        buddyName: 'Noodle',
        weekStart: WeekStart.sunday,
        onboardingCompleted: true,
      ),
    );
    for (final (amount, title, day) in [
      (1840, 'Lunch, with "Sara"', DateTime(2026, 10, 7)),
      (5000, null, DateTime(2026, 9, 30)),
    ]) {
      await transactions.add(
        type: TransactionType.expense,
        amountMinor: amount,
        currencyCode: 'USD',
        categoryId: groceries,
        occurredOn: day,
        title: title,
      );
    }
    await LimitRepositoryImpl(database.limitsDao, clock).create(
      period: LimitPeriod.week,
      currencyCode: 'USD',
      categoryId: groceries,
      amountMinor: 10000,
      effectiveFrom: DateTime(2026, 10, 4),
    );
  });
  tearDown(() => database.close());

  Future<String> backup() async =>
      (await data.createBackup()).getRight().toNullable()!;

  Future<List<Object>> everything() async => [
    await database.select(database.preferencesTable).get(),
    await database.select(database.categoriesTable).get(),
    await database.select(database.transactionsTable).get(),
    await database.select(database.limitsTable).get(),
    await database.select(database.limitAmountsTable).get(),
  ];

  test('a backup restores everything exactly, ids included', () async {
    final before = await everything();
    final file = await backup();

    await data.deleteEverything();
    expect(await database.select(database.transactionsTable).get(), isEmpty);

    expect((await data.restoreBackup(file)).isRight(), isTrue);
    expect(await everything(), before);
  });

  test('reading a backup tells when it was made and what it holds', () async {
    final info = (await data.readBackup(await backup()))
        .getRight()
        .toNullable()!;

    expect(info.createdAt, DateTime(2026, 10, 22, 14, 32));
    expect(info.transactionCount, 2);
  });

  test('files that aren’t readable backups change nothing', () async {
    final before = await everything();
    final newer = (jsonDecode(await backup()) as Map<String, Object?>)
      ..['schemaVersion'] = database.schemaVersion + 1;

    for (final contents in [
      'not json at all',
      '{"format": "something-else"}',
      '{"format": "cashund-backup", "formatVersion": 1}',
      jsonEncode(newer),
    ]) {
      final result = await data.restoreBackup(contents);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    }
    expect(await everything(), before);
  });

  test('CSV lists transactions oldest first, quoting what needs it', () async {
    final csv = (await data.exportCsv(
      categoryName: (category) => category.predefinedKey ?? '',
    )).getRight().toNullable()!;

    expect(
      csv,
      'date,type,category,title,amount,currency\r\n'
      '2026-09-30,expense,groceries,,-50.00,USD\r\n'
      '2026-10-07,expense,groceries,"Lunch, with ""Sara""",-18.40,USD\r\n',
    );
  });

  test('CSV can cover one range only', () async {
    final csv = (await data.exportCsv(
      categoryName: (category) => '',
      range: DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11)),
    )).getRight().toNullable()!;

    expect(csv.trim().split('\r\n'), hasLength(2));
  });

  test(
    'deleting everything starts over with only the built-in categories',
    () async {
      final counts = (await data.watchCounts().first).getRight().toNullable()!;
      expect(counts, (transactions: 2, categories: 21, limits: 1));

      await data.deleteEverything();

      expect(await database.select(database.preferencesTable).get(), isEmpty);
      expect((await data.watchCounts().first).getRight().toNullable(), (
        transactions: 0,
        categories: 21,
        limits: 0,
      ));
    },
  );
}
