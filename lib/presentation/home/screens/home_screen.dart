import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy_message.dart';
import 'package:cashund/presentation/home/bloc/home_bloc.dart';
import 'package:cashund/presentation/home/widgets/home_band.dart';
import 'package:cashund/presentation/home/widgets/home_buddy_message.dart';
import 'package:cashund/presentation/home/widgets/home_empty_state.dart';
import 'package:cashund/presentation/home/widgets/limits_card.dart';
import 'package:cashund/presentation/home/widgets/spending_card.dart';
import 'package:cashund/presentation/limits/limit_editor_sheet.dart';
import 'package:cashund/presentation/reaction/bloc/reaction_cubit.dart';
import 'package:cashund/presentation/reaction/transaction_actions.dart';
import 'package:cashund/presentation/reaction/widgets/reaction_card.dart';
import 'package:cashund/presentation/reaction/widgets/reaction_timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeEvent.started()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  static const _buddyWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeBloc>().state;
    final reaction = context.watch<ReactionCubit>().state;
    final (preferences, range, summary) = (
      state.preferences,
      state.range,
      state.summary,
    );
    final currency =
        currencyByCode(preferences?.currencyCode ?? '') ??
        supportedCurrencies.first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BrandBandLayout(
        buddyWidth: _buddyWidth,
        buddy:
            reaction?.line.expression ??
            ((summary?.balanceMinor ?? 0) > 0
                ? BuddyExpression.happy
                : BuddyExpression.listening),
        band: preferences == null || range == null
            ? const SizedBox.shrink()
            : HomeBand(
                period: state.period,
                range: range,
                currency: currency,
                summary: summary,
                onPeriodSelected: (period) => context.read<HomeBloc>().add(
                  HomeEvent.periodSelected(period),
                ),
                // On the root router, so Settings covers the bottom bar.
                onSettingsPressed: () =>
                    context.router.root.push(const SettingsRoute()),
              ),
        sheet:
            preferences == null ||
                summary == null ||
                state.hasTransactions == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: CashundSpace.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AnimatedSlot(
                      child: switch ((reaction, state.buddyMessageDismissed)) {
                        (final reaction?, _) => _ReactionMessage(
                          key: ValueKey(('reaction', reaction.id)),
                          reaction: reaction,
                        ),
                        (null, true) => const SizedBox(
                          key: ValueKey('no-message'),
                          width: double.infinity,
                        ),
                        (null, false) => _Message(
                          state: state,
                          currency: currency,
                        ),
                      },
                    ),
                    _AnimatedSlot(
                      child: _Content(
                        state: state,
                        summary: summary,
                        currency: currency,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Swaps its child by fading it while the height adjusts, so whatever sits
/// below glides instead of jumping. Children need distinct keys.
class _AnimatedSlot extends StatelessWidget {
  const _AnimatedSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.state, required this.currency});

  final HomeState state;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final preferences = state.preferences!;
    final message = homeBuddyMessage(
      context.l10n,
      buddyName: preferences.buddyName,
      period: state.period,
      currency: currency,
      hasTransactions: state.hasTransactions ?? false,
      summary: state.summary ?? const PeriodSummary(),
      slices: state.slices,
    );

    return Padding(
      // A new message gets a new key, so it cross-fades in.
      key: ValueKey(message),
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s5,
        CashundSpace.s6,
        0,
      ),
      child: BuddyMessage(
        buddyName: preferences.buddyName,
        message: message,
        onDismiss: () => context.read<HomeBloc>().add(
          const HomeEvent.buddyMessageDismissed(),
        ),
      ),
    );
  }
}

/// The buddy reacting to something just logged, in place of the message.
class _ReactionMessage extends StatelessWidget {
  const _ReactionMessage({required this.reaction, super.key});

  final Reaction reaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s5,
        CashundSpace.s6,
        0,
      ),
      child: BuddyMessage(
        buddyName: reaction.buddyName,
        header: ReactionMeta(reaction: reaction),
        message: reaction.line.text(context.l10n),
        footer: ReactionTimerBar(
          duration: context.read<ReactionCubit>().visibleFor,
        ),
        onDismiss: context.read<ReactionCubit>().dismiss,
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.summary,
    required this.currency,
  });

  final HomeState state;
  final PeriodSummary summary;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return Padding(
        key: ValueKey(('empty', state.period)),
        padding: const EdgeInsets.fromLTRB(
          CashundSpace.s6,
          72,
          CashundSpace.s6,
          0,
        ),
        child: HomeEmptyState(
          period: state.period,
          onAddExpense: () => logTransaction(context),
          onAddIncome: () =>
              logTransaction(context, type: TransactionType.income),
        ),
      );
    }

    final preferences = state.preferences!;
    final limits = state.limits ?? const [];
    final Widget? limitsSection = switch (limits) {
      [_, ...] => LimitsCard(
        limits: limits,
        currency: currency,
        today: state.today,
        onSeeAll: () => _openLimits(context),
      ),
      // Loaded and empty: a nudge, until "Not now".
      [] when state.limits != null && !preferences.limitsPromptDismissed =>
        LimitsPrompt(
          buddyName: preferences.buddyName,
          onSetLimit: () => _setLimit(context),
          onNotNow: () => context.read<HomeBloc>().add(
            const HomeEvent.limitsPromptDismissed(),
          ),
        ),
      _ => null,
    };

    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s6,
        CashundSpace.s6,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CashundSpace.s8,
        children: [
          ?limitsSection,
          // Only income so far: there's nothing to chart.
          if (state.slices.isNotEmpty)
            SpendingCard(
              period: state.period,
              slices: state.slices,
              totalMinor: summary.expenseMinor,
              currency: currency,
            ),
        ],
      ),
    );
  }

  /// Limits run per week or month; Home's day view opens the week's.
  void _openLimits(BuildContext context) => unawaited(
    context.router.root.push(LimitsRoute(period: state.limitPeriod)),
  );

  void _setLimit(BuildContext context) =>
      unawaited(showLimitEditor(context, period: state.limitPeriod));
}
