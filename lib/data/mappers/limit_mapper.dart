import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/spending_limit.dart';

extension LimitRowMapper on LimitRow {
  SpendingLimit toEntity() {
    return SpendingLimit(
      id: id,
      period: period,
      currencyCode: currencyCode,
      createdAt: createdAt,
      categoryId: categoryId,
    );
  }
}

extension SpendingLimitMapper on SpendingLimit {
  /// The row as it was, with its id, for restoring a deleted limit.
  LimitRow toRow() {
    return LimitRow(
      id: id,
      period: period,
      currencyCode: currencyCode,
      categoryId: categoryId,
      createdAt: createdAt,
    );
  }
}

extension LimitAmountRowMapper on LimitAmountRow {
  LimitAmount toEntity() =>
      LimitAmount(effectiveFrom: effectiveFrom, amountMinor: amountMinor);
}

extension LimitAmountMapper on LimitAmount {
  LimitAmountRow toRow(int limitId) => LimitAmountRow(
    limitId: limitId,
    effectiveFrom: effectiveFrom,
    amountMinor: amountMinor,
  );

  LimitAmountsTableCompanion toCompanion(int limitId) =>
      LimitAmountsTableCompanion.insert(
        limitId: limitId,
        effectiveFrom: effectiveFrom,
        amountMinor: amountMinor,
      );
}

/// Only the day matters for when an amount applies.
DateTime dateOnly(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);
