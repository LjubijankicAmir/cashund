import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  PreferencesTableCompanion row({String buddyName = 'Biscuit'}) {
    return PreferencesTableCompanion.insert(
      currencyCode: 'EUR',
      buddyName: buddyName,
      weekStart: WeekStart.monday,
      onboardingCompleted: true,
    );
  }

  test('has no row before anything is saved', () async {
    expect(await database.preferencesDao.getRow(), isNull);
  });

  test('upsert keeps a single row and replaces its values', () async {
    await database.preferencesDao.upsert(row());
    await database.preferencesDao.upsert(row(buddyName: 'Peanut'));

    final rows = await database.select(database.preferencesTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.buddyName, 'Peanut');
  });

  test('rejects a second row', () async {
    final second = row().copyWith(id: const Value(2));

    await expectLater(
      database.into(database.preferencesTable).insert(second),
      throwsA(isA<SqliteException>()),
    );
  });
}
