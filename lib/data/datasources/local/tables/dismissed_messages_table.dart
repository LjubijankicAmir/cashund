import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:drift/drift.dart';

/// Buddy messages the user closed, so they stay closed: a key per message
/// (e.g. one limit at one level) and the day it was closed.
@DataClassName('DismissedMessageRow')
class DismissedMessagesTable extends Table {
  @override
  String get tableName => 'dismissed_messages';

  TextColumn get messageKey => text()();
  TextColumn get dismissedOn => text().map(const DateOnlyConverter())();

  @override
  Set<Column> get primaryKey => {messageKey};
}
