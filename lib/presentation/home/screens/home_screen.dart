import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/add_transaction/add_transaction_sheet.dart';
import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy_message.dart';
import 'package:cashund/presentation/home/bloc/home_bloc.dart';
import 'package:cashund/presentation/home/widgets/home_band.dart';
import 'package:cashund/presentation/home/widgets/home_buddy_message.dart';
import 'package:cashund/presentation/home/widgets/home_empty_state.dart';
import 'package:cashund/presentation/home/widgets/spending_card.dart';
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
        buddy: (summary?.balanceMinor ?? 0) > 0
            ? BuddyExpression.happy
            : BuddyExpression.listening,
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
                // TODO(settings): open Settings.
                onSettingsPressed: () {},
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
                      child: state.buddyMessageDismissed
                          ? const SizedBox(
                              key: ValueKey('no-message'),
                              width: double.infinity,
                            )
                          : _Message(state: state, currency: currency),
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
          onAddExpense: () => showAddTransactionSheet(context),
          onAddIncome: () =>
              showAddTransactionSheet(context, type: TransactionType.income),
        ),
      );
    }

    // Only income so far: there's nothing to chart.
    if (state.slices.isEmpty) {
      return const SizedBox(
        key: ValueKey('nothing-spent'),
        width: double.infinity,
      );
    }

    return Padding(
      key: const ValueKey('spending'),
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s6,
        CashundSpace.s6,
        0,
      ),
      child: SpendingCard(
        period: state.period,
        slices: state.slices,
        totalMinor: summary.expenseMinor,
        currency: currency,
      ),
    );
  }
}
