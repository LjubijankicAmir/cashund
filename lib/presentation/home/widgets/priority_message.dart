import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/buddy_message.dart';
import 'package:cashund/presentation/home/bloc/home_message_bloc.dart';
import 'package:cashund/presentation/home/widgets/recap_text.dart';
import 'package:cashund/presentation/reaction/limit_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The peeking buddy's face for [message]: worried about a limit, happy
/// about a period that went better, listening otherwise.
BuddyExpression expressionFor(HomeMessage message) => switch (message) {
  LimitMessage() => BuddyExpression.worried,
  RecapMessage(:final recap) =>
    recap.line.isGood ? BuddyExpression.happy : BuddyExpression.listening,
};

/// A limit warning or a recap in the buddy's bubble on Home, with a way to
/// see more and a close button that keeps it closed.
class PriorityMessage extends StatelessWidget {
  const PriorityMessage({
    required this.message,
    required this.buddyName,
    required this.currency,
    required this.today,
    super.key,
  });

  final HomeMessage message;
  final String buddyName;
  final Currency currency;
  final DateTime today;

  void _close(BuildContext context) =>
      context.read<HomeMessageBloc>().add(HomeMessageEvent.closed(message));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;

    final (header, text, footer) = switch (message) {
      LimitMessage(:final progress) => (
        null,
        LimitLine.forDay(progress, today, currency: currency).text(l10n),
        _Action(
          label: l10n.limitMessageSeeLimits,
          onPressed: () => unawaited(
            context.router.root.push(
              LimitsRoute(period: progress.limit.period),
            ),
          ),
        ),
      ),
      RecapMessage(:final recap) => (
        Text(
          '$buddyName · ${recapMeta(l10n, locale, recap)}',
          style: CashundText.buddyName.copyWith(color: scheme.primary),
        ),
        recapText(l10n, locale, recap, currency),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CashundSpace.s2,
          children: [
            _RecapStats(recap: recap, currency: currency),
            _Action(
              label: l10n.recapSeeInsights,
              onPressed: () {
                // Seen: the recap has done its job.
                _close(context);
                unawaited(
                  context.router.root.push(
                    InsightsRoute(
                      period: recap.period == LimitPeriod.week
                          ? InsightsPeriod.week
                          : InsightsPeriod.month,
                      range: recap.range,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    };

    return BuddyMessage(
      buddyName: buddyName,
      header: header,
      message: text,
      footer: footer,
      onDismiss: () => _close(context),
    );
  }
}

/// Spent · Top category · Limits kept, only the ones that exist.
class _RecapStats extends StatelessWidget {
  const _RecapStats({required this.recap, required this.currency});

  final PeriodRecap recap;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = CashundText.labelSm.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );
    final value = CashundText.body.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      fontFeatures: CashundText.amount.fontFeatures,
    );
    final kept = recap.limitsKept;

    Widget stat(String name, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: label),
        Text(text, style: value, maxLines: 1, softWrap: false),
      ],
    );

    return Wrap(
      spacing: CashundSpace.s5,
      runSpacing: CashundSpace.s2,
      children: [
        stat(l10n.recapStatSpent, formatMoney(recap.spentMinor, currency)),
        if (recap.top case final top?)
          stat(
            l10n.recapStatTop,
            '${top.category.emoji} ${formatMoney(top.amountMinor, currency)}',
          ),
        if (kept != null)
          stat(
            l10n.recapStatLimitsKept,
            l10n.recapLimitsKeptValue(kept.kept, kept.of),
          ),
      ],
    );
  }
}

/// "See insights ›": a small text button lined up with the bubble's text.
class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      iconAlignment: IconAlignment.end,
      icon: const Icon(LucideIcons.chevronRight, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
