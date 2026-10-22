import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/tables/dismissed_messages_table.dart';
import 'package:drift/drift.dart';

part 'dismissed_messages_dao.g.dart';

@DriftAccessor(tables: [DismissedMessagesTable])
class DismissedMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$DismissedMessagesDaoMixin {
  DismissedMessagesDao(super.attachedDatabase);

  Stream<List<DismissedMessageRow>> watchAll() =>
      select(dismissedMessagesTable).watch();

  /// Records [row], replacing an earlier dismissal of the same message.
  Future<void> upsert(DismissedMessagesTableCompanion row) =>
      into(dismissedMessagesTable).insertOnConflictUpdate(row);
}
