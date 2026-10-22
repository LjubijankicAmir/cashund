import 'dart:convert';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/daos/backup_dao.dart';
import 'package:cashund/data/datasources/local/daos/transactions_dao.dart';
import 'package:cashund/data/dtos/backup_dto.dart';
import 'package:cashund/data/mappers/category_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DataRepository)
class DataRepositoryImpl implements DataRepository {
  DataRepositoryImpl(this._backups, this._transactions, this._clock);

  final BackupDao _backups;
  final TransactionsDao _transactions;
  final Clock _clock;

  static const _unreadable = Failure.validation("This file can't be read.");

  @override
  FutureResult<String> createBackup() => guardFuture(() async {
    final backup = await _backups.dump(_clock.now());
    return const JsonEncoder.withIndent(' ').convert(backup.toJson());
  });

  @override
  FutureResult<BackupInfo> readBackup(String contents) async =>
      _parse(contents).map(
        (backup) => (
          createdAt: backup.createdAt,
          transactionCount: backup.transactions.length,
        ),
      );

  @override
  FutureResult<Unit> restoreBackup(String contents) async {
    switch (_parse(contents)) {
      case Left(:final value):
        return left(value);
      case Right(value: final backup):
        return await guardFuture(() async {
          await _backups.replaceWith(backup);
          return unit;
        });
    }
  }

  /// Reads and checks a backup without touching the database.
  Result<BackupDto> _parse(String contents) {
    try {
      final backup = BackupDto.fromJson(
        jsonDecode(contents) as Map<String, Object?>,
      );
      // From a newer app: its tables may not fit this one's.
      if (backup.schemaVersion > _backups.attachedDatabase.schemaVersion) {
        return left(
          const Failure.validation('This backup is from a newer app.'),
        );
      }
      return right(backup);
    } on Object {
      return left(_unreadable);
    }
  }

  @override
  FutureResult<String> exportCsv({
    required String Function(Category category) categoryName,
    DateRange? range,
  }) => guardFuture(() async {
    final rows = await _transactions
        .watchFiltered(TransactionFilter(range: range))
        .first;
    final lines = [
      'date,type,category,title,amount,currency',
      for (final (transaction, category) in rows.reversed)
        [
          _isoDate(transaction.occurredOn),
          transaction.type.name,
          categoryName(category.toEntity()),
          transaction.title ?? '',
          _amount(
            transaction.type == TransactionType.expense
                ? -transaction.amountMinor
                : transaction.amountMinor,
            transaction.currencyCode,
          ),
          transaction.currencyCode,
        ].map(_csvField).join(','),
    ];
    // CRLF, as CSV files are expected to use.
    return '${lines.join('\r\n')}\r\n';
  });

  /// Quotes a field that holds a comma, quote or line break, doubling its
  /// quotes, so spreadsheets read it as one cell.
  static String _csvField(String value) => RegExp('[",\r\n]').hasMatch(value)
      ? '"${value.replaceAll('"', '""')}"'
      : value;

  static String _isoDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// A signed decimal with the currency's digits, e.g. -18.40.
  static String _amount(int minor, String currencyCode) {
    final digits = currencyByCode(currencyCode)?.decimalDigits ?? 2;
    final sign = minor < 0 ? '-' : '';
    final value = minor.abs();
    if (digits == 0) return '$sign$value';
    final unit = BigInt.from(10).pow(digits).toInt();
    final fraction = (value % unit).toString().padLeft(digits, '0');
    return '$sign${value ~/ unit}.$fraction';
  }

  @override
  FutureResult<Unit> deleteEverything() => guardFuture(() async {
    await _backups.wipe();
    return unit;
  });

  @override
  StreamResult<DataCounts> watchCounts() => guardStream(_backups.watchCounts());
}
