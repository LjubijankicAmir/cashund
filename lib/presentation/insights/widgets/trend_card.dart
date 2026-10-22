import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/widgets/surface_card.dart';
import 'package:cashund/presentation/common/widgets/trend_bars.dart';
import 'package:flutter/material.dart';

/// Spending over the last periods, with the average in the header.
class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.title,
    required this.averageMinor,
    required this.bars,
    required this.currency,
    required this.currentLabel,
    required this.pastLabel,
    this.currentColor,
    super.key,
  });

  final String title;
  final int averageMinor;
  final List<TrendBar> bars;
  final Currency currency;
  final String currentLabel;
  final String pastLabel;
  final Color? currentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CashundSpace.s4,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: CashundText.title.copyWith(color: scheme.onSurface),
                ),
              ),
              if (averageMinor > 0)
                Text(
                  l10n.insightsAverage(
                    formatMoneyWhole(averageMinor, currency),
                  ),
                  style: CashundText.bodySm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          TrendBars(
            bars: bars,
            currency: currency,
            currentLabel: currentLabel,
            pastLabel: pastLabel,
            currentColor: currentColor,
          ),
        ],
      ),
    );
  }
}
