import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/locale/locale_defaults.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The onboarding flow: the welcome screen, then the setup steps, both
/// sharing one [OnboardingBloc]. Its child routes render in [AutoRouter].
@RoutePage()
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({this.onCompleted, super.key});

  /// Called once the choices are saved. Without it, the flow opens Home.
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final deviceLocale = View.of(context).platformDispatcher.locale;

    return BlocProvider(
      create: (_) => getIt<OnboardingBloc>()
        ..add(
          OnboardingEvent.started(
            currencyCode: LocaleDefaults.currencyCode(deviceLocale),
            weekStart: LocaleDefaults.weekStart(deviceLocale),
          ),
        ),
      child: BlocListener<OnboardingBloc, OnboardingState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case OnboardingStatus.completed:
              if (onCompleted case final onCompleted?) {
                onCompleted();
              } else {
                unawaited(context.router.replaceAll([const HomeRoute()]));
              }
            case OnboardingStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.onboardingSaveFailed)),
              );
            case OnboardingStatus.editing || OnboardingStatus.saving:
              break;
          }
        },
        child: const AutoRouter(),
      ),
    );
  }
}
