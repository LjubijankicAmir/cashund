import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_occurred_on', columns: {#occurredOn})
@TableIndex(name: 'transactions_category_id', columns: {#categoryId})
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TransactionType>()();

  /// In the currency's smallest unit; always positive.
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Categories in use can't be deleted, only archived.
  IntColumn get categoryId => integer().references(
    CategoriesTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get title => text().withLength(min: 1, max: 200).nullable()();
  TextColumn get occurredOn => text().map(const DateOnlyConverter())();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => ['CHECK (amount_minor > 0)'];
}
