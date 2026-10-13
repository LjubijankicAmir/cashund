import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';

/// The buddy's name: a labelled field with a character counter, a [helper]
/// line and name ideas to pick with one tap.
class BuddyNameField extends StatelessWidget {
  const BuddyNameField({
    required this.controller,
    required this.helper,
    this.onChanged,
    super.key,
  });

  /// Holds the name; picking an idea writes into it.
  final TextEditingController controller;
  final String helper;
  final ValueChanged<String>? onChanged;

  /// Name suggestions. Proper names, so they aren't translated.
  static const List<String> nameIdeas = [
    UserPreferences.defaultBuddyName,
    'Pretzel',
    'Noodle',
    'Frank',
    'Waffles',
  ];

  void _setName(String name) {
    controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    onChanged?.call(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.buddyNameLabel, style: muted),
        const SizedBox(height: CashundSpace.s2),
        TextField(
          controller: controller,
          maxLength: UserPreferences.buddyNameMaxLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: CashundText.bodyLg.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: CashundSpace.s4),
              child: ValueListenableBuilder(
                valueListenable: controller,
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
          helper,
          style: CashundText.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s6),
        Text(l10n.buddyNameIdeas, style: muted),
        const SizedBox(height: CashundSpace.s3),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => Wrap(
            spacing: CashundSpace.s2 + 2,
            runSpacing: CashundSpace.s2 + 2,
            children: [
              for (final idea in nameIdeas)
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
