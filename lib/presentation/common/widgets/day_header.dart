import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The line above a day's transactions: which day, and its net amount.
class DayHeader extends StatelessWidget {
  const DayHeader({
    required this.day,
    required this.today,
    required this.net,
    super.key,
  });

  final DateTime day;
  final DateTime today;

  /// The day's net, already formatted with its sign.
  final String net;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final style = CashundText.body.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final date = DateFormat.MMMEd(locale).format(day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final label = day == today
        ? l10n.activityDayToday(date)
        : day == yesterday
        ? l10n.activityDayYesterday(date)
        : date;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        // Same look as the date, with digits that line up across days.
        Text(
          net,
          style: style.copyWith(fontFeatures: CashundText.amount.fontFeatures),
        ),
      ],
    );
  }
}
