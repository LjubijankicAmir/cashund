import 'package:cashund/data/datasources/local/converters/date_only_converter.dart';
import 'package:cashund/data/datasources/local/tables/categories_table.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:drift/drift.dart';

/// Spending limits. Their amounts live in [LimitAmountsTable], so a change
/// only applies from then on.
@DataClassName('LimitRow')
class LimitsTable extends Table {
  @override
  String get tableName => 'limits';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get period => textEnum<LimitPeriod>()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// `null` for the overall limit. Categories are archived, never deleted,
  /// so a limit keeps its category.
  IntColumn get categoryId => integer().nullable().references(
    CategoriesTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  DateTimeColumn get createdAt => dateTime()();

  /// One limit per category, period and currency. SQLite treats every
  /// `null` as different, so the repository checks the overall limit itself.
  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, period, currencyCode},
  ];
}

/// A limit's amount from [effectiveFrom] (a period start) onwards.
@DataClassName('LimitAmountRow')
class LimitAmountsTable extends Table {
  @override
  String get tableName => 'limit_amounts';

  IntColumn get limitId =>
      integer().references(LimitsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get effectiveFrom => text().map(const DateOnlyConverter())();
  IntColumn get amountMinor => integer()();

  @override
  Set<Column> get primaryKey => {limitId, effectiveFrom};

  @override
  List<String> get customConstraints => ['CHECK (amount_minor > 0)'];
}
