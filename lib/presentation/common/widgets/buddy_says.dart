import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/buddy_avatar.dart';
import 'package:flutter/material.dart';

/// The buddy's avatar beside a speech bubble with one line, for pages where
/// the buddy isn't peeking.
class BuddySays extends StatelessWidget {
  const BuddySays({required this.buddyName, required this.message, super.key});

  final String buddyName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CashundSpace.s3,
      children: [
        const BuddyAvatar(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CashundSpace.s1,
            children: [
              Text(
                buddyName,
                style: CashundText.buddyName.copyWith(color: scheme.primary),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: CashundRadius.bubble,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CashundSpace.s4,
                    vertical: CashundSpace.s3,
                  ),
                  child: Text(
                    message,
                    style: CashundText.bodyLg.copyWith(color: scheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
