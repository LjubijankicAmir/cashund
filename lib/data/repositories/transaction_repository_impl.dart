import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/transactions_dao.dart';
import 'package:cashund/data/mappers/category_mapper.dart';
import 'package:cashund/data/mappers/transaction_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
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
  FutureResult<Transaction> add({
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

    return guardFuture(() async {
      final row = await _dao.insert(
        TransactionsTableCompanion.insert(
          type: type,
          amountMinor: amountMinor,
          currencyCode: currencyCode,
          categoryId: categoryId,
          title: Value(_cleanTitle(title)),
          occurredOn: DateTime(
            occurredOn.year,
            occurredOn.month,
            occurredOn.day,
          ),
          createdAt: _clock.now(),
        ),
      );
      return row.toEntity();
    });
  }

  @override
  StreamResult<PeriodSummary> watchSummary(
    DateRange range, {
    required String currencyCode,
  }) {
    return guardStream(
      _dao.watchTotalsByType(range, currencyCode).map((totals) {
        final income = totals[TransactionType.income];
        final expense = totals[TransactionType.expense];
        return PeriodSummary(
          incomeMinor: income?.totalMinor ?? 0,
          expenseMinor: expense?.totalMinor ?? 0,
          transactionCount: (income?.count ?? 0) + (expense?.count ?? 0),
        );
      }),
    );
  }

  @override
  StreamResult<List<CategorySpending>> watchSpendingByCategory(
    DateRange range, {
    required String currencyCode,
  }) {
    return guardStream(
      _dao
          .watchExpensesByCategory(range, currencyCode)
          .map(
            (rows) => [
              for (final (row, total) in rows)
                CategorySpending(category: row.toEntity(), amountMinor: total),
            ],
          ),
    );
  }

  @override
  StreamResult<bool> watchHasAny() => guardStream(_dao.watchHasAny());

  @override
  StreamResult<Map<DateTime, int>> watchExpensesByDay(
    DateRange range, {
    required String currencyCode,
    int? categoryId,
  }) => guardStream(
    _dao.watchExpensesByDay(range, currencyCode, categoryId: categoryId),
  );

  @override
  FutureResult<int> count() => guardFuture(_dao.countAll);

  @override
  StreamResult<int> watchCountInCurrency(String currencyCode) =>
      guardStream(_dao.watchCountInCurrency(currencyCode));

  @override
  StreamResult<List<TransactionWithCategory>> watchFiltered(
    TransactionFilter filter,
  ) {
    return guardStream(
      _dao
          .watchFiltered(filter)
          .map(
            (rows) => [
              for (final (transaction, category) in rows)
                TransactionWithCategory(
                  transaction: transaction.toEntity(),
                  category: category.toEntity(),
                ),
            ],
          ),
    );
  }

  @override
  FutureResult<Unit> update({
    required int id,
    required TransactionType type,
    required int amountMinor,
    required int categoryId,
    required DateTime occurredOn,
    String? title,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        left(const Failure.validation('The amount must be above zero.')),
      );
    }
    return guardFuture(() async {
      await _dao.updateById(
        id,
        TransactionsTableCompanion(
          type: Value(type),
          amountMinor: Value(amountMinor),
          categoryId: Value(categoryId),
          title: Value(_cleanTitle(title)),
          occurredOn: Value(
            DateTime(occurredOn.year, occurredOn.month, occurredOn.day),
          ),
        ),
      );
      return unit;
    });
  }

  @override
  FutureResult<Unit> delete(int id) {
    return guardFuture(() async {
      await _dao.deleteById(id);
      return unit;
    });
  }

  @override
  FutureResult<Unit> restore(Transaction transaction) {
    return guardFuture(() async {
      await _dao.insert(
        TransactionsTableCompanion.insert(
          id: Value(transaction.id),
          type: transaction.type,
          amountMinor: transaction.amountMinor,
          currencyCode: transaction.currencyCode,
          categoryId: transaction.categoryId,
          title: Value(transaction.title),
          occurredOn: transaction.occurredOn,
          createdAt: transaction.createdAt,
        ),
      );
      return unit;
    });
  }

  /// No title rather than a blank one.
  static String? _cleanTitle(String? title) {
    final trimmed = title?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
