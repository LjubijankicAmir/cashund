import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// A small pill for one-tap picks under a field, e.g. a recent category.
class QuickChip extends StatelessWidget {
  const QuickChip({
    required this.label,
    required this.onTap,
    this.leading,
    this.selected = false,
    super.key,
  });

  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CashundSpace.s3,
              vertical: CashundSpace.s2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CashundSpace.s2,
              children: [
                ?leading,
                Text(
                  label,
                  style: CashundText.body.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
