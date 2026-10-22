import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/domain/repositories/file_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/data_settings/bloc/data_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockData extends Mock implements DataRepository;

class _MockFiles extends Mock implements FileRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockClock extends Mock implements Clock;

void main() {
  final now = DateTime(2026, 10, 22, 14, 32);
  const settings = UserPreferences(
    currencyCode: 'USD',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );
  final info = (createdAt: DateTime(2026, 10, 2), transactionCount: 296);

  late _MockData data;
  late _MockFiles files;
  late _MockPreferences preferences;
  late _MockTransactions transactions;

  setUpAll(() => registerFallbackValue(settings));

  setUp(() {
    data = _MockData();
    files = _MockFiles();
    preferences = _MockPreferences();
    transactions = _MockTransactions();
    when(data.watchCounts).thenAnswer(
      (_) =>
          Stream.value(right((transactions: 341, categories: 21, limits: 7))),
    );
    when(() => transactions.watchCountCreatedAfter(any()))
        .thenAnswer((_) => Stream.value(right(12)));
    when(() => preferences.save(any())).thenAnswer((_) async => right(unit));
  });

  Future<DataBloc> opened({DateTime? lastBackupAt}) async {
    when(preferences.watch).thenAnswer(
      (_) => Stream.value(right(settings.copyWith(lastBackupAt: lastBackupAt))),
    );
    final clock = _MockClock();
    when(clock.now).thenReturn(now);
    final bloc = DataBloc(data, files, preferences, transactions, clock)
      ..add(const DataEvent.started());
    await pumpEventQueue();
    return bloc;
  }

  group('reminder', () {
    test('without any backup yet', () async {
      final bloc = await opened();
      expect(bloc.state.remindToBackUp, isTrue);
      await bloc.close();
    });

    test('a recent backup needs no reminder', () async {
      final bloc = await opened(lastBackupAt: DateTime(2026, 10, 19));
      expect(bloc.state.remindToBackUp, isFalse);
      await bloc.close();
    });

    test('an old backup with new transactions since', () async {
      final bloc = await opened(lastBackupAt: DateTime(2026, 9, 7));
      expect(bloc.state.sinceBackup, 12);
      expect(bloc.state.remindToBackUp, isTrue);
      await bloc.close();
    });
  });

  group('backup', () {
    setUp(() {
      when(data.createBackup).thenAnswer((_) async => right('{}'));
    });

    void shareReturns({required bool shared}) => when(
      () => files.share(
        fileName: any(named: 'fileName'),
        contents: any(named: 'contents'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => right(shared));

    test('a shared backup is remembered', () async {
      shareReturns(shared: true);
      final bloc = await opened();

      bloc.add(const DataEvent.backupPressed());
      await pumpEventQueue();

      verify(
        () => files.share(
          fileName: 'cashund-backup-2026-10-22.cashund',
          contents: '{}',
          mimeType: 'application/json',
        ),
      ).called(1);
      verify(() => preferences.save(settings.copyWith(lastBackupAt: now)))
          .called(1);
      await bloc.close();
    });

    test('backing out of the share sheet doesn’t count', () async {
      shareReturns(shared: false);
      final bloc = await opened();

      bloc.add(const DataEvent.backupPressed());
      await pumpEventQueue();

      verifyNever(() => preferences.save(any()));
      await bloc.close();
    });
  });

  group('restore', () {
    test(
      'reads the picked file, then replaces everything on confirm',
      () async {
        when(files.pickText).thenAnswer(
          (_) async => right((name: 'backup.cashund', contents: 'backup')),
        );
        when(() => data.readBackup('backup'))
            .thenAnswer((_) async => right(info));
        when(() => data.restoreBackup('backup'))
            .thenAnswer((_) async => right(unit));
        final bloc = await opened();

        bloc.add(const DataEvent.restorePressed());
        await pumpEventQueue();
        expect(
          bloc.state.restore,
          RestoreStep.confirming(
            file: (name: 'backup.cashund', contents: 'backup'),
            info: info,
          ),
        );

        bloc.add(const DataEvent.restoreConfirmed());
        await pumpEventQueue();
        expect(bloc.state.restore, RestoreStep.restored(info));
        await bloc.close();
      },
    );

    test('an unreadable file fails without touching anything', () async {
      when(
        files.pickText,
      ).thenAnswer((_) async => right((name: 'photo.jpg', contents: 'nope')));
      when(() => data.readBackup('nope'))
          .thenAnswer((_) async => left(const Failure.validation()));
      final bloc = await opened();

      bloc.add(const DataEvent.restorePressed());
      await pumpEventQueue();

      expect(
        bloc.state.restore,
        const RestoreStep.failed(fileName: 'photo.jpg'),
      );
      verifyNever(() => data.restoreBackup(any()));
      await bloc.close();
    });

    test('backing out of the picker changes nothing', () async {
      when(files.pickText).thenAnswer((_) async => right(null));
      final bloc = await opened();

      bloc.add(const DataEvent.restorePressed());
      await pumpEventQueue();

      expect(bloc.state.restore, const RestoreStep.idle());
      await bloc.close();
    });
  });

  test('deleting everything reports when it’s done', () async {
    when(data.deleteEverything).thenAnswer((_) async => right(unit));
    final bloc = await opened();

    bloc.add(const DataEvent.deleteConfirmed());
    await pumpEventQueue();

    expect(bloc.state.delete, DataActionStatus.done);
    await bloc.close();
  });
}
