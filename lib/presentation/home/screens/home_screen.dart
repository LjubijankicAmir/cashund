import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/add_transaction/add_transaction_sheet.dart';
import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy_message.dart';
import 'package:cashund/presentation/home/bloc/home_bloc.dart';
import 'package:cashund/presentation/home/widgets/home_band.dart';
import 'package:cashund/presentation/home/widgets/home_empty_state.dart';
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
    final (preferences, range) = (state.preferences, state.range);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BrandBandLayout(
        buddyWidth: _buddyWidth,
        band: preferences == null || range == null
            ? const SizedBox.shrink()
            : HomeBand(
                period: state.period,
                range: range,
                currency:
                    currencyByCode(preferences.currencyCode) ??
                    supportedCurrencies.first,
                onPeriodSelected: (period) => context.read<HomeBloc>().add(
                  HomeEvent.periodSelected(period),
                ),
                // TODO(settings): open Settings.
                onSettingsPressed: () {},
              ),
        sheet: preferences == null
            ? const SizedBox.shrink()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    // Opening and closing the message changes its height
                    // smoothly, so everything below glides instead of jumping.
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: state.buddyMessageDismissed
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(
                                CashundSpace.s6,
                                CashundSpace.s5,
                                CashundSpace.s6,
                                0,
                              ),
                              child: BuddyMessage(
                                buddyName: preferences.buddyName,
                                message: context.l10n.homeBuddyWelcome(
                                  preferences.buddyName,
                                ),
                                onDismiss: () => context.read<HomeBloc>().add(
                                  const HomeEvent.buddyMessageDismissed(),
                                ),
                              ),
                            ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CashundSpace.s6,
                        CashundSpace.s8,
                        CashundSpace.s6,
                        CashundSpace.s12,
                      ),
                      child: Center(
                        child: HomeEmptyState(
                          period: state.period,
                          onAddExpense: () => showAddTransactionSheet(context),
                          onAddIncome: () => showAddTransactionSheet(
                            context,
                            type: TransactionType.income,
                          ),
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
