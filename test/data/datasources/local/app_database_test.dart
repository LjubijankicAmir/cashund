import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('enables foreign keys on open', () async {
    final result = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(result.read<int>('foreign_keys'), 1);
  });
}
