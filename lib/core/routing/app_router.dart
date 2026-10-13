import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/routing/guards/onboarding_guard.dart';
import 'package:cashund/core/routing/page_transitions.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter(this._onboardingGuard);

  final OnboardingGuard _onboardingGuard;

  @override
  RouteType get defaultRouteType => slideOverRouteType;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: MainShellRoute.page,
      initial: true,
      guards: [_onboardingGuard],
      children: [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: ActivityRoute.page),
      ],
    ),
    // Pushed over the tabs, so there's no bottom bar.
    AutoRoute(
      page: SettingsRoute.page,
      children: [
        AutoRoute(page: SettingsHomeRoute.page, initial: true),
        AutoRoute(page: SettingsCurrencyRoute.page),
        AutoRoute(page: SettingsWeekStartRoute.page),
        AutoRoute(page: SettingsBuddyNameRoute.page),
      ],
    ),
    AutoRoute(
      page: OnboardingRoute.page,
      children: [
        AutoRoute(page: WelcomeRoute.page, initial: true),
        AutoRoute(page: OnboardingStepsRoute.page),
      ],
    ),
  ];
}
