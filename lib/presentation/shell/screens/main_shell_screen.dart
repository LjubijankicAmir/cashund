import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/presentation/add_transaction/add_transaction_sheet.dart';
import 'package:cashund/presentation/shell/widgets/cashund_nav_bar.dart';
import 'package:flutter/material.dart';

/// The app after onboarding: the Home and Activity tabs under the bottom bar.
/// Both tabs stay alive, so switching keeps their scroll position and state.
@RoutePage()
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [HomeRoute(), ActivityRoute()],
      transitionBuilder: (context, child, animation) =>
          FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final tabs = AutoTabsRouter.of(context);

        return Scaffold(
          body: child,
          bottomNavigationBar: CashundNavBar(
            currentIndex: tabs.activeIndex,
            onTabSelected: tabs.setActiveIndex,
            onAddPressed: () => showAddTransactionSheet(context),
          ),
        );
      },
    );
  }
}
