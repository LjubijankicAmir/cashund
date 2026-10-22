import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:intl/intl.dart';

/// The buddy's one line on how a finished week or month went.
String recapText(
  AppLocalizations l10n,
  String locale,
  PeriodRecap recap,
  Currency currency,
) {
  final month = DateFormat.MMMM(locale);
  final previousMonth = DateTime(
    recap.range.start.year,
    recap.range.start.month - 1,
  );
  final kept = recap.limitsKept;
  final args = (
    period: recap.period == LimitPeriod.week
        ? formatDateRange(recap.range, locale)
        : month.format(recap.range.start),
    previous: recap.period == LimitPeriod.week
        ? l10n.recapWeekBefore
        : month.format(previousMonth),
    amount: formatMoney(recap.spentMinor, currency),
    diff: formatMoney(recap.differenceMinor, currency),
    income: formatMoney(recap.incomeMinor, currency),
    topCategory: recap.top?.category.label(l10n) ?? '',
    kept: '${recap.keptPercent}%',
    limitsKept: kept == null
        ? ''
        : l10n.recapLimitsKeptValue(kept.kept, kept.of),
  );

  final line = switch (recap.line) {
    RecapLine.weekLess => l10n.recapWeekLess,
    RecapLine.weekMore => l10n.recapWeekMore,
    RecapLine.weekTopCategory => l10n.recapWeekTopCategory,
    RecapLine.weekLimitsKept => l10n.recapWeekLimitsKept,
    RecapLine.monthLess => l10n.recapMonthLess,
    RecapLine.monthMore => l10n.recapMonthMore,
    RecapLine.monthKept => l10n.recapMonthKept,
    RecapLine.monthSummary => l10n.recapMonthSummary,
  };
  return line(
    args.period,
    args.previous,
    args.amount,
    args.diff,
    args.income,
    args.topCategory,
    args.kept,
    args.limitsKept,
  );
}

/// "Your week, Oct 5 – 11" or "Your September", after the buddy's name.
String recapMeta(AppLocalizations l10n, String locale, PeriodRecap recap) =>
    switch (recap.period) {
      LimitPeriod.week => l10n.recapMetaWeek(
        formatDateRange(recap.range, locale),
      ),
      LimitPeriod.month => l10n.recapMetaMonth(
        DateFormat.MMMM(locale).format(recap.range.start),
      ),
    };
