import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:flutter/material.dart';

/// A 2pt bar that empties over [duration]: how long the reaction stays.
class ReactionTimerBar extends StatelessWidget {
  const ReactionTimerBar({required this.duration, super.key});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: duration,
        builder: (context, left, _) => LinearProgressIndicator(
          value: left,
          minHeight: 2,
          color: scheme.primary,
          backgroundColor: Theme.of(context).extension<CashundColors>()!.track,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
