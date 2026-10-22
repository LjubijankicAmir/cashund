import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/presentation/common/widgets/surface_card.dart';
import 'package:flutter/material.dart';

/// What came in, went out and was kept, with a bar splitting income into
/// spent and kept.
class InOutCard extends StatelessWidget {
  const InOutCard({
    required this.summary,
    required this.label,
    required this.currency,
    super.key,
  });

  final PeriodSummary summary;

  /// The period, e.g. "October".
  final String label;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;
    final (income, expense) = (summary.incomeMinor, summary.expenseMinor);
    final net = income - expense;
    final spentShare = income == 0 ? 100 : (expense * 100 / income).round();
    final money = TextStyle(fontFeatures: CashundText.amount.fontFeatures);

    Widget stat(String name, String value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            name,
            style: CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: CashundText.title
                  .merge(money)
                  .copyWith(fontSize: 17, color: color),
            ),
          ),
        ],
      ),
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CashundSpace.s4,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.insightsInOut,
                  style: CashundText.title.copyWith(color: scheme.onSurface),
                ),
              ),
              Text(
                label,
                style: CashundText.bodySm.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            spacing: CashundSpace.s3,
            children: [
              stat(
                l10n.insightsIn,
                formatMoney(income, currency, signed: true),
                colors.positive,
              ),
              stat(
                l10n.insightsOut,
                formatMoney(-expense, currency),
                scheme.onSurface,
              ),
              stat(
                l10n.insightsNet,
                formatMoney(net, currency, signed: true),
                net >= 0 ? colors.positive : scheme.onSurface,
              ),
            ],
          ),
          if (income > 0) ...[
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    spacing: spentShare >= 100 ? 0 : 2,
                    children: [
                      Expanded(
                        flex: spentShare.clamp(1, 100),
                        child: ColoredBox(color: scheme.outline),
                      ),
                      if (spentShare < 100)
                        Expanded(
                          flex: 100 - spentShare,
                          child: ColoredBox(color: colors.positive),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: CashundSpace.s4,
              children: [
                if (spentShare > 100)
                  _Legend(
                    scheme.outline,
                    l10n.insightsSpentOfIncome(spentShare),
                  )
                else ...[
                  _Legend(scheme.outline, l10n.insightsSpentShare(spentShare)),
                  _Legend(
                    colors.positive,
                    l10n.insightsKeptShare(100 - spentShare),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          label,
          style: CashundText.bodySm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
