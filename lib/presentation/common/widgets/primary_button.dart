import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// The screen's main action: a full-width pill with the cobalt glow.
///
/// Use at most one per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// `null` disables the button and removes the glow.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: enabled
            ? CashundShadow.primary(Theme.of(context).brightness)
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
