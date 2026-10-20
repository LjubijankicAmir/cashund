import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class LimitRepository {
  /// The [period] limits in [currencyCode], with what's spent in [range],
  /// most used first. Limits on archived categories are left out.
  StreamResult<List<LimitProgress>> watchProgress({
    required LimitPeriod period,
    required String currencyCode,
    required DateRange range,
  });

  /// Every limit in [currencyCode], both periods, archived categories
  /// left out.
  StreamResult<List<SpendingLimit>> watchAll(String currencyCode);

  /// One limit, or `null` once it's deleted.
  StreamResult<SpendingLimit?> watch(int id);

  /// The limit's amounts over time, oldest first.
  StreamResult<List<LimitAmount>> watchAmounts(int id);

  /// Adds a limit on [categoryId], or on all spending when `null`, from the
  /// period starting on [effectiveFrom]. There's at most one per category,
  /// period and currency. [amountMinor] must be above zero.
  FutureResult<SpendingLimit> create({
    required LimitPeriod period,
    required String currencyCode,
    required int? categoryId,
    required int amountMinor,
    required DateTime effectiveFrom,
  });

  /// Sets a new amount from the period starting on [effectiveFrom] on;
  /// earlier periods keep theirs.
  FutureResult<Unit> changeAmount(
    int id, {
    required int amountMinor,
    required DateTime effectiveFrom,
  });

  /// Deletes a limit and returns it as it was, for [restore].
  FutureResult<LimitSnapshot> delete(int id);

  /// Brings back a deleted limit with the same id and history.
  FutureResult<Unit> restore(LimitSnapshot snapshot);
}
