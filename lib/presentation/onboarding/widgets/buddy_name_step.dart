import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/buddy_name_field.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 2: what the buddy is called.
class BuddyNameStep extends StatefulWidget {
  const BuddyNameStep({super.key});

  @override
  State<BuddyNameStep> createState() => _BuddyNameStepState();
}

class _BuddyNameStepState extends State<BuddyNameStep> {
  late final _controller = TextEditingController(
    text: context.read<OnboardingBloc>().state.buddyName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: stepBodyPadding,
      children: [
        Text(
          l10n.onboardingBuddySubtitle,
          style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s5),
        BuddyNameField(
          controller: _controller,
          helper: l10n.onboardingBuddyNameHelper,
          onChanged: (name) => context.read<OnboardingBloc>().add(
            OnboardingEvent.buddyNameChanged(name),
          ),
        ),
      ],
    );
  }
}
