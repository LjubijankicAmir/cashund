import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The buddy's mood. Pick it by meaning, not decoration.
enum BuddyExpression {
  /// Proud: money saved, a streak, a goal reached.
  happy,

  /// Idle, waiting for input. The default.
  listening,

  /// The on-device AI is reading a receipt or statement.
  thinking,

  /// A soft limit is at 80% or more, or passed.
  worried,

  /// Night, or nothing logged today.
  sleeping;

  String get _asset => 'assets/buddy/biscuit-$name.svg';
}

/// The buddy (head and paws), drawn for peeking over the top edge of a sheet.
///
/// Only one buddy per screen.
class Buddy extends StatelessWidget {
  const Buddy({
    this.expression = BuddyExpression.listening,
    this.width = 120,
    super.key,
  });

  /// The artwork's own size, used to keep its proportions.
  static const artSize = Size(170, 142);

  final BuddyExpression expression;
  final double width;

  double get height => width * artSize.height / artSize.width;

  @override
  Widget build(BuildContext context) {
    // Decorative: the screen's text already says who the buddy is.
    return ExcludeSemantics(
      child: SvgPicture.asset(expression._asset, width: width, height: height),
    );
  }
}
