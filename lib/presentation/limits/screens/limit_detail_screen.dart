import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/extensions/limit_display.dart';
import 'package:cashund/presentation/common/widgets/overall_limit_card.dart';
import 'package:cashund/presentation/common/widgets/transaction_row.dart';
import 'package:cashund/presentation/common/widgets/trend_bars.dart';
import 'package:cashund/presentation/limits/bloc/limit_detail_bloc.dart';
import 'package:cashund/presentation/limits/limit_editor_sheet.dart';
import 'package:cashund/presentation/transaction_form/transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One limit: this period's progress, the last few periods against it, and
/// this period's transactions. Resolves to a [LimitDeleted] if the limit is
/// deleted from here, so the Limits page can offer undo.
@RoutePage()
class LimitDetailScreen extends StatelessWidget {
  const LimitDetailScreen({required this.limit, super.key});

  final SpendingLimit limit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<LimitDetailBloc>(param1: limit)
            ..add(const LimitDetailEvent.started()),
      child: const _LimitDetailView(),
    );
  }
}

class _LimitDetailView extends StatelessWidget {
  const _LimitDetailView();

  Future<void> _edit(BuildContext context) async {
    final progress = context.read<LimitDetailBloc>().state.progress;
    if (progress == null) return;
    final result = await showLimitEditor(context, editing: progress);
    if (result is LimitDeleted && context.mounted) {
      await context.router.maybePop(result);
    }
  }

  Future<void> _openTransaction(
    BuildContext context,
    TransactionWithCategory entry,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<LimitDetailBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showTransactionSheet(
      context,
      editing: entry.transaction,
    );
    if (result is! TransactionDeleted) return;
    final title = entry.transaction.title;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            l10n.transactionDeletedNamed(
              title == null || title.isEmpty
                  ? entry.category.name(l10n)
                  : title,
            ),
          ),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => bloc.add(
              LimitDetailEvent.transactionRestored(entry.transaction),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final state = context.watch<LimitDetailBloc>().state;
    final (progress, currency) = (state.progress, state.currency);
    final period = state.limit.period.name;

    return BlocListener<LimitDetailBloc, LimitDetailState>(
      listenWhen: (previous, current) =>
          !previous.isDeleted && current.isDeleted,
      // Deleted elsewhere: nothing left to show.
      listener: (context, state) => unawaited(context.router.maybePop()),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s3,
              CashundSpace.s6,
              CashundSpace.s8,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.back,
                    onPressed: () => context.router.maybePop(),
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.limitDetailEdit,
                    onPressed: progress == null ? null : () => _edit(context),
                    icon: const Icon(LucideIcons.pencil),
                  ),
                ],
              ),
              if (progress != null && currency != null) ...[
                const SizedBox(height: CashundSpace.s4),
                Text(
                  progress.label(l10n),
                  style: CashundText.pageTitle.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: CashundSpace.s1),
                Text(
                  l10n.limitDetailSubtitle(
                    period,
                    formatMoney(progress.amountMinor, currency),
                  ),
                  style: CashundText.bodyLg.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: CashundSpace.s6),
                OverallLimitCard(
                  progress: progress,
                  label: l10n.limitThisPeriod(
                    period,
                    formatDateRange(progress.range, locale),
                  ),
                  currency: currency,
                  today: state.today,
                ),
                const SizedBox(height: CashundSpace.s4),
                _HistoryCard(state: state, currency: currency),
                const SizedBox(height: CashundSpace.s6),
                _Transactions(
                  state: state,
                  currency: currency,
                  onTap: (entry) => _openTransaction(context, entry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The last few periods against the limit.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.state, required this.currency});

  final LimitDetailState state;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final history = state.history;
    final kept = state.kept;
    final period = state.limit.period;
    final category = state.progress?.category;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CashundRadius.lg),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CashundSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CashundSpace.s4,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.limitDetailHistory(period.name),
                    style: CashundText.title.copyWith(color: scheme.onSurface),
                  ),
                ),
                if (kept.of > 0)
                  Text(
                    l10n.limitDetailKept(kept.kept, kept.of),
                    style: CashundText.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            TrendBars(
              currency: currency,
              currentLabel: l10n.trendLegendCurrent(period.name),
              pastLabel: l10n.trendLegendUnder,
              currentColor: category == null
                  ? null
                  : context.categoryColor(category.color).mark,
              limitMinor: state.progress?.amountMinor,
              bars: [
                for (final (index, result) in history.indexed)
                  TrendBar(
                    label: period == LimitPeriod.week
                        ? DateFormat.MMMd(locale).format(result.range.start)
                        : DateFormat.MMM(locale).format(result.range.start),
                    valueMinor: result.spentMinor,
                    isCurrent: index == history.length - 1,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// This period's transactions under a day-header-style summary line.
class _Transactions extends StatelessWidget {
  const _Transactions({
    required this.state,
    required this.currency,
    required this.onTap,
  });

  final LimitDetailState state;
  final Currency currency;
  final ValueChanged<TransactionWithCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = state.transactions;
    final period = state.limit.period.name;
    final muted = CashundText.body.copyWith(color: scheme.onSurfaceVariant);
    final total = entries.fold(
      0,
      (sum, entry) => sum + entry.transaction.amountMinor,
    );

    if (entries.isEmpty) {
      return Text(l10n.limitDetailNoTransactions(period), style: muted);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s2,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s1),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.limitDetailTransactions(period, entries.length),
                  style: muted.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatMoney(-total, currency),
                style: CashundText.amountSm.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CashundRadius.lg),
            side: theme.brightness == Brightness.dark
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: CashundSpace.s4,
                    endIndent: CashundSpace.s4,
                    color: scheme.outlineVariant,
                  ),
                TransactionRow(entry: entry, onTap: () => onTap(entry)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
