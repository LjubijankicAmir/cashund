import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/extensions/transaction_display.dart';
import 'package:cashund/presentation/common/widgets/buddy_avatar.dart';
import 'package:cashund/presentation/reaction/bloc/reaction_cubit.dart';
import 'package:cashund/presentation/reaction/widgets/reaction_timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The buddy's reaction floating above the bottom bar, on tabs where the
/// buddy isn't already peeking.
class ReactionCard extends StatelessWidget {
  const ReactionCard({
    required this.reaction,
    required this.visibleFor,
    required this.onDismiss,
    super.key,
  });

  final Reaction reaction;
  final Duration visibleFor;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(CashundRadius.lg),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CashundSpace.s3,
          CashundSpace.s3,
          CashundSpace.s1,
          CashundSpace.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CashundSpace.s3,
          children: [
            const BuddyAvatar(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: CashundSpace.s1,
                children: [
                  ReactionMeta(reaction: reaction),
                  Text(
                    reaction.line.text(context.l10n),
                    style: CashundText.body.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: CashundSpace.s1),
                  ReactionTimerBar(
                    key: ValueKey(reaction.id),
                    duration: visibleFor,
                  ),
                ],
              ),
            ),
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
    );
  }
}

/// "Biscuit · Saved −$42.75": who's talking and what was logged.
class ReactionMeta extends StatelessWidget {
  const ReactionMeta({required this.reaction, super.key});

  final Reaction reaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: reaction.buddyName,
            style: CashundText.buddyName.copyWith(color: scheme.primary),
          ),
          TextSpan(
            text:
                ' · ${context.l10n.reactionSaved(reaction.transaction.signedAmount)}',
            style: CashundText.bodySm.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
