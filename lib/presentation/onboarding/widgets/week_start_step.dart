import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Step 3: the day the user's week starts on.
class WeekStartStep extends StatelessWidget {
  const WeekStartStep({this.today, super.key});

  /// Overrides today's date in the week preview, for tests.
  final DateTime? today;

  /// In the order they're offered.
  static const List<WeekStart> options = [
    WeekStart.monday,
    WeekStart.sunday,
    WeekStart.saturday,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<OnboardingBloc>();
    final weekStart = context.select<OnboardingBloc, WeekStart>(
      (bloc) => bloc.state.weekStart,
    );

    return ListView(
      padding: stepBodyPadding,
      children: [
        Text(
          l10n.onboardingWeekSubtitle,
          style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: CashundSpace.s5),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: CashundSpace.s3),
            child: OptionCard(
              title: DateFormat.EEEE(locale).format(_dayOfWeek(option.weekday)),
              selected: option == weekStart,
              onTap: () => bloc.add(OnboardingEvent.weekStartSelected(option)),
            ),
          ),
        const SizedBox(height: CashundSpace.s3),
        _WeekPreview(
          weekStart: weekStart,
          today: today ?? DateTime.now(),
          locale: locale,
        ),
      ],
    );
  }

  /// Any date falling on [weekday]; only its name is used.
  static DateTime _dayOfWeek(int weekday) => DateTime(2024, 1, weekday);
}

/// The current week laid out from the chosen first day.
class _WeekPreview extends StatelessWidget {
  const _WeekPreview({
    required this.weekStart,
    required this.today,
    required this.locale,
  });

  final WeekStart weekStart;
  final DateTime today;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateUtils.dateOnly(today);
    final first = DateUtils.addDaysToDate(
      date,
      -((date.weekday - weekStart.weekday) % 7),
    );

    return Container(
      padding: const EdgeInsets.all(CashundSpace.s4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CashundRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CashundSpace.s3,
        children: [
          Text(
            context.l10n.onboardingWeekPreview,
            style: CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant),
          ),
          Row(
            children: [
              for (var i = 0; i < DateTime.daysPerWeek; i++)
                Expanded(
                  child: _Day(
                    date: DateUtils.addDaysToDate(first, i),
                    isFirst: i == 0,
                    locale: locale,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.isFirst, required this.locale});

  final DateTime date;
  final bool isFirst;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isFirst ? scheme.onPrimary : scheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: CashundSpace.s2),
      decoration: BoxDecoration(
        color: isFirst ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(CashundRadius.md),
      ),
      child: Column(
        spacing: 2,
        children: [
          Text(
            DateFormat.E(locale).format(date),
            style: CashundText.labelSm.copyWith(color: color),
          ),
          Text(
            '${date.day}',
            style: CashundText.body.copyWith(
              color: color,
              fontFeatures: CashundText.amount.fontFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
