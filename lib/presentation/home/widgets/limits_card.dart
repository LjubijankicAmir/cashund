import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/widgets/limit_row.dart';
import 'package:flutter/material.dart';

/// Home's limits: the top few for the period, or a quiet prompt to set one.
class LimitsCard extends StatelessWidget {
  const LimitsCard({
    required this.limits,
    required this.currency,
    required this.today,
    required this.onSeeAll,
    super.key,
  });

  /// Most used first.
  final List<LimitProgress> limits;
  final Currency currency;
  final DateTime today;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeLimitsTitle,
                style: CashundText.title.copyWith(color: scheme.onSurface),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: Text(l10n.homeLimitsSeeAll)),
          ],
        ),
        for (final (index, limit) in limits.indexed) ...[
          if (index > 0)
            Divider(height: CashundSpace.s6, color: scheme.outlineVariant),
          if (index == 0) const SizedBox(height: CashundSpace.s2),
          LimitRow(
            progress: limit,
            currency: currency,
            today: today,
            showMeta: false,
          ),
        ],
      ],
    );
  }
}

/// No limits yet: a nudge to set one, which "Not now" hides for good.
class LimitsPrompt extends StatelessWidget {
  const LimitsPrompt({
    required this.buddyName,
    required this.onSetLimit,
    required this.onNotNow,
    super.key,
  });

  final String buddyName;
  final VoidCallback onSetLimit;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CashundRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CashundSpace.s4,
          CashundSpace.s4,
          CashundSpace.s4,
          CashundSpace.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CashundSpace.s2,
          children: [
            Text(
              l10n.homeLimitsTitle,
              style: CashundText.title.copyWith(color: scheme.onSurface),
            ),
            Text(
              l10n.homeLimitsPrompt(buddyName),
              style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
            ),
            Row(
              spacing: CashundSpace.s2,
              children: [
                FilledButton.tonal(
                  onPressed: onSetLimit,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(l10n.limitsSetLimit),
                ),
                TextButton(
                  onPressed: onNotNow,
                  child: Text(l10n.homeLimitsNotNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
