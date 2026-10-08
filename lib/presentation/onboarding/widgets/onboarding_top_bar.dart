import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/presentation/common/widgets/step_dots.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Back button, step dots and "Skip": the parts of the steps that never move.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({this.onBrand = false, super.key});

  /// Use the white version on the brand band.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OnboardingBloc>();
    final step = context.select<OnboardingBloc, int>((bloc) => bloc.state.step);
    final onBrandColor = Theme.of(context).extension<CashundColors>()!.onBrand;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: context.l10n.back,
              // Same as the system back gesture: the steps screen decides
              // whether that means the previous step or leaving the steps.
              onPressed: () => Navigator.of(context).maybePop(),
              style: onBrand
                  ? IconButton.styleFrom(
                      backgroundColor: onBrandColor.withValues(alpha: 0.16),
                      foregroundColor: onBrandColor,
                    )
                  : null,
              icon: const Icon(LucideIcons.chevronLeft),
            ),
          ),
          StepDots(
            count: OnboardingState.stepCount,
            current: step,
            onBrand: onBrand,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => bloc.add(const OnboardingEvent.skipPressed()),
              style: onBrand
                  ? TextButton.styleFrom(foregroundColor: onBrandColor)
                  : null,
              child: Text(context.l10n.skip),
            ),
          ),
        ],
      ),
    );
  }
}
