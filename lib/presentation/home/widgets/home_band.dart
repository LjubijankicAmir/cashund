import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The top of Home: the period switch, settings, and the period's balance.
class HomeBand extends StatelessWidget {
  const HomeBand({
    required this.period,
    required this.range,
    required this.currency,
    required this.summary,
    required this.onPeriodSelected,
    required this.onSettingsPressed,
    super.key,
  });

  final Period period;
  final DateRange range;
  final Currency currency;

  /// `null` while loading; shown as nothing logged.
  final PeriodSummary? summary;
  final ValueChanged<Period> onPeriodSelected;
  final VoidCallback onSettingsPressed;

  String _caption(AppLocalizations l10n, String locale) => switch (period) {
    Period.day => l10n.homeCaptionDay(
      DateFormat.MMMEd(locale).format(range.start),
    ),
    Period.week => l10n.homeCaptionWeek(formatDateRange(range, locale)),
    Period.month => l10n.homeCaptionMonth(
      DateFormat.MMMM(locale).format(range.start),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final colors = Theme.of(context).extension<CashundColors>()!;
    final summary = this.summary ?? const PeriodSummary();
    final muted = CashundText.body.copyWith(color: colors.onBrandMuted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s4,
        CashundSpace.s6,
        CashundSpace.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SegmentedPills(
                onBrand: true,
                segments: [
                  (Period.day, l10n.periodDay),
                  (Period.week, l10n.periodWeek),
                  (Period.month, l10n.periodMonth),
                ],
                selected: period,
                onChanged: onPeriodSelected,
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.settings,
                onPressed: onSettingsPressed,
                style: IconButton.styleFrom(
                  backgroundColor: colors.onBrand.withValues(alpha: 0.16),
                  foregroundColor: colors.onBrand,
                ),
                icon: const Icon(LucideIcons.settings),
              ),
            ],
          ),
          const SizedBox(height: CashundSpace.s6),
          Text(_caption(l10n, locale), style: muted),
          const SizedBox(height: CashundSpace.s1),
          // Rolls from the previous balance to the new one.
          TweenAnimationBuilder<double>(
            tween: Tween(end: summary.balanceMinor.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              formatMoney(value.round(), currency),
              style: CashundText.displayXl.copyWith(color: colors.onBrand),
            ),
          ),
          Text(
            summary.isEmpty
                ? l10n.homeNothingLogged
                : l10n.homeInOut(
                    formatMoney(summary.incomeMinor, currency, signed: true),
                    formatMoney(-summary.expenseMinor, currency),
                  ),
            style: muted,
          ),
        ],
      ),
    );
  }
}
