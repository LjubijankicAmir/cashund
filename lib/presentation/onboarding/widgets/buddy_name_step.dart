import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 2: what the buddy is called.
class BuddyNameStep extends StatefulWidget {
  const BuddyNameStep({super.key});

  /// Name suggestions. Proper names, so they aren't translated.
  static const List<String> nameIdeas = [
    UserPreferences.defaultBuddyName,
    'Pretzel',
    'Noodle',
    'Frank',
    'Waffles',
  ];

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

  void _setName(String name) {
    _controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    context.read<OnboardingBloc>().add(OnboardingEvent.buddyNameChanged(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant);

    return ListView(
      padding: stepBodyPadding,
      children: [
        Text(
          l10n.onboardingBuddySubtitle,
          style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s5),
        Text(l10n.onboardingBuddyNameLabel, style: muted),
        const SizedBox(height: CashundSpace.s2),
        TextField(
          controller: _controller,
          maxLength: UserPreferences.buddyNameMaxLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: CashundText.bodyLg.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (name) => context.read<OnboardingBloc>().add(
            OnboardingEvent.buddyNameChanged(name),
          ),
          decoration: InputDecoration(
            counterText: '',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: CashundSpace.s4),
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, _) => Text(
                  '${value.text.characters.length}/${UserPreferences.buddyNameMaxLength}',
                  style: CashundText.bodySm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(height: CashundSpace.s2),
        Text(
          l10n.onboardingBuddyNameHelper,
          style: CashundText.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s6),
        Text(l10n.onboardingBuddyNameIdeas, style: muted),
        const SizedBox(height: CashundSpace.s3),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => Wrap(
            spacing: CashundSpace.s2 + 2,
            runSpacing: CashundSpace.s2 + 2,
            children: [
              for (final idea in BuddyNameStep.nameIdeas)
                ChoiceChip(
                  label: Text(idea),
                  selected: value.text.trim() == idea,
                  showCheckmark: false,
                  side: value.text.trim() == idea
                      ? BorderSide(color: scheme.primary, width: 1.5)
                      : null,
                  labelStyle: CashundText.label.copyWith(
                    color: value.text.trim() == idea
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                  onSelected: (_) => _setName(idea),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
