import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';

/// What the buddy says on Home, based on the selected period.
String homeBuddyMessage(
  AppLocalizations l10n, {
  required String buddyName,
  required Period period,
  required Currency currency,
  required bool hasTransactions,
  required PeriodSummary summary,
  required List<SpendingSlice> slices,
}) {
  if (summary.isEmpty) {
    return hasTransactions
        ? l10n.homeBuddyQuiet(period.name)
        : l10n.homeBuddyWelcome(buddyName);
  }
  if (summary.expenseMinor == 0) {
    return l10n.homeBuddyIncome(
      period.name,
      formatMoney(summary.incomeMinor, currency),
    );
  }
  if (summary.incomeMinor > 0 && summary.balanceMinor < 0) {
    return l10n.homeBuddyOverspent(
      period.name,
      formatMoney(-summary.balanceMinor, currency),
    );
  }
  return switch (slices.firstOrNull?.category) {
    final top? => l10n.homeBuddyTopCategory(period.name, top.label(l10n)),
    null => l10n.homeBuddyQuiet(period.name),
  };
}
