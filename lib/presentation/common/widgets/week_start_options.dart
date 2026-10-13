import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The first days of the week on offer as option cards, then a preview of
/// the current week laid out from the selected one.
class WeekStartOptions extends StatelessWidget {
  const WeekStartOptions({
    required this.selected,
    required this.onSelected,
    this.today,
    super.key,
  });

  final WeekStart selected;
  final ValueChanged<WeekStart> onSelected;

  /// Overrides today's date in the week preview, for tests.
  final DateTime? today;

  /// In the order they're offered.
  static const List<WeekStart> options = [
    WeekStart.monday,
    WeekStart.sunday,
    WeekStart.saturday,
  ];

  /// The localized name of [weekStart]'s day, e.g. "Monday".
  static String dayName(WeekStart weekStart, String locale) {
    // Any date falling on that weekday; only its name is used.
    return DateFormat.EEEE(locale).format(DateTime(2024, 1, weekStart.weekday));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: CashundSpace.s3),
            child: OptionCard(
              title: dayName(option, locale),
              selected: option == selected,
              onTap: () => onSelected(option),
            ),
          ),
        const SizedBox(height: CashundSpace.s3),
        _WeekPreview(
          weekStart: selected,
          today: today ?? DateTime.now(),
          locale: locale,
        ),
      ],
    );
  }
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
            context.l10n.weekPreviewTitle,
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
