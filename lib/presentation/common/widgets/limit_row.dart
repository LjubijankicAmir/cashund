import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/extensions/limit_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A limit: its category, "spent / limit" and a progress bar in the
/// category's color, turning to the warning color from 80% on.
class LimitRow extends StatelessWidget {
  const LimitRow({
    required this.progress,
    required this.currency,
    required this.today,
    this.showMeta = true,
    this.onTap,
    super.key,
  });

  final LimitProgress progress;
  final Currency currency;
  final DateTime today;

  /// The "$X left · N days left" line. Without it, only "Over by $X" shows.
  final bool showMeta;

  /// Shows a chevron when set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;
    final status = progress.status;
    final warn = status != LimitStatus.under;
    final mark = switch (progress.category) {
      final category? => context.categoryColor(category.color).mark,
      null => scheme.primary,
    };
    final money = TextStyle(fontFeatures: CashundText.amount.fontFeatures);

    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s2,
      children: [
        Row(
          spacing: CashundSpace.s2,
          children: [
            if (progress.category case final category?)
              CategoryMark(color: category.color, height: 18),
            Expanded(
              child: Text(
                progress.label(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CashundText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                style: CashundText.amountSm
                    .merge(money)
                    .copyWith(
                      color: warn ? colors.warning : scheme.onSurfaceVariant,
                      fontWeight: warn ? FontWeight.w700 : null,
                    ),
                children: [
                  TextSpan(
                    text: formatMoney(progress.spentMinor, currency),
                    style: TextStyle(
                      color: warn ? null : scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${formatMoney(progress.amountMinor, currency)}',
                  ),
                ],
              ),
            ),
          ],
        ),
        LimitBar(
          fraction: progress.fraction,
          color: warn ? colors.warningFill : mark,
          height: showMeta ? 8 : 6,
        ),
        if (showMeta || status == LimitStatus.over)
          LimitMeta(
            progress: progress,
            currency: currency,
            today: today,
            showDays: showMeta,
          ),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: row),
          const SizedBox(width: CashundSpace.s3),
          Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// What's left (or how far over) and, if [showDays], the days left.
class LimitMeta extends StatelessWidget {
  const LimitMeta({
    required this.progress,
    required this.currency,
    required this.today,
    this.showDays = true,
    super.key,
  });

  final LimitProgress progress;
  final Currency currency;
  final DateTime today;
  final bool showDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;
    final warn = progress.status != LimitStatus.under;
    final muted = CashundText.bodySm.copyWith(color: scheme.onSurfaceVariant);
    final left = progress.status == LimitStatus.over
        ? l10n.limitOverBy(formatMoney(progress.overByMinor, currency))
        : l10n.limitLeft(formatMoney(progress.leftMinor, currency));

    return Row(
      children: [
        if (warn) ...[
          Icon(
            LucideIcons.triangleAlert,
            size: 13,
            color: colors.warning,
            semanticLabel: l10n.limitWarning,
          ),
          const SizedBox(width: CashundSpace.s1),
        ],
        Expanded(
          child: Text(
            left,
            style: warn
                ? muted.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w700,
                  )
                : muted,
          ),
        ),
        if (showDays)
          Text(l10n.limitDaysLeft(progress.daysLeft(today)), style: muted),
      ],
    );
  }
}

/// A rounded progress track; the fill stops at full even when over.
class LimitBar extends StatelessWidget {
  const LimitBar({
    required this.fraction,
    required this.color,
    this.height = 8,
    super.key,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
