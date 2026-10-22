part of 'data_bloc.dart';

@freezed
sealed class DataEvent with _$DataEvent {
  /// Follows the last backup and what's stored.
  const factory DataEvent.started() = _Started;

  /// Writes a backup and offers it in the share sheet.
  const factory DataEvent.backupPressed() = _BackupPressed;

  /// Picks a backup file and reads it, so the user can confirm.
  const factory DataEvent.restorePressed() = _RestorePressed;
  const factory DataEvent.restoreConfirmed() = _RestoreConfirmed;
  const factory DataEvent.restoreCancelled() = _RestoreCancelled;

  /// Deletes everything; the app starts over with onboarding.
  const factory DataEvent.deleteConfirmed() = _DeleteConfirmed;

  /// Internal: follows what was logged since the last backup.
  const factory DataEvent.sinceBackupWatched() = _SinceBackupWatched;
}
