import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'spending_limit.freezed.dart';

/// A soft limit on spending in one category, or on all spending, per week or
/// month. Nothing is ever blocked; the buddy gives a heads-up instead.
///
/// Its amount can change over time; see [LimitAmount].
@freezed
abstract class SpendingLimit with _$SpendingLimit {
  const factory SpendingLimit({
    required int id,
    required LimitPeriod period,

    /// Only transactions in this currency count towards it.
    required String currencyCode,
    required DateTime createdAt,

    /// `null` for the overall limit on all spending.
    int? categoryId,
  }) = _SpendingLimit;

  const SpendingLimit._();

  bool get isOverall => categoryId == null;
}

/// A limit's amount from the period starting on [effectiveFrom] onwards, so
/// changing it never rewrites past periods.
@freezed
abstract class LimitAmount with _$LimitAmount {
  const factory LimitAmount({
    /// The start of the first period it applies to.
    required DateTime effectiveFrom,
    required int amountMinor,
  }) = _LimitAmount;

  /// The amount in force for the period starting on [periodStart], or `null`
  /// before the limit existed. [amounts] must be sorted oldest first.
  static int? amountFor(List<LimitAmount> amounts, DateTime periodStart) {
    int? amount;
    for (final entry in amounts) {
      if (entry.effectiveFrom.isAfter(periodStart)) break;
      amount = entry.amountMinor;
    }
    return amount;
  }
}

/// A deleted limit with everything needed to bring it back as it was.
typedef LimitSnapshot = ({SpendingLimit limit, List<LimitAmount> amounts});
