import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/activity/activity_filter_requests.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/limit_row.dart';
import 'package:cashund/presentation/common/widgets/surface_card.dart';
import 'package:cashund/presentation/common/widgets/trend_bars.dart';
import 'package:cashund/presentation/insights/bloc/category_insights_bloc.dart';
import 'package:cashund/presentation/insights/insights_labels.dart';
import 'package:cashund/presentation/insights/widgets/trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One category in one period of Insights: what it came to, how it's
/// trending, its limits, and a way to its transactions.
@RoutePage()
class CategoryInsightsScreen extends StatelessWidget {
  const CategoryInsightsScreen({
    required this.category,
    required this.period,
    required this.range,
    super.key,
  });

  final Category category;
  final InsightsPeriod period;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryInsightsBloc>(
        param1: (category: category, period: period, range: range),
      )..add(const CategoryInsightsEvent.started()),
      child: const _CategoryInsightsView(),
    );
  }
}

class _CategoryInsightsView extends StatelessWidget {
  const _CategoryInsightsView();

  /// Back to the tabs, on Activity with this category and period applied.
  void _seeInActivity(BuildContext context, CategoryInsightsState state) {
    getIt<ActivityFilterRequests>().open(
      TransactionFilter(
        type: TransactionType.expense,
        categoryIds: {state.category.id},
        range: state.range,
      ),
    );
    context.router.root.popUntilRoot();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final state = context.watch<CategoryInsightsBloc>().state;
    final (category, period, range, currency) = (
      state.category,
      state.period,
      state.range,
      state.currency,
    );
    final label = period.shortLabel(l10n, locale, range);
    final mark = context.categoryColor(category.color).mark;

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
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: l10n.back,
                onPressed: () => context.router.maybePop(),
                icon: const Icon(LucideIcons.chevronLeft),
              ),
            ),
            const SizedBox(height: CashundSpace.s4),
            Text(
              category.label(l10n),
              style: CashundText.pageTitle.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: CashundSpace.s1),
            Text(
              period.title(l10n, locale, range),
              style: CashundText.bodyLg.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (currency != null) ...[
              const SizedBox(height: CashundSpace.s6),
              _TotalCard(state: state, label: label),
              const SizedBox(height: CashundSpace.s4),
              TrendCard(
                title: switch (period) {
                  InsightsPeriod.week => l10n.insightsTrendWeeks,
                  InsightsPeriod.month => l10n.insightsTrendMonths,
                  InsightsPeriod.year => l10n.insightsTrendYear,
                },
                averageMinor: state.averageMinor,
                currency: currency,
                currentColor: mark,
                currentLabel: l10n.insightsLegendCategory(
                  category.label(l10n),
                  label,
                ),
                pastLabel: l10n.insightsLegendEarlier(
                  period == InsightsPeriod.week ? 'week' : 'month',
                ),
                bars: [
                  for (final point in state.trend)
                    TrendBar(
                      label: period.barLabel(locale, point.range),
                      valueMinor: point.totalMinor,
                      isCurrent:
                          point.isCurrent ||
                          period == InsightsPeriod.year &&
                              point.range.contains(state.today),
                      isFuture: point.isFuture,
                    ),
                ],
              ),
              for (final limit in state.limits) ...[
                const SizedBox(height: CashundSpace.s4),
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(
                    CashundSpace.s4,
                    CashundSpace.s4,
                    CashundSpace.s3,
                    CashundSpace.s4,
                  ),
                  child: LimitRow(
                    progress: limit,
                    currency: currency,
                    today: state.today,
                    onTap: () => unawaited(
                      context.router.push(LimitDetailRoute(limit: limit.limit)),
                    ),
                  ),
                ),
              ],
              if (state.transactionCount > 0) ...[
                const SizedBox(height: CashundSpace.s5),
                FilledButton.tonalIcon(
                  onPressed: () => _seeInActivity(context, state),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(LucideIcons.chevronRight),
                  label: Text(
                    l10n.insightsSeeInActivity(state.transactionCount),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// "$512.40 spent", its share of spending, and how it compares.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.state, required this.label});

  final CategoryInsightsState state;

  /// The period's short name, e.g. "October".
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final currency = state.currency!;
    final comparison = state.comparison;
    final muted = CashundText.body.copyWith(color: scheme.onSurfaceVariant);

    final compared = switch (comparison) {
      (:final current, :final previous) => () {
        final diff = formatMoney((current - previous).abs(), currency);
        final name = state.period.previousLabel(
          l10n,
          locale,
          state.previousRange,
        );
        return current > previous
            ? l10n.insightsCategoryMore(diff, name)
            : l10n.insightsCategoryLess(diff, name);
      }(),
      null => null,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CashundSpace.s1,
        children: [
          Text(
            l10n.insightsCategoryShare(label, state.sharePercent),
            style: CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatMoney(state.spentMinor, currency),
                  style: CashundText.pageTitle.copyWith(
                    color: scheme.onSurface,
                    fontFeatures: CashundText.amount.fontFeatures,
                  ),
                ),
                TextSpan(
                  text: ' ${l10n.insightsSpentLabel}',
                  style: CashundText.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            [
              ?compared,
              l10n.insightsTransactionCount(state.transactionCount),
            ].join(' · '),
            style: muted,
          ),
        ],
      ),
    );
  }
}
