import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/transactions_dao.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dao, this._clock);

  final TransactionsDao _dao;
  final Clock _clock;

  @override
  FutureResult<Unit> add({
    required TransactionType type,
    required int amountMinor,
    required String currencyCode,
    required int categoryId,
    required DateTime occurredOn,
    String? title,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        left(const Failure.validation('The amount must be above zero.')),
      );
    }

    final trimmedTitle = title?.trim();
    return guardFuture(() async {
      await _dao.insert(
        TransactionsTableCompanion.insert(
          type: type,
          amountMinor: amountMinor,
          currencyCode: currencyCode,
          categoryId: categoryId,
          title: Value(
            trimmedTitle == null || trimmedTitle.isEmpty ? null : trimmedTitle,
          ),
          occurredOn: DateTime(
            occurredOn.year,
            occurredOn.month,
            occurredOn.day,
          ),
          createdAt: _clock.now(),
        ),
      );
      return unit;
    });
  }
}
