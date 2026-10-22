import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:fpdart/fpdart.dart';

/// What a backup holds, shown before restoring it.
typedef BackupInfo = ({DateTime createdAt, int transactionCount});

/// How much is stored on the phone.
typedef DataCounts = ({int transactions, int categories, int limits});

/// All of the user's data at once: backups, CSV export and starting over.
abstract interface class DataRepository {
  /// Everything on the phone as one backup file's contents.
  FutureResult<String> createBackup();

  /// What [contents] holds, or a validation failure when it isn't a backup
  /// this app can read (another kind of file, damaged, or from a newer
  /// version of the app).
  FutureResult<BackupInfo> readBackup(String contents);

  /// Replaces everything on the phone with the backup. Nothing changes if
  /// it fails.
  FutureResult<Unit> restoreBackup(String contents);

  /// Transactions in [range] (all time when `null`), oldest first, as CSV:
  /// date, type, category, title, amount, currency. All currencies.
  /// [categoryName] names a category the way the user sees it.
  FutureResult<String> exportCsv({
    required String Function(Category category) categoryName,
    DateRange? range,
  });

  /// Deletes everything; the app starts over with onboarding.
  FutureResult<Unit> deleteEverything();

  StreamResult<DataCounts> watchCounts();
}
