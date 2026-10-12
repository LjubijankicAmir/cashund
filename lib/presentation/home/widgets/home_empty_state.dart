import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// What Home shows before anything is logged: a nudge and the two ways in.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    required this.period,
    required this.onAddExpense,
    required this.onAddIncome,
    super.key,
  });

  final Period period;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final title = switch (period) {
      Period.day => l10n.homeEmptyTitleDay,
      Period.week => l10n.homeEmptyTitleWeek,
      Period.month => l10n.homeEmptyTitleMonth,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: CashundText.pageTitle.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: CashundSpace.s2),
        Text(
          l10n.homeEmptyBody,
          textAlign: TextAlign.center,
          style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s6),
        Row(
          spacing: CashundSpace.s3,
          children: [
            Expanded(
              child: PrimaryButton(
                label: l10n.addExpense,
                onPressed: onAddExpense,
              ),
            ),
            Expanded(
              child: FilledButton.tonal(
                onPressed: onAddIncome,
                child: Text(l10n.addIncome),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
