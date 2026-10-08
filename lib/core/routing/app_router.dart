import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(
      page: OnboardingRoute.page,
      children: [
        AutoRoute(page: WelcomeRoute.page, initial: true),
        // Slides in from the side on both platforms (Android's default is a
        // zoom), with the edge swipe to go back.
        CupertinoRoute<void>(page: OnboardingStepsRoute.page),
      ],
    ),
  ];
}
