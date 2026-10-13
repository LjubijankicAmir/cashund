import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/material.dart';

/// A card with the buddy peeking over it, for when the list is empty.
class ActivityNoResults extends StatelessWidget {
  const ActivityNoResults({
    required this.title,
    required this.message,
    required this.actions,
    this.expression = BuddyExpression.thinking,
    super.key,
  });

  final String title;
  final String message;
  final List<Widget> actions;
  final BuddyExpression expression;

  static const _buddyWidth = 104.0;

  /// How far the buddy's paws hang over the card's top edge.
  static const _pawOverlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buddyHeight = const Buddy(width: _buddyWidth).height;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: buddyHeight - _pawOverlap),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s8,
              CashundSpace.s6,
              CashundSpace.s6,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(CashundRadius.lg),
            ),
            child: Column(
              spacing: CashundSpace.s3,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CashundText.title.copyWith(
                    fontSize: 20,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: CashundText.bodyLg.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: CashundSpace.s1),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: CashundSpace.s3,
                  runSpacing: CashundSpace.s2,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
        Buddy(expression: expression, width: _buddyWidth),
      ],
    );
  }
}
