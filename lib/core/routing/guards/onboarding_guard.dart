import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:injectable/injectable.dart';

/// Sends the user through onboarding until they've finished it once.
@lazySingleton
class OnboardingGuard extends AutoRouteGuard {
  OnboardingGuard(this._preferences);

  final PreferencesRepository _preferences;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final result = await _preferences.get();
    final completed = result.match(
      (_) => false,
      (preferences) => preferences?.onboardingCompleted ?? false,
    );

    // The first screen is decided, so the native splash can go.
    FlutterNativeSplash.remove();

    if (completed) {
      resolver.next();
    } else {
      resolver.redirectUntil(OnboardingRoute(onCompleted: resolver.next));
    }
  }
}
