import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/transaction.dart';

extension TransactionRowMapper on TransactionRow {
  Transaction toEntity() {
    return Transaction(
      id: id,
      type: type,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      categoryId: categoryId,
      title: title,
      occurredOn: occurredOn,
      createdAt: createdAt,
    );
  }
}
