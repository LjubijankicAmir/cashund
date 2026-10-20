import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/limits_dao.dart';
import 'package:cashund/data/mappers/category_mapper.dart';
import 'package:cashund/data/mappers/limit_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LimitRepository)
class LimitRepositoryImpl implements LimitRepository {
  LimitRepositoryImpl(this._dao, this._clock);

  final LimitsDao _dao;
  final Clock _clock;

  static const _taken = Failure.validation(
    'There is already a limit for this category and period.',
  );

  @override
  StreamResult<List<LimitProgress>> watchProgress({
    required LimitPeriod period,
    required String currencyCode,
    required DateRange range,
  }) {
    return guardStream(
      _dao
          .watchSpending(
            period: period,
            currencyCode: currencyCode,
            range: range,
          )
          .map(
            (rows) => [
              for (final row in rows)
                LimitProgress(
                  limit: row.limit.toEntity(),
                  category: row.category?.toEntity(),
                  range: range,
                  amountMinor: row.amountMinor,
                  spentMinor: row.spentMinor,
                ),
            ]..sort(LimitProgress.byUse),
          ),
    );
  }

  @override
  StreamResult<List<SpendingLimit>> watchAll(String currencyCode) {
    return guardStream(
      _dao
          .watchAll(currencyCode)
          .map((rows) => [for (final row in rows) row.toEntity()]),
    );
  }

  @override
  StreamResult<SpendingLimit?> watch(int id) =>
      guardStream(_dao.watchById(id).map((row) => row?.toEntity()));

  @override
  StreamResult<List<LimitAmount>> watchAmounts(int id) {
    return guardStream(
      _dao
          .watchAmounts(id)
          .map((rows) => [for (final row in rows) row.toEntity()]),
    );
  }

  @override
  FutureResult<SpendingLimit> create({
    required LimitPeriod period,
    required String currencyCode,
    required int? categoryId,
    required int amountMinor,
    required DateTime effectiveFrom,
  }) async {
    if (amountMinor <= 0) {
      return left(const Failure.validation('A limit must be above zero.'));
    }
    if (categoryId == null) {
      final existing = await guardFuture(
        () => _dao.findOverall(period, currencyCode),
      );
      if (existing case Left(:final value)) return left(value);
      if (existing case Right(value: _?)) return left(_taken);
    }

    final created = await guardFuture(
      () => _dao.insert(
        LimitsTableCompanion.insert(
          period: period,
          currencyCode: currencyCode,
          categoryId: Value(categoryId),
          createdAt: _clock.now(),
        ),
        amount: (id) => LimitAmount(
          effectiveFrom: dateOnly(effectiveFrom),
          amountMinor: amountMinor,
        ).toCompanion(id),
      ),
    );
    // The unique key catches a second limit on the same category.
    return created.match<Result<SpendingLimit>>(
      (failure) => left(
        failure.maybeWhen(
          database: (message) =>
              (message ?? '').contains('UNIQUE') ? _taken : failure,
          orElse: () => failure,
        ),
      ),
      (row) => right(row.toEntity()),
    );
  }

  @override
  FutureResult<Unit> changeAmount(
    int id, {
    required int amountMinor,
    required DateTime effectiveFrom,
  }) async {
    if (amountMinor <= 0) {
      return left(const Failure.validation('A limit must be above zero.'));
    }
    return await guardFuture(() async {
      await _dao.upsertAmount(
        LimitAmount(
          effectiveFrom: dateOnly(effectiveFrom),
          amountMinor: amountMinor,
        ).toCompanion(id),
      );
      return unit;
    });
  }

  @override
  FutureResult<LimitSnapshot> delete(int id) async {
    final found = await guardFuture(() async {
      final limit = await _dao.findById(id);
      if (limit == null) return null;
      final amounts = await _dao.amounts(id);
      await _dao.deleteById(id);
      return (
        limit: limit.toEntity(),
        amounts: [for (final amount in amounts) amount.toEntity()],
      );
    });
    return found.flatMap(
      (snapshot) =>
          snapshot == null ? left(const Failure.notFound()) : right(snapshot),
    );
  }

  @override
  FutureResult<Unit> restore(LimitSnapshot snapshot) {
    final limit = snapshot.limit;
    return guardFuture(() async {
      await _dao.restore(limit.toRow(), [
        for (final amount in snapshot.amounts) amount.toRow(limit.id),
      ]);
      return unit;
    });
  }
}
