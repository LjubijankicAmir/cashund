import 'dart:ui';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/home/widgets/recap_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final usd = currencyByCode('USD')!;
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
    predefinedKey: 'groceries',
  );

  setUpAll(() => initializeDateFormatting('en'));

  String text(PeriodRecap recap) => recapText(l10n, 'en', recap, usd);

  test('a week that went better than the one before', () {
    final recap = PeriodRecap(
      period: LimitPeriod.week,
      range: DateRange(
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 12),
      ),
      spentMinor: 46890,
      previousSpentMinor: 51030,
      incomeMinor: 0,
    );

    expect(text(recap), r'Nice! You spent $41.40 less than the week before.');
    expect(recapMeta(l10n, 'en', recap), 'Your week, Oct 5 – 11');
  });

  test('a month in one line', () {
    final recap = PeriodRecap(
      period: LimitPeriod.month,
      range: DateRange(start: DateTime(2026, 9), end: DateTime(2026, 10)),
      spentMinor: 300000,
      incomeMinor: 275000,
      top: const CategorySpending(category: groceries, amountMinor: 51240),
    );

    expect(
      text(recap),
      r'September in one line: $3,000.00 out, $2,750.00 in, 🛒 Groceries on top.',
    );
    expect(recapMeta(l10n, 'en', recap), 'Your September');
  });
}
