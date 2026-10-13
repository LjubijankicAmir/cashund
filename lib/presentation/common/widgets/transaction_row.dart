import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:flutter/material.dart';

/// One transaction in a list: its category, title and amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.entry, this.onTap, super.key});

  final TransactionWithCategory entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (transaction, category) = (entry.transaction, entry.category);
    final swatch = context.categoryColor(category.color);
    final isIncome = transaction.type == TransactionType.income;
    final currency =
        currencyByCode(transaction.currencyCode) ??
        Currency(
          code: transaction.currencyCode,
          symbol: transaction.currencyCode,
          decimalDigits: 2,
        );
    final title = transaction.title;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CashundSpace.s4,
        vertical: CashundSpace.s3,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CashundSpace.s3,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: swatch.mark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Text(
                    category.label(l10n),
                    style: CashundText.categoryLabel.copyWith(
                      color: swatch.label,
                    ),
                  ),
                  Text(
                    title == null || title.isEmpty
                        ? category.name(l10n)
                        : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CashundText.rowTitle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Text(
                formatMoney(
                  isIncome ? transaction.amountMinor : -transaction.amountMinor,
                  currency,
                  signed: true,
                ),
                style: CashundText.amount.copyWith(
                  color: isIncome
                      ? Theme.of(context).extension<CashundColors>()!.positive
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
