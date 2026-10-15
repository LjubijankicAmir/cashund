import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/widgets/transaction_row.dart';
import 'package:flutter/material.dart';

/// A sample transaction in [category], showing how it will look in lists.
class CategoryPreview extends StatelessWidget {
  const CategoryPreview({
    required this.category,
    required this.currencyCode,
    super.key,
  });

  final Category category;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sample = DateTime(2026);
    final isExpense = category.type == TransactionType.expense;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CashundRadius.md),
      ),
      child: ExcludeSemantics(
        child: TransactionRow(
          entry: TransactionWithCategory(
            category: category,
            transaction: Transaction(
              id: 0,
              type: category.type,
              amountMinor: 2400,
              currencyCode: currencyCode,
              categoryId: category.id,
              occurredOn: sample,
              createdAt: sample,
              title: isExpense
                  ? l10n.categoryEditorSampleExpense
                  : l10n.categoryEditorSampleIncome,
            ),
          ),
        ),
      ),
    );
  }
}
