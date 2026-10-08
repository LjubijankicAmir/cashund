import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// Progress through a short flow: the current step is a wider pill.
class StepDots extends StatelessWidget {
  const StepDots({
    required this.count,
    required this.current,
    this.onBrand = false,
    super.key,
  });

  final int count;

  /// Zero-based index of the current step.
  final int current;

  /// Use the white version on the brand band.
  final bool onBrand;

  static const _dotSize = 8.0;
  static const _activeWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onBrandColor = Theme.of(context).extension<CashundColors>()!.onBrand;
    final active = onBrand ? onBrandColor : scheme.primary;
    final inactive = onBrand
        ? onBrandColor.withValues(alpha: 0.5)
        : scheme.outline.withValues(alpha: 0.45);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CashundSpace.s1 + 2,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: i == current ? _activeWidth : _dotSize,
            height: _dotSize,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: i == current ? active : inactive,
            ),
          ),
      ],
    );
  }
}
