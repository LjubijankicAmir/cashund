import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/widgets/limit_row.dart';
import 'package:flutter/material.dart';

/// A limit's progress as a card: a big "$412.35 of $600.00", the share used
/// and a thick bar. For the overall limit, and a limit's detail page.
class OverallLimitCard extends StatelessWidget {
  const OverallLimitCard({
    required this.progress,
    required this.label,
    required this.currency,
    required this.today,
    this.onTap,
    super.key,
  });

  final LimitProgress progress;

  /// The header, e.g. "All spending · This week · Oct 5 – 11".
  final String label;
  final Currency currency;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<CashundColors>()!;
    final warn = progress.status != LimitStatus.under;
    final muted = CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant);

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CashundRadius.lg),
        side: theme.brightness == Brightness.dark
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
      elevation: theme.brightness == Brightness.dark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CashundSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CashundSpace.s2,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: muted)),
                  Text(
                    l10n.limitPercent(progress.percent),
                    style: muted.copyWith(color: warn ? colors.warning : null),
                  ),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatMoney(progress.spentMinor, currency),
                      style: CashundText.pageTitle.copyWith(
                        color: warn ? colors.warning : scheme.onSurface,
                        fontFeatures: CashundText.amount.fontFeatures,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' ${l10n.limitOf(formatMoney(progress.amountMinor, currency))}',
                      style: CashundText.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              LimitBar(
                fraction: progress.fraction,
                color: warn ? colors.warningFill : scheme.primary,
                height: 12,
              ),
              LimitMeta(progress: progress, currency: currency, today: today),
            ],
          ),
        ),
      ),
    );
  }
}
