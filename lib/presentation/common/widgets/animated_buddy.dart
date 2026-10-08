import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:flutter/widgets.dart';

/// Triggers reactions on an [AnimatedBuddy], e.g. when the user does
/// something worth cheering for.
class BuddyController extends ChangeNotifier {
  /// The buddy turns happy, hops twice, then goes back to its expression.
  void cheer() => notifyListeners();
}

/// A [Buddy] that can react: on [BuddyController.cheer] it turns happy and
/// hops twice before settling back into [expression].
class AnimatedBuddy extends StatefulWidget {
  const AnimatedBuddy({
    this.controller,
    this.expression = BuddyExpression.listening,
    this.width = 120,
    super.key,
  });

  final BuddyController? controller;

  /// The resting expression, shown whenever the buddy isn't reacting.
  final BuddyExpression expression;

  final double width;

  @override
  State<AnimatedBuddy> createState() => _AnimatedBuddyState();
}

class _AnimatedBuddyState extends State<AnimatedBuddy>
    with SingleTickerProviderStateMixin {
  static const _hopHeight = 5.0;

  late final _cheer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Up and down twice: decelerating on the way up, accelerating on the way
  // down, like a little jump.
  late final Animation<double> _lift = TweenSequence([
    for (var hop = 0; hop < 2; hop++) ...[
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -_hopHeight,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -_hopHeight,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ],
  ]).animate(_cheer);

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onCheer);
  }

  @override
  void didUpdateWidget(AnimatedBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onCheer);
      widget.controller?.addListener(_onCheer);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onCheer);
    _cheer.dispose();
    super.dispose();
  }

  void _onCheer() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _cheer.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cheer,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _lift.value),
        child: Buddy(
          expression: _cheer.isAnimating
              ? BuddyExpression.happy
              : widget.expression,
          width: widget.width,
        ),
      ),
    );
  }
}
