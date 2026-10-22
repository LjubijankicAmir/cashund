import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/surface_card.dart';
import 'package:flutter/material.dart';

/// The period's spending as bars per category, largest first, each scaled
/// to the largest: the top 5, then "Other".
class RankedSpendingCard extends StatelessWidget {
  const RankedSpendingCard({
    required this.slices,
    required this.totalMinor,
    required this.otherCount,
    required this.currency,
    required this.onCategory,
    required this.onOther,
    this.note,
    super.key,
  });

  final List<SpendingSlice> slices;
  final int totalMinor;

  /// How many categories "Other" groups.
  final int otherCount;
  final Currency currency;
  final ValueChanged<Category> onCategory;
  final VoidCallback onOther;

  /// Shown at the top right; a hint by default.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final largest = slices.fold(
      1,
      (max, s) => s.amountMinor > max ? s.amountMinor : max,
    );
    final money = TextStyle(fontFeatures: CashundText.amount.fontFeatures);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.insightsSpendingTitle,
                  style: CashundText.title.copyWith(color: scheme.onSurface),
                ),
              ),
              Text(
                note ?? l10n.insightsTapHint,
                style: CashundText.bodySm.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: CashundSpace.s1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatMoney(totalMinor, currency),
                  style: CashundText.pageTitle
                      .merge(money)
                      .copyWith(color: scheme.onSurface),
                ),
                TextSpan(
                  text: ' ${l10n.insightsSpentLabel}',
                  style: CashundText.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CashundSpace.s2),
          for (final slice in slices)
            _Row(
              slice: slice,
              fraction: slice.amountMinor / largest,
              currency: currency,
              otherCount: otherCount,
              onTap: switch (slice.category) {
                final category? => () => onCategory(category),
                null => onOther,
              },
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.slice,
    required this.fraction,
    required this.currency,
    required this.otherCount,
    required this.onTap,
  });

  final SpendingSlice slice;
  final double fraction;
  final Currency currency;
  final int otherCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final category = slice.category;
    final swatch = category == null
        ? null
        : context.categoryColor(category.color);
    final money = TextStyle(fontFeatures: CashundText.amount.fontFeatures);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CashundRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CashundSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CashundSpace.s2,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category?.label(l10n) ?? l10n.insightsOther(otherCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CashundText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: swatch?.label ?? scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  formatMoney(slice.amountMinor, currency),
                  style: CashundText.body
                      .merge(money)
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${slice.percent}%',
                    textAlign: TextAlign.end,
                    style: CashundText.body
                        .merge(money)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.02, 1),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: swatch?.mark ?? scheme.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
