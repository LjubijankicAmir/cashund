import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TransactionType>()();

  /// Set for built-in categories, e.g. `eating_out`.
  TextColumn get predefinedKey => text().nullable()();

  /// Set once the user renames a category; otherwise the translated default.
  TextColumn get customName => text().withLength(min: 1, max: 64).nullable()();
  TextColumn get emoji => text()();
  TextColumn get color => textEnum<CategoryColor>()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {type, predefinedKey},
  ];
}
