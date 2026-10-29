import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/home_widgets/widget_snapshot.dart';

/// Everything the widgets show, in the selected currency, as of `now`.
typedef WidgetInputs = ({
  DateTime now,
  Currency currency,
  WeekStart weekStart,

  /// Whether anything was ever logged in [currency].
  bool hasTransactions,
  PeriodSummary today,
  PeriodSummary week,

  /// Where most went this week; `null` before anything was spent.
  Category? weekTopCategory,

  /// This week's and this month's limits, most used first (see
  /// [LimitProgress.byUse]).
  List<LimitProgress> weekLimits,
  List<LimitProgress> monthLimits,
});

/// Words and formats what the widgets show, ahead of time: one entry now,
/// then one at each coming period boundary with that period started over.
/// Nothing can be logged in between without the app writing a new snapshot,
/// so the later entries are exactly what the widgets should show then.
abstract final class WidgetSnapshotBuilder {
  static const limitsShown = 2;

  static WidgetSnapshot build(WidgetInputs inputs, AppLocalizations l10n) {
    final now = inputs.now;
    final day = Period.day.rangeContaining(now, weekStart: inputs.weekStart);
    final week = Period.week.rangeContaining(now, weekStart: inputs.weekStart);
    final month = Period.month.rangeContaining(
      now,
      weekStart: inputs.weekStart,
    );
    final boundaries = {day.end, week.end, month.end}.toList()..sort();

    return WidgetSnapshot(
      entries: [
        // From the start of today, so the same totals give the same snapshot.
        _entry(inputs, l10n, from: day.start),
        for (final boundary in boundaries)
          _entry(
            from: boundary,
            _startedOver(
              inputs,
              at: boundary,
              day: !day.contains(boundary),
              week: !week.contains(boundary),
              month: !month.contains(boundary),
            ),
            l10n,
          ),
      ],
    );
  }

  /// [inputs] at [at], with the periods that have ended by then empty.
  static WidgetInputs _startedOver(
    WidgetInputs inputs, {
    required DateTime at,
    required bool day,
    required bool week,
    required bool month,
  }) {
    List<LimitProgress> unspent(List<LimitProgress> limits) => [
      for (final limit in limits) limit.copyWith(spentMinor: 0),
    ];

    return (
      now: at,
      currency: inputs.currency,
      weekStart: inputs.weekStart,
      hasTransactions: inputs.hasTransactions,
      today: day ? const PeriodSummary() : inputs.today,
      week: week ? const PeriodSummary() : inputs.week,
      weekTopCategory: week ? null : inputs.weekTopCategory,
      weekLimits: week ? unspent(inputs.weekLimits) : inputs.weekLimits,
      monthLimits: month ? unspent(inputs.monthLimits) : inputs.monthLimits,
    );
  }

  static WidgetEntry _entry(
    WidgetInputs inputs,
    AppLocalizations l10n, {
    required DateTime from,
  }) {
    String money(int minor, {bool signed = false}) =>
        formatMoney(minor, inputs.currency, signed: signed);

    final overall = inputs.weekLimits.where((limit) => limit.limit.isOverall);
    final weekOverall = overall.isEmpty ? null : overall.first;
    final allLimits = [...inputs.weekLimits, ...inputs.monthLimits];
    final overs =
        allLimits.where((limit) => limit.status == LimitStatus.over).toList()
          ..sort(LimitProgress.byUse);

    return WidgetEntry(
      from: from,
      mood: _mood(inputs, allLimits),
      spending: _spending(inputs, l10n, weekOverall, overs, money),
      today: TodayTile(
        title: l10n.widgetToday,
        hero: money(-inputs.today.expenseMinor),
        caption: l10n.widgetTransactions(inputs.today.transactionCount),
        weekLabel: l10n.widgetThisWeek,
        weekValue: money(-inputs.week.expenseMinor),
      ),
      todayWeek: TodayWeekTile(
        todayTitle: l10n.widgetToday,
        todayHero: money(-inputs.today.expenseMinor),
        todayCaption: l10n.widgetTransactions(inputs.today.transactionCount),
        weekTitle: l10n.homeCaptionWeek(
          formatDateRange(
            Period.week.rangeContaining(
              inputs.now,
              weekStart: inputs.weekStart,
            ),
            'en',
          ),
        ),
        outLabel: l10n.widgetOut,
        outValue: money(-inputs.week.expenseMinor),
        inLabel: l10n.widgetIn,
        inValue: money(inputs.week.incomeMinor, signed: true),
        topLabel: l10n.widgetTop,
        topValue: inputs.weekTopCategory?.label(l10n) ?? l10n.widgetTopNone,
        topColor: inputs.weekTopCategory?.color,
      ),
      compact: _compact(inputs, l10n, weekOverall, money),
      limits: _limits(inputs, l10n, money),
    );
  }

  static WidgetMood _mood(WidgetInputs inputs, List<LimitProgress> limits) {
    if (!inputs.hasTransactions) return WidgetMood.sleeping;
    if (limits.any((limit) => limit.status != LimitStatus.under)) {
      return WidgetMood.worried;
    }
    if (limits.isNotEmpty || inputs.week.balanceMinor > 0) {
      return WidgetMood.happy;
    }
    return WidgetMood.listening;
  }

  static SpendingTile _spending(
    WidgetInputs inputs,
    AppLocalizations l10n,
    LimitProgress? weekOverall,
    List<LimitProgress> overs,
    String Function(int minor) money,
  ) {
    if (!inputs.hasTransactions) {
      return SpendingTile(
        kind: SpendingTileKind.empty,
        title: l10n.widgetThisWeek,
        hero: l10n.widgetNothingYet,
        caption: l10n.widgetLogFirst,
      );
    }
    if (overs.isNotEmpty) {
      final over = overs.first;
      return SpendingTile(
        kind: SpendingTileKind.over,
        title: l10n.widgetOverALimit,
        hero: money(over.overByMinor),
        caption: switch (over.category) {
          final category? => l10n.widgetOverCategory(category.label(l10n)),
          null => l10n.widgetOverOverall(over.limit.period.name),
        },
        fraction: 1,
      );
    }
    return SpendingTile(
      kind: SpendingTileKind.normal,
      title: l10n.widgetThisWeek,
      hero: money(inputs.week.expenseMinor),
      caption: weekOverall == null
          ? l10n.widgetSpentThisWeek
          : l10n.widgetOfLimit(_limitAmount(weekOverall, inputs.currency)),
      fraction: weekOverall == null ? null : _filled(weekOverall),
    );
  }

  static CompactTile _compact(
    WidgetInputs inputs,
    AppLocalizations l10n,
    LimitProgress? weekOverall,
    String Function(int minor) money,
  ) {
    if (weekOverall == null) {
      return CompactTile(
        hero: money(inputs.week.expenseMinor),
        caption: l10n.widgetSpentThisWeek,
      );
    }
    final over = weekOverall.status == LimitStatus.over;
    return CompactTile(
      hero: money(over ? weekOverall.overByMinor : weekOverall.leftMinor),
      caption: over ? l10n.widgetOverThisWeek : l10n.widgetLeftThisWeek,
      fraction: _filled(weekOverall),
    );
  }

  /// The two most used category limits of the week, or of the month when
  /// only monthly ones are set.
  static LimitsTile? _limits(
    WidgetInputs inputs,
    AppLocalizations l10n,
    String Function(int minor) money,
  ) {
    List<LimitProgress> ofCategories(List<LimitProgress> limits) => [
      for (final limit in limits)
        if (!limit.limit.isOverall) limit,
    ];
    final week = ofCategories(inputs.weekLimits);
    final period = week.isNotEmpty ? LimitPeriod.week : LimitPeriod.month;
    final shown = (week.isNotEmpty ? week : ofCategories(inputs.monthLimits))
        .take(limitsShown)
        .toList();
    if (shown.isEmpty) return null;

    final top = shown.first;
    final topName = top.category!.name(l10n);
    return LimitsTile(
      title: l10n.widgetLimitsTitle(period.name),
      status: switch (top.status) {
        LimitStatus.over => l10n.widgetOverBy(money(top.overByMinor)),
        LimitStatus.near => l10n.widgetLimitClose(topName),
        LimitStatus.under => l10n.widgetAllUnder,
      },
      warns: top.status != LimitStatus.under,
      rows: [
        for (final limit in shown)
          LimitRowTile(
            limitId: limit.limit.id,
            emoji: limit.category!.emoji,
            name: limit.category!.name(l10n),
            spent: money(limit.spentMinor),
            amount: money(limit.amountMinor),
            fraction: _filled(limit),
            status: limit.status,
            color: limit.category!.color,
          ),
      ],
    );
  }

  /// How full a bar for [limit] is; a limit past its amount fills it.
  static double _filled(LimitProgress limit) => min(limit.fraction, 1);

  /// "$600" for a round limit, "$650.50" otherwise.
  static String _limitAmount(LimitProgress limit, Currency currency) {
    final unit = pow(10, currency.decimalDigits).toInt();
    return limit.amountMinor % unit == 0
        ? formatMoneyWhole(limit.amountMinor, currency)
        : formatMoney(limit.amountMinor, currency);
  }
}
