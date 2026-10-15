import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/reaction/bloc/reaction_cubit.dart';
import 'package:cashund/presentation/reaction/transaction_actions.dart';
import 'package:cashund/presentation/reaction/widgets/reaction_card.dart';
import 'package:cashund/presentation/shell/widgets/cashund_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app after onboarding: the Home and Activity tabs under the bottom bar.
/// Both tabs stay alive, so switching keeps their scroll position and state.
///
/// Also where the buddy reacts to something just logged: in the speech
/// bubble on Home, or in a card floating above the bar on other tabs.
@RoutePage()
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  /// Home has the buddy peeking already, so it shows reactions itself.
  static const _homeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReactionCubit>(),
      child: AutoTabsRouter(
        routes: const [HomeRoute(), ActivityRoute()],
        transitionBuilder: (context, child, animation) =>
            FadeTransition(opacity: animation, child: child),
        builder: (context, child) {
          final tabs = AutoTabsRouter.of(context);
          final reaction = context.watch<ReactionCubit>().state;
          final floating = tabs.activeIndex == _homeIndex ? null : reaction;

          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  left: CashundSpace.s4,
                  right: CashundSpace.s4,
                  bottom: CashundSpace.s4,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: floating == null
                        ? const SizedBox.shrink()
                        : ReactionCard(
                            key: ValueKey(floating.id),
                            reaction: floating,
                            visibleFor: context
                                .read<ReactionCubit>()
                                .visibleFor,
                            onDismiss: context.read<ReactionCubit>().dismiss,
                          ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: CashundNavBar(
              currentIndex: tabs.activeIndex,
              onTabSelected: tabs.setActiveIndex,
              onAddPressed: () => logTransaction(context),
            ),
          );
        },
      ),
    );
  }
}
