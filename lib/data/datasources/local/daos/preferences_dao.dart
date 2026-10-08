import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/tables/preferences_table.dart';
import 'package:drift/drift.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [PreferencesTable])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.attachedDatabase);

  Future<PreferencesRow?> getRow() =>
      select(preferencesTable).getSingleOrNull();

  Stream<PreferencesRow?> watchRow() =>
      select(preferencesTable).watchSingleOrNull();

  /// The only row's id. An omitted INTEGER PRIMARY KEY would get the next
  /// rowid instead of conflicting, so every write sets it explicitly.
  static const _rowId = 1;

  /// Inserts the single row, or replaces it if it already exists.
  Future<void> upsert(PreferencesTableCompanion row) {
    return into(preferencesTable)
        .insertOnConflictUpdate(row.copyWith(id: const Value(_rowId)));
  }
}
