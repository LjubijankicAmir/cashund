import 'dart:math';
import 'dart:ui';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/reaction/limit_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final usd = currencyByCode('USD')!;
  const eatingOut = Category(
    id: 2,
    type: TransactionType.expense,
    emoji: '🍔',
    color: CategoryColor.apricot,
    sortOrder: 1,
    predefinedKey: 'eating_out',
  );
  LimitProgress spent(int spentMinor) => LimitProgress(
    limit: SpendingLimit(
      id: 9,
      period: LimitPeriod.week,
      currencyCode: 'USD',
      createdAt: DateTime(2026, 9),
      categoryId: eatingOut.id,
    ),
    category: eatingOut,
    range: DateRange(start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 12)),
    amountMinor: 10000,
    spentMinor: spentMinor,
  );

  test('every line of both levels is distinct and filled in', () {
    for (final progress in [spent(8640), spent(11240)]) {
      final lines = {
        for (var i = 0; i < LimitLine.lineCount; i++)
          LimitLine(progress, i, currency: usd).text(l10n),
      };
      expect(lines, hasLength(LimitLine.lineCount));
      expect(lines.any((line) => line.contains('{')), isFalse);
    }
  });

  test('writes the category, share and amount into the line', () {
    expect(
      LimitLine(spent(8640), 0, currency: usd).text(l10n),
      'Heads up! Eating Out is at 86% of this week’s limit.',
    );
    expect(
      LimitLine(spent(11240), 1, currency: usd).text(l10n),
      r'We went $12.40 over on Eating Out. It happens.',
    );
  });

  test('a random line never repeats the previous one at the same level', () {
    final random = Random(4);
    var previous = LimitLine.random(spent(8640), currency: usd, random: random);
    for (var i = 0; i < 100; i++) {
      final next = LimitLine.random(
        spent(8640),
        currency: usd,
        random: random,
        previous: previous,
      );
      expect(next.index, isNot(previous.index));
      previous = next;
    }
  });

  test('the same limit gets the same line all day', () {
    final day = DateTime(2026, 10, 8);
    expect(
      LimitLine.forDay(spent(8640), day, currency: usd),
      LimitLine.forDay(spent(8640), day, currency: usd),
    );
  });
}
