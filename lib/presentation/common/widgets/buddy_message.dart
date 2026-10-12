import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Something the buddy says: their name above a speech bubble whose tail
/// points up at the buddy peeking over the sheet.
///
/// The buddy's name is user-defined, so always pass it in.
class BuddyMessage extends StatelessWidget {
  const BuddyMessage({
    required this.buddyName,
    required this.message,
    this.onDismiss,
    super.key,
  });

  final String buddyName;
  final String message;

  /// Shows a close button when set.
  final VoidCallback? onDismiss;

  /// Bubbles don't stretch across the whole sheet.
  static const _maxWidthFactor = 0.8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * _maxWidthFactor,
          ),
          // A Container (unlike a DecoratedBox) adds the border's room for the
          // tail on top of this padding.
          child: Container(
            decoration: ShapeDecoration(
              color: scheme.primaryContainer,
              shape: const SpeechBubbleBorder(radius: CashundRadius.lg),
            ),
            padding: EdgeInsets.fromLTRB(
              CashundSpace.s4,
              CashundSpace.s3,
              onDismiss == null ? CashundSpace.s4 : CashundSpace.s1,
              CashundSpace.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: CashundSpace.s1,
                    children: [
                      Text(
                        buddyName,
                        style: CashundText.buddyName.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        message,
                        style: CashundText.bodyLg.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss case final onDismiss?)
                  IconButton(
                    tooltip: context.l10n.dismiss,
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle whose top-right corner rises into a tail, pointing up
/// at the buddy. The tail's height is part of the layout.
class SpeechBubbleBorder extends ShapeBorder {
  const SpeechBubbleBorder({required this.radius});

  final double radius;

  static const _tailWidth = 16.0;
  static const _tailHeight = 10.0;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(top: _tailHeight);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Rect.fromLTRB(
      rect.left,
      rect.top + _tailHeight,
      rect.right,
      rect.bottom,
    );
    final corner = Radius.circular(min(radius, body.shortestSide / 2));

    return Path()
      // The top-right corner stays square so the tail grows straight out of it.
      ..addRRect(
        RRect.fromRectAndCorners(
          body,
          topLeft: corner,
          bottomLeft: corner,
          bottomRight: corner,
        ),
      )
      ..addPath(
        Path()
          ..moveTo(body.right - _tailWidth, body.top + 1)
          ..lineTo(body.right, rect.top)
          ..lineTo(body.right, body.top + 1)
          ..close(),
        Offset.zero,
      );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => SpeechBubbleBorder(radius: radius * t);
}
