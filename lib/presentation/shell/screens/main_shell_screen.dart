import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/presentation/activity/activity_filter_requests.dart';
import 'package:cashund/presentation/app_links/app_link.dart';
import 'package:cashund/presentation/app_links/app_link_requests.dart';
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
///
/// And where links from home-screen widgets and app shortcuts open.
@RoutePage()
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  /// Home has the buddy peeking already, so it shows reactions itself.
  static const _homeIndex = 0;
  static const _activityIndex = 1;

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

          return _AppLinkListener(
            onLink: (link) => _open(context, tabs, link),
            child: _ActivityRequestListener(
              onRequest: () => tabs.setActiveIndex(_activityIndex),
              child: Scaffold(
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
                                onDismiss: context
                                    .read<ReactionCubit>()
                                    .dismiss,
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
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _open(
    BuildContext context,
    TabsRouter tabs,
    AppLink link,
  ) async {
    // Whatever is open over the tabs makes way, sheets included.
    final router = context.router.root
      ..popUntilRouteWithName(MainShellRoute.name);

    switch (link) {
      case AddLink(:final type):
        await logTransaction(context, type: type);
      case HomeLink():
        tabs.setActiveIndex(_homeIndex);
      case ActivityLink():
        tabs.setActiveIndex(_activityIndex);
      case LimitsLink(:final period):
        await router.push(LimitsRoute(period: period));
      case LimitDetailLink(:final id):
        final found = await getIt<LimitRepository>().watch(id).first;
        final limit = found.getOrElse((_) => null);
        if (!context.mounted) return;
        // A widget can still show a limit that has been deleted since.
        await router.push(
          limit == null ? LimitsRoute() : LimitDetailRoute(limit: limit),
        );
    }
  }
}

/// Opens each link from a home-screen widget or an app shortcut, including
/// one that came in before the shell was up.
class _AppLinkListener extends StatefulWidget {
  const _AppLinkListener({required this.onLink, required this.child});

  final ValueChanged<AppLink> onLink;
  final Widget child;

  @override
  State<_AppLinkListener> createState() => _AppLinkListenerState();
}

class _AppLinkListenerState extends State<_AppLinkListener> {
  final AppLinkRequests _links = getIt();
  late final StreamSubscription<void> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _links.requests.listen((_) => _openPending());
    // After the first frame, so the shell can push over itself.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  void _openPending() {
    final link = _links.take();
    if (link != null && mounted) widget.onLink(link);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Switches to Activity when something asks it to show a filtered list.
class _ActivityRequestListener extends StatefulWidget {
  const _ActivityRequestListener({
    required this.onRequest,
    required this.child,
  });

  final VoidCallback onRequest;
  final Widget child;

  @override
  State<_ActivityRequestListener> createState() =>
      _ActivityRequestListenerState();
}

class _ActivityRequestListenerState extends State<_ActivityRequestListener> {
  late final StreamSubscription<void> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<ActivityFilterRequests>().requests.listen(
      (_) => widget.onRequest(),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
