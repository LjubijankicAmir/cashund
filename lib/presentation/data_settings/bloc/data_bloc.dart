import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/domain/repositories/file_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Right;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'data_bloc.freezed.dart';
part 'data_event.dart';
part 'data_state.dart';

/// Settings › Data: backing up, restoring and deleting everything.
@injectable
class DataBloc extends Bloc<DataEvent, DataState> {
  DataBloc(
    this._data,
    this._files,
    this._preferences,
    this._transactions,
    this._clock,
  ) : super(DataState(today: _clock.now())) {
    on<_Started>(
      (event, emit) => Future.wait([
        emit.forEach(
          _preferences.watch(),
          onData: (result) {
            final previous = state.lastBackupAt;
            final next = state.copyWith(
              preferences: result.getRight().toNullable() ?? state.preferences,
            );
            // On the first load, and whenever a new backup is made.
            if (state.preferences == null || next.lastBackupAt != previous) {
              add(const DataEvent.sinceBackupWatched());
            }
            return next;
          },
        ),
        emit.forEach(
          _data.watchCounts(),
          onData: (result) => state.copyWith(
            counts: result.getRight().toNullable() ?? state.counts,
          ),
        ),
      ]),
    );
    on<_SinceBackupWatched>((event, emit) {
      final last = state.lastBackupAt;
      if (last == null) return Future<void>.value();
      return emit.forEach(
        _transactions.watchCountCreatedAfter(last),
        onData: (result) => state.copyWith(
          sinceBackup: result.getRight().toNullable() ?? state.sinceBackup,
        ),
      );
    }, transformer: restartable());
    on<_BackupPressed>(_onBackupPressed, transformer: droppable());
    on<_RestorePressed>(_onRestorePressed, transformer: droppable());
    on<_RestoreConfirmed>(_onRestoreConfirmed, transformer: droppable());
    on<_RestoreCancelled>(
      (event, emit) => emit(state.copyWith(restore: const RestoreStep.idle())),
    );
    on<_DeleteConfirmed>(_onDeleteConfirmed, transformer: droppable());
  }

  final DataRepository _data;
  final FileRepository _files;
  final PreferencesRepository _preferences;
  final TransactionRepository _transactions;
  final Clock _clock;

  /// "cashund-backup-2026-10-22.cashund"
  static String backupFileName(DateTime day) =>
      'cashund-backup-${day.year}-${_two(day.month)}-${_two(day.day)}.cashund';

  static String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _onBackupPressed(
    _BackupPressed event,
    Emitter<DataState> emit,
  ) async {
    emit(state.copyWith(backup: DataActionStatus.working));
    final now = _clock.now();
    final contents = (await _data.createBackup()).getRight().toNullable();
    final shared = contents == null
        ? null
        : (await _files.share(
            fileName: backupFileName(now),
            contents: contents,
            mimeType: 'application/json',
          )).getRight().toNullable();

    switch (shared) {
      case true:
        // Only a shared file counts; cancelling the share sheet doesn't.
        final preferences = state.preferences;
        if (preferences != null) {
          await _preferences.save(preferences.copyWith(lastBackupAt: now));
        }
        emit(state.copyWith(backup: DataActionStatus.done));
      case false:
        emit(state.copyWith(backup: DataActionStatus.idle));
      case null:
        emit(state.copyWith(backup: DataActionStatus.failed));
    }
    emit(state.copyWith(backup: DataActionStatus.idle));
  }

  Future<void> _onRestorePressed(
    _RestorePressed event,
    Emitter<DataState> emit,
  ) async {
    final picked = await _files.pickText();
    if (picked case Right(value: null)) return; // Backed out.
    final file = picked.getRight().toNullable();
    if (file == null) {
      emit(state.copyWith(restore: const RestoreStep.failed()));
      return;
    }
    final info = (await _data.readBackup(file.contents))
        .getRight()
        .toNullable();
    emit(
      state.copyWith(
        restore: info == null
            ? RestoreStep.failed(fileName: file.name)
            : RestoreStep.confirming(file: file, info: info),
      ),
    );
  }

  Future<void> _onRestoreConfirmed(
    _RestoreConfirmed event,
    Emitter<DataState> emit,
  ) async {
    if (state.restore case RestoreConfirming(:final file, :final info)) {
      emit(state.copyWith(restore: const RestoreStep.restoring()));
      final restored = await _data.restoreBackup(file.contents);
      emit(
        state.copyWith(
          restore: restored.isRight()
              ? RestoreStep.restored(info)
              : RestoreStep.failed(fileName: file.name),
        ),
      );
    }
  }

  Future<void> _onDeleteConfirmed(
    _DeleteConfirmed event,
    Emitter<DataState> emit,
  ) async {
    emit(state.copyWith(delete: DataActionStatus.working));
    final deleted = await _data.deleteEverything();
    emit(
      state.copyWith(
        delete: deleted.isRight()
            ? DataActionStatus.done
            : DataActionStatus.failed,
      ),
    );
  }
}
