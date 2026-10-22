import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/dismissed_messages_dao.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/repositories/dismissed_message_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DismissedMessageRepository)
class DismissedMessageRepositoryImpl implements DismissedMessageRepository {
  DismissedMessageRepositoryImpl(this._dao);

  final DismissedMessagesDao _dao;

  @override
  StreamResult<Map<String, DateTime>> watchAll() {
    return guardStream(
      _dao.watchAll().map(
        (rows) => {for (final row in rows) row.messageKey: row.dismissedOn},
      ),
    );
  }

  @override
  FutureResult<Unit> dismiss(String key, DateTime day) {
    return guardFuture(() async {
      await _dao.upsert(
        DismissedMessagesTableCompanion.insert(
          messageKey: key,
          dismissedOn: DateTime(day.year, day.month, day.day),
        ),
      );
      return unit;
    });
  }
}
