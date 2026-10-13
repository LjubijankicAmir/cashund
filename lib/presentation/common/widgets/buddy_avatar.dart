import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The buddy's head in a round disc: 40 next to messages, 32 in compact rows.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Decorative: the text next to it already says who the buddy is.
    return ExcludeSemantics(
      child: SvgPicture.asset(
        dark
            ? 'assets/buddy/biscuit-avatar-dark.svg'
            : 'assets/buddy/biscuit-avatar.svg',
        width: size,
        height: size,
      ),
    );
  }
}
