part of 'data_bloc.dart';

enum DataActionStatus { idle, working, done, failed }

/// Where restoring a backup is at.
@freezed
sealed class RestoreStep with _$RestoreStep {
  const factory RestoreStep.idle() = RestoreIdle;

  /// A backup was read; the user decides whether to replace everything.
  const factory RestoreStep.confirming({
    required PickedFile file,
    required BackupInfo info,
  }) = RestoreConfirming;
  const factory RestoreStep.restoring() = RestoreRestoring;
  const factory RestoreStep.restored(BackupInfo info) = RestoreDone;

  /// The picked file isn't a backup this app can read; nothing changed.
  const factory RestoreStep.failed({String? fileName}) = RestoreFailed;
}

@freezed
abstract class DataState with _$DataState {
  const factory DataState({
    required DateTime today,

    /// `null` until loaded.
    UserPreferences? preferences,

    /// `null` until loaded.
    DataCounts? counts,

    /// Logged since the last backup.
    @Default(0) int sinceBackup,
    @Default(DataActionStatus.idle) DataActionStatus backup,
    @Default(RestoreStep.idle()) RestoreStep restore,
    @Default(DataActionStatus.idle) DataActionStatus delete,
  }) = _DataState;

  const DataState._();

  /// How long a backup is fresh.
  static const reminderAfter = Duration(days: 30);

  DateTime? get lastBackupAt => preferences?.lastBackupAt;

  /// Never backed up, or a long time ago with new transactions since. Only
  /// once there's something to back up.
  bool get remindToBackUp {
    final (counts, last) = (this.counts, lastBackupAt);
    if (counts == null || preferences == null || counts.transactions == 0) {
      return false;
    }
    if (last == null) return true;
    return today.difference(last) > reminderAfter && sinceBackup > 0;
  }
}
