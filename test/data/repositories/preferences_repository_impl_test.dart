import 'package:cashund/core/error/failure.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:cashund/data/repositories/preferences_repository_impl.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesDao extends Mock implements PreferencesDao;

void main() {
  const preferences = UserPreferences(
    currencyCode: 'EUR',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );

  group('with a database', () {
    late AppDatabase database;
    late PreferencesRepositoryImpl repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = PreferencesRepositoryImpl(database.preferencesDao);
    });
    tearDown(() => database.close());

    test('get returns null before anything is saved', () async {
      expect(await repository.get(), right<Failure, UserPreferences?>(null));
    });

    test('get returns what save stored', () async {
      await repository.save(preferences);

      expect(
        await repository.get(),
        right<Failure, UserPreferences?>(preferences),
      );
    });

    test('watch emits the current value and every change', () async {
      final renamed = preferences.copyWith(buddyName: 'Peanut');

      final emitted = repository.watch().take(3).toList();
      await pumpEventQueue();
      await repository.save(preferences);
      await pumpEventQueue();
      await repository.save(renamed);

      expect(await emitted, [
        right<Failure, UserPreferences?>(null),
        right<Failure, UserPreferences?>(preferences),
        right<Failure, UserPreferences?>(renamed),
      ]);
    });
  });

  group('when the database fails', () {
    late _MockPreferencesDao dao;
    late PreferencesRepositoryImpl repository;

    setUp(() {
      dao = _MockPreferencesDao();
      repository = PreferencesRepositoryImpl(dao);
    });

    test('get returns a database failure', () async {
      when(dao.getRow).thenThrow(Exception('disk full'));

      final result = await repository.get();

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('watch emits a database failure instead of an error', () async {
      when(dao.watchRow)
          .thenAnswer((_) => Stream.error(Exception('disk full')));

      final result = await repository.watch().first;

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
