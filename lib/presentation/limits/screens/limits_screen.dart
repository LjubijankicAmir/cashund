import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/limit_row.dart';
import 'package:cashund/presentation/common/widgets/overall_limit_card.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:cashund/presentation/limits/bloc/limits_bloc.dart';
import 'package:cashund/presentation/limits/limit_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every limit for one period, the overall one first, then by category,
/// most used first.
@RoutePage()
class LimitsScreen extends StatelessWidget {
  const LimitsScreen({this.period = LimitPeriod.week, super.key});

  /// The period it opens on, e.g. the one selected on Home.
  final LimitPeriod period;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LimitsBloc>()..add(LimitsEvent.started(period)),
      child: BlocListener<LimitsBloc, LimitsState>(
        listenWhen: (previous, current) =>
            !previous.restoreFailed && current.restoreFailed,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.limitsSaveFailed))),
        child: const _LimitsView(),
      ),
    );
  }
}

class _LimitsView extends StatelessWidget {
  const _LimitsView();

  Future<void> _openEditor(
    BuildContext context, {
    LimitProgress? editing,
  }) async {
    final period = context.read<LimitsBloc>().state.period;
    final result = await showLimitEditor(
      context,
      period: period,
      editing: editing,
    );
    if (context.mounted) _offerUndo(context, result);
  }

  Future<void> _openDetail(BuildContext context, LimitProgress progress) async {
    final result = await context.router.push<LimitEditorResult>(
      LimitDetailRoute(limit: progress.limit),
    );
    if (context.mounted) _offerUndo(context, result);
  }

  /// After a delete, "Deleted the Eating Out limit" with Undo.
  void _offerUndo(BuildContext context, LimitEditorResult? result) {
    if (result is! LimitDeleted) return;
    final l10n = context.l10n;
    final bloc = context.read<LimitsBloc>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(l10n.limitsDeleted(result.name)),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => bloc.add(LimitsEvent.restored(result.snapshot)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<LimitsBloc>();
    final state = context.watch<LimitsBloc>().state;
    final (currency, range, overall) = (
      state.currency,
      state.range,
      state.overall,
    );
    final period = state.period.name;
    final hasAny = (state.limitCount ?? 0) > 0;
    final loaded = state.progress != null && currency != null && range != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CashundSpace.s6,
                  CashundSpace.s3,
                  CashundSpace.s6,
                  CashundSpace.s6,
                ),
                children: [
                  PushedPageHeader(
                    title: l10n.limitsTitle,
                    subtitle: l10n.limitsSubtitle,
                  ),
                  const SizedBox(height: CashundSpace.s5),
                  if (state.limitCount == 0)
                    _EmptyState(
                      buddyName: state.preferences?.buddyName ?? '',
                      onSetLimit: () => _openEditor(context),
                    )
                  else ...[
                    SegmentedPills(
                      stretch: true,
                      segments: [
                        (LimitPeriod.week, l10n.limitPeriodWeek),
                        (LimitPeriod.month, l10n.limitPeriodMonth),
                      ],
                      selected: state.period,
                      onChanged: (period) =>
                          bloc.add(LimitsEvent.periodSelected(period)),
                    ),
                    if (loaded) ...[
                      const SizedBox(height: CashundSpace.s5),
                      if (overall != null)
                        OverallLimitCard(
                          progress: overall,
                          label:
                              '${l10n.limitAllSpending} · ${l10n.limitThisPeriod(period, formatDateRange(range, locale))}',
                          currency: currency,
                          today: state.today,
                          onTap: () => _openDetail(context, overall),
                        )
                      else
                        _AddOverallSlot(
                          period: period,
                          onTap: () => _openEditor(context),
                        ),
                      const SizedBox(height: CashundSpace.s6),
                      if (state.byCategory.isEmpty)
                        Text(
                          l10n.limitsEmptyPeriod(period),
                          style: CashundText.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: CashundSpace.s1,
                            bottom: CashundSpace.s3,
                          ),
                          child: Text(
                            l10n.limitsByCategory,
                            style: CashundText.labelSm.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        _LimitList(
                          limits: state.byCategory,
                          row: (progress) => LimitRow(
                            progress: progress,
                            currency: currency,
                            today: state.today,
                            onTap: () => _openDetail(context, progress),
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            if (hasAny)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CashundSpace.s6,
                      CashundSpace.s4,
                      CashundSpace.s6,
                      CashundSpace.s4,
                    ),
                    child: FilledButton.tonalIcon(
                      onPressed: () => unawaited(_openEditor(context)),
                      icon: const Icon(LucideIcons.plus),
                      label: Text(l10n.limitsNew),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The category limits in one card, hairlines between them.
class _LimitList extends StatelessWidget {
  const _LimitList({required this.limits, required this.row});

  final List<LimitProgress> limits;
  final Widget Function(LimitProgress) row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
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
          for (final (index, progress) in limits.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: CashundSpace.s4,
                endIndent: CashundSpace.s4,
                color: scheme.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s4,
                CashundSpace.s4,
                CashundSpace.s3,
                CashundSpace.s4,
              ),
              child: row(progress),
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the overall card goes when there's no overall limit yet.
class _AddOverallSlot extends StatelessWidget {
  const _AddOverallSlot({required this.period, required this.onTap});

  final String period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CashundRadius.lg),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CashundSpace.s4),
          child: Row(
            spacing: CashundSpace.s3,
            children: [
              Icon(LucideIcons.plus, color: scheme.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.limitsAddOverall,
                      style: CashundText.label.copyWith(color: scheme.primary),
                    ),
                    Text(
                      l10n.limitsAddOverallHint(period),
                      style: CashundText.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No limits at all: the buddy and one way in.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.buddyName, required this.onSetLimit});

  final String buddyName;
  final VoidCallback onSetLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: CashundSpace.s8),
      child: Column(
        spacing: CashundSpace.s3,
        children: [
          const Buddy(width: 150),
          const SizedBox(height: CashundSpace.s2),
          Text(
            l10n.limitsEmptyTitle,
            style: CashundText.title.copyWith(color: scheme.onSurface),
          ),
          Text(
            l10n.limitsEmptyBody(buddyName),
            textAlign: TextAlign.center,
            style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: CashundSpace.s3),
          PrimaryButton(label: l10n.limitsSetLimit, onPressed: onSetLimit),
        ],
      ),
    );
  }
}
