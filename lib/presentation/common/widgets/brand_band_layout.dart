import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/animated_buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/material.dart';

/// The brand's signature layout: a cobalt band on top, a rounded sheet below
/// it, and the buddy peeking over the seam on the right.
class BrandBandLayout extends StatelessWidget {
  const BrandBandLayout({
    required this.band,
    required this.sheet,
    this.buddy = BuddyExpression.listening,
    this.buddyWidth = 120,
    this.sheetPosition,
    this.buddyController,
    super.key,
  });

  /// Content on the band. Already below the status bar.
  final Widget band;

  /// Content on the sheet.
  final Widget sheet;

  final BuddyExpression buddy;
  final double buddyWidth;

  /// Moves the sheet (and the buddy sitting on it), e.g. to slide it in.
  /// Offsets are fractions of the sheet's size.
  final Animation<Offset>? sheetPosition;

  /// Lets the screen make the buddy react, see [BuddyController.cheer].
  final BuddyController? buddyController;

  /// How far the buddy's paws hang over the sheet's top edge.
  static const _pawOverlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CashundColors>()!;
    final buddyHeight = Buddy(width: buddyWidth).height;

    final sheetWithBuddy = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(CashundRadius.xl),
              ),
              boxShadow: CashundShadow.sheet(theme.brightness),
            ),
            child: sheet,
          ),
        ),
        Positioned(
          right: CashundSpace.s6,
          top: _pawOverlap - buddyHeight,
          child: AnimatedBuddy(
            controller: buddyController,
            expression: buddy,
            width: buddyWidth,
          ),
        ),
      ],
    );

    return ColoredBox(
      color: colors.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(bottom: false, child: band),
          Expanded(
            child: switch (sheetPosition) {
              final position? => SlideTransition(
                position: position,
                child: sheetWithBuddy,
              ),
              null => sheetWithBuddy,
            },
          ),
        ],
      ),
    );
  }
}
