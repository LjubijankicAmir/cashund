import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/widgets/week_start_options.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 3: the day the user's week starts on.
class WeekStartStep extends StatelessWidget {
  const WeekStartStep({this.today, super.key});

  /// Overrides today's date in the week preview, for tests.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekStart = context.select<OnboardingBloc, WeekStart>(
      (bloc) => bloc.state.weekStart,
    );

    return ListView(
      padding: stepBodyPadding,
      children: [
        Text(
          context.l10n.onboardingWeekSubtitle,
          style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s5),
        WeekStartOptions(
          selected: weekStart,
          today: today,
          onSelected: (option) => context.read<OnboardingBloc>().add(
            OnboardingEvent.weekStartSelected(option),
          ),
        ),
      ],
    );
  }
}
