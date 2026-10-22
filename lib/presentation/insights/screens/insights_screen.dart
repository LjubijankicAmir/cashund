import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy_says.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/common/widgets/period_stepper.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/common/widgets/trend_bars.dart';
import 'package:cashund/presentation/insights/bloc/insights_bloc.dart';
import 'package:cashund/presentation/insights/insights_labels.dart';
import 'package:cashund/presentation/insights/widgets/in_out_card.dart';
import 'package:cashund/presentation/insights/widgets/ranked_spending_card.dart';
import 'package:cashund/presentation/insights/widgets/trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Where the money went, one week, month or year at a time.
@RoutePage()
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({this.period = InsightsPeriod.month, super.key});

  /// The kind of period it opens on, e.g. the one selected on Home.
  final InsightsPeriod period;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InsightsBloc>()..add(InsightsEvent.started(period)),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  void _openCategory(BuildContext context, Category category) {
    final state = context.read<InsightsBloc>().state;
    final range = state.range;
    if (range == null) return;
    unawaited(
      context.router.push(
        CategoryInsightsRoute(
          category: category,
          period: state.period,
          range: range,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<InsightsBloc>();
    final state = context.watch<InsightsBloc>().state;
    final (range, currency, summary) = (
      state.range,
      state.currency,
      state.summary,
    );
    final period = state.period;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s3,
            CashundSpace.s6,
            CashundSpace.s8,
          ),
          children: [
            PushedPageHeader(title: l10n.insightsTitle),
            if (range != null && currency != null) ...[
              const SizedBox(height: CashundSpace.s5),
              PeriodStepper(
                segments: [
                  (InsightsPeriod.week, l10n.periodWeek),
                  (InsightsPeriod.month, l10n.periodMonth),
                  (InsightsPeriod.year, l10n.periodYear),
                ],
                selected: period,
                onSelected: (period) =>
                    bloc.add(InsightsEvent.periodSelected(period)),
                title: period.title(l10n, locale, range),
                subtitle: period.subtitle(l10n, locale, range, state.today),
                onPrevious: state.canGoBack
                    ? () => bloc.add(const InsightsEvent.previousPressed())
                    : null,
                onNext: state.canGoForward
                    ? () => bloc.add(const InsightsEvent.nextPressed())
                    : null,
              ),
              const SizedBox(height: CashundSpace.s6),
              if (state.isEmpty)
                _EmptyPeriod(state: state)
              else if (summary != null) ...[
                BuddySays(
                  buddyName: state.preferences!.buddyName,
                  message: _summaryLine(l10n, locale, state),
                ),
                if (state.slices.isNotEmpty) ...[
                  const SizedBox(height: CashundSpace.s5),
                  RankedSpendingCard(
                    slices: state.slices,
                    totalMinor: summary.expenseMinor,
                    otherCount:
                        state.spending.length - SpendingBreakdown.maxCategories,
                    currency: currency,
                    onCategory: (category) => _openCategory(context, category),
                    onOther: () => _showOther(context, state),
                  ),
                ],
                const SizedBox(height: CashundSpace.s4),
                TrendCard(
                  title: switch (period) {
                    InsightsPeriod.week => l10n.insightsTrendWeeks,
                    InsightsPeriod.month => l10n.insightsTrendMonths,
                    InsightsPeriod.year => l10n.insightsTrendYear,
                  },
                  averageMinor: state.averageMinor,
                  currency: currency,
                  currentLabel: _currentLegend(l10n, locale, state),
                  pastLabel: l10n.insightsLegendEarlier(
                    period == InsightsPeriod.week ? 'week' : 'month',
                  ),
                  bars: [
                    for (final point in state.trend)
                      TrendBar(
                        label: period.barLabel(locale, point.range),
                        valueMinor: point.totalMinor,
                        isCurrent:
                            point.range.contains(state.today) ||
                            point.isCurrent && period != InsightsPeriod.year,
                        isFuture: point.isFuture,
                      ),
                  ],
                ),
                const SizedBox(height: CashundSpace.s4),
                InOutCard(
                  summary: summary,
                  label: period.shortLabel(l10n, locale, range),
                  currency: currency,
                ),
                const SizedBox(height: CashundSpace.s5),
                _CurrencyNote(code: currency.code),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// The trend's highlighted bar: "October so far", or the period's name.
  static String _currentLegend(
    AppLocalizations l10n,
    String locale,
    InsightsState state,
  ) {
    final period = state.period;
    final day = state.today;
    final current = period == InsightsPeriod.year
        ? DateTime(day.year, day.month)
        : state.range!.start;
    final label = period == InsightsPeriod.year
        ? DateFormat.MMMM(locale).format(current)
        : period.shortLabel(l10n, locale, state.range!);
    final running = period == InsightsPeriod.year || state.isCurrent;
    return running ? l10n.insightsLegendSoFar(label) : label;
  }

  /// One line from the buddy on how the period went.
  static String _summaryLine(
    AppLocalizations l10n,
    String locale,
    InsightsState state,
  ) {
    final (range, summary, currency) = (
      state.range!,
      state.summary!,
      state.currency!,
    );
    final period = state.period;

    if (period == InsightsPeriod.year) {
      final spent = formatMoney(summary.expenseMinor, currency);
      final average = formatMoneyWhole(
        summary.expenseMinor ~/ state.monthsSoFar,
        currency,
      );
      return state.isCurrent
          ? l10n.insightsYear(spent, average)
          : l10n.insightsYearWhole(
              DateFormat.y(locale).format(range.start),
              spent,
              average,
            );
    }
    if (summary.transactionCount < InsightsState.minForComparison) {
      return l10n.insightsFew(summary.transactionCount);
    }
    final comparison = state.comparison;
    if (comparison == null) {
      return l10n.insightsSpent(formatMoney(summary.expenseMinor, currency));
    }

    final previous = period.previousLabel(
      l10n,
      locale,
      period.previous(range, weekStart: state.preferences!.weekStart),
    );
    final diff = formatMoney(
      (comparison.current - comparison.previous).abs(),
      currency,
    );
    final less = comparison.current <= comparison.previous;
    return switch ((less, state.isCurrent)) {
      (true, true) => l10n.insightsLess(diff, previous),
      (true, false) => l10n.insightsLessWhole(diff, previous),
      (false, true) => l10n.insightsMore(diff, previous),
      (false, false) => l10n.insightsMoreWhole(diff, previous),
    };
  }

  /// The categories folded into "Other", each opening its detail.
  void _showOther(BuildContext context, InsightsState state) {
    final l10n = context.l10n;
    final currency = state.currency!;
    final others = state.spending.skip(SpendingBreakdown.maxCategories);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        builder: (sheetContext) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s4,
            CashundSpace.s6,
            CashundSpace.s6,
          ),
          children: [
            Text(
              l10n.insightsOtherTitle,
              style: CashundText.title.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: CashundSpace.s3),
            for (final item in others)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CategoryMark(color: item.category.color),
                minLeadingWidth: 3,
                title: Text(item.category.label(l10n)),
                trailing: Text(formatMoney(item.amountMinor, currency)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCategory(context, item.category);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A period with nothing logged: the buddy asleep and a way to data.
class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final (range, firstDay, target) = (
      state.range!,
      state.firstDay,
      state.dataRange,
    );
    final period = state.period;
    final beforeFirst = firstDay != null && !range.end.isAfter(firstDay);

    return Padding(
      padding: const EdgeInsets.only(top: CashundSpace.s6),
      child: Column(
        spacing: CashundSpace.s3,
        children: [
          const Buddy(expression: BuddyExpression.sleeping, width: 130),
          Text(
            l10n.insightsEmptyTitle(period.shortLabel(l10n, locale, range)),
            textAlign: TextAlign.center,
            style: CashundText.title.copyWith(color: scheme.onSurface),
          ),
          Text(
            beforeFirst
                ? l10n.insightsEmptyBeforeFirst(
                    DateFormat.MMMd(locale).format(firstDay),
                    period.name,
                  )
                : l10n.insightsEmptyBody(period.name),
            textAlign: TextAlign.center,
            style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (target != null && target != range) ...[
            const SizedBox(height: CashundSpace.s2),
            FilledButton.tonal(
              onPressed: () => context.read<InsightsBloc>().add(
                const InsightsEvent.jumpedToData(),
              ),
              child: Text(
                l10n.insightsGoTo(period.shortLabel(l10n, locale, target)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Totals only count the selected currency, so say which.
class _CurrencyNote extends StatelessWidget {
  const _CurrencyNote({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CashundSpace.s3,
      children: [
        Icon(LucideIcons.info, size: 18, color: muted),
        Expanded(
          child: Text(
            context.l10n.insightsCurrencyNote(code),
            style: CashundText.bodySm.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
