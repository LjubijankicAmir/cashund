import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/tables/transactions_table.dart';
import 'package:drift/drift.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  Future<int> insert(TransactionsTableCompanion row) =>
      into(transactionsTable).insert(row);
}
