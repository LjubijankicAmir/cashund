import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// A labelled form field: the label above, and on the right "Optional" when
/// the field can stay empty, or a [trailing] note such as the picked value.
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    required this.label,
    required this.child,
    this.optional = false,
    this.trailing,
    super.key,
  });

  final String label;
  final Widget child;
  final bool optional;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = CashundText.labelSm.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s2,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: style)),
            if (optional ? context.l10n.optional : trailing case final note?)
              Text(note, style: style.copyWith(fontWeight: FontWeight.w400)),
          ],
        ),
        child,
      ],
    );
  }
}
