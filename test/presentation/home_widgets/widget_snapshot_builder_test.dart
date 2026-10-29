import 'dart:ui';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/home_widgets/widget_snapshot.dart';
import 'package:cashund/presentation/home_widgets/widget_snapshot_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final usd = currencyByCode('USD')!;

  // A Wednesday afternoon; with Monday starts, the week runs Oct 5 – 11.
  final now = DateTime(2026, 10, 7, 14, 30);
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  final month = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));

  const eatingOut = Category(
    id: 2,
    type: TransactionType.expense,
    emoji: '🍔',
    color: CategoryColor.apricot,
    sortOrder: 1,
    predefinedKey: 'eating_out',
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
    predefinedKey: 'groceries',
  );

  LimitProgress limit({
    required int id,
    required int amount,
    required int spent,
    LimitPeriod period = LimitPeriod.week,
    Category? category,
  }) => LimitProgress(
    limit: SpendingLimit(
      id: id,
      period: period,
      currencyCode: 'USD',
      createdAt: DateTime(2026, 9),
      categoryId: category?.id,
    ),
    category: category,
    range: period == LimitPeriod.week ? week : month,
    amountMinor: amount,
    spentMinor: spent,
  );

  WidgetInputs inputs({
    bool hasTransactions = true,
    WeekStart weekStart = WeekStart.monday,
    PeriodSummary today = const PeriodSummary(
      expenseMinor: 4275,
      transactionCount: 2,
    ),
    PeriodSummary week = const PeriodSummary(
      expenseMinor: 41235,
      incomeMinor: 240000,
      transactionCount: 9,
    ),
    Category? weekTopCategory = groceries,
    List<LimitProgress> weekLimits = const [],
    List<LimitProgress> monthLimits = const [],
  }) => (
    now: now,
    currency: usd,
    weekStart: weekStart,
    hasTransactions: hasTransactions,
    today: today,
    week: week,
    weekTopCategory: weekTopCategory,
    weekLimits: weekLimits,
    monthLimits: monthLimits,
  );

  WidgetEntry first(WidgetInputs inputs) =>
      WidgetSnapshotBuilder.build(inputs, l10n).entries.first;

  setUpAll(() => initializeDateFormatting('en'));

  test('invites the first transaction while nothing is logged', () {
    final entry = first(
      inputs(
        hasTransactions: false,
        today: const PeriodSummary(),
        week: const PeriodSummary(),
        weekTopCategory: null,
      ),
    );

    expect(entry.mood, WidgetMood.sleeping);
    expect(
      entry.spending,
      const SpendingTile(
        kind: SpendingTileKind.empty,
        title: 'This week',
        hero: 'Nothing yet',
        caption: 'Log your first one',
        link: 'cashund://add?type=expense',
      ),
    );
    expect(entry.limits, isNull);
    expect(entry.todayWeek.topValue, '—');
    expect(entry.todayWeek.topColor, isNull);
  });

  test('words today and the week', () {
    final entry = first(inputs());

    expect(
      entry.today,
      const TodayTile(
        title: 'Today',
        hero: r'−$42.75',
        caption: '2 transactions',
        weekLabel: 'This week',
        weekValue: r'−$412.35',
        link: 'cashund://home',
      ),
    );
    expect(entry.todayWeek.weekTitle, 'This week · Oct 5 – 11');
    expect(entry.todayWeek.outValue, r'−$412.35');
    expect(entry.todayWeek.inValue, r'+$2,400.00');
    expect(entry.todayWeek.topValue, '🛒 Groceries');
    expect(entry.todayWeek.topColor, CategoryColor.olive);
  });

  group('spending and compact', () {
    test('measure the week against the overall limit', () {
      final entry = first(
        inputs(weekLimits: [limit(id: 1, amount: 60000, spent: 41235)]),
      );

      expect(entry.spending.kind, SpendingTileKind.normal);
      expect(entry.spending.hero, r'$412.35');
      expect(entry.spending.caption, r'of $600 this week');
      expect(entry.spending.fraction, closeTo(0.687, 0.001));
      expect(
        entry.compact,
        CompactTile(
          hero: r'$187.65',
          caption: 'left this week',
          fraction: entry.spending.fraction,
          link: 'cashund://home',
        ),
      );
    });

    test('show cents only for a limit that has them', () {
      final entry = first(
        inputs(weekLimits: [limit(id: 1, amount: 65050, spent: 41235)]),
      );

      expect(entry.spending.caption, r'of $650.50 this week');
    });

    test('show what was spent, without a bar, with no overall limit', () {
      final entry = first(inputs());

      expect(entry.spending.caption, 'spent this week');
      expect(entry.spending.fraction, isNull);
      expect(
        entry.compact,
        const CompactTile(
          hero: r'$412.35',
          caption: 'spent this week',
          link: 'cashund://home',
        ),
      );
    });

    test('call out the limit that is furthest over', () {
      final entry = first(
        inputs(
          weekLimits: [
            limit(id: 1, amount: 60000, spent: 61000),
            limit(id: 2, amount: 10000, spent: 11240, category: eatingOut),
          ],
        ),
      );

      expect(
        entry.spending,
        const SpendingTile(
          kind: SpendingTileKind.over,
          title: 'Over a limit',
          hero: r'$12.40',
          caption: 'over the 🍔 Eating Out limit',
          fraction: 1,
          link: 'cashund://limits/2',
        ),
      );
      expect(
        entry.compact,
        const CompactTile(
          hero: r'$10.00',
          caption: 'over this week',
          fraction: 1,
          link: 'cashund://home',
        ),
      );
    });

    test('name the overall limit when that one is over', () {
      final entry = first(
        inputs(
          monthLimits: [
            limit(
              id: 5,
              amount: 200000,
              spent: 210000,
              period: LimitPeriod.month,
            ),
          ],
        ),
      );

      expect(entry.spending.caption, 'over your monthly limit');
      expect(entry.spending.hero, r'$100.00');
    });
  });

  group('limits', () {
    test('show the two most used of the week, with how it stands', () {
      final entry = first(
        inputs(
          weekLimits: [
            limit(id: 2, amount: 10000, spent: 8640, category: eatingOut),
            limit(id: 1, amount: 60000, spent: 41235),
            limit(id: 3, amount: 20000, spent: 14820, category: groceries),
            limit(
              id: 4,
              amount: 20000,
              spent: 100,
              category: groceries.copyWith(id: 7),
            ),
          ],
        ),
      );

      expect(entry.limits!.title, 'Limits · this week');
      expect(entry.limits!.link, 'cashund://limits?period=week');
      expect(entry.limits!.status, 'Eating Out is close');
      expect(entry.limits!.warns, isTrue);
      expect(entry.limits!.rows, [
        const LimitRowTile(
          limitId: 2,
          emoji: '🍔',
          name: 'Eating Out',
          spent: r'$86.40',
          amount: r'$100.00',
          fraction: 0.864,
          status: LimitStatus.near,
          color: CategoryColor.apricot,
          link: 'cashund://limits/2',
        ),
        const LimitRowTile(
          limitId: 3,
          emoji: '🛒',
          name: 'Groceries',
          spent: r'$148.20',
          amount: r'$200.00',
          fraction: 0.741,
          status: LimitStatus.under,
          color: CategoryColor.olive,
          link: 'cashund://limits/3',
        ),
      ]);
    });

    test('say how far over the top one is', () {
      final entry = first(
        inputs(
          weekLimits: [
            limit(id: 2, amount: 10000, spent: 11240, category: eatingOut),
          ],
        ),
      );

      expect(entry.limits!.status, r'Over by $12.40');
      expect(entry.limits!.rows.single.fraction, 1);
    });

    test('are all under, calmly', () {
      final entry = first(
        inputs(
          weekLimits: [
            limit(id: 3, amount: 20000, spent: 5000, category: groceries),
          ],
        ),
      );

      expect(entry.limits!.status, 'All under');
      expect(entry.limits!.warns, isFalse);
    });

    test('fall back to the month when only monthly ones are set', () {
      final entry = first(
        inputs(
          monthLimits: [
            limit(
              id: 6,
              amount: 40000,
              spent: 1000,
              period: LimitPeriod.month,
              category: eatingOut,
            ),
          ],
        ),
      );

      expect(entry.limits!.title, 'Limits · this month');
      expect(entry.limits!.link, 'cashund://limits?period=month');
      expect(entry.limits!.rows.single.limitId, 6);
    });

    test('are left out with only an overall limit', () {
      final entry = first(
        inputs(weekLimits: [limit(id: 1, amount: 60000, spent: 100)]),
      );

      expect(entry.limits, isNull);
    });
  });

  group('mood', () {
    test('worries about a limit near or over', () {
      expect(
        first(
          inputs(
            monthLimits: [
              limit(
                id: 6,
                amount: 10000,
                spent: 8000,
                period: LimitPeriod.month,
                category: eatingOut,
              ),
            ],
          ),
        ).mood,
        WidgetMood.worried,
      );
    });

    test('is happy under all limits or after a good week', () {
      expect(
        first(
          inputs(
            weekLimits: [limit(id: 1, amount: 60000, spent: 100)],
            week: const PeriodSummary(expenseMinor: 100, transactionCount: 1),
          ),
        ).mood,
        WidgetMood.happy,
      );
      expect(first(inputs()).mood, WidgetMood.happy);
    });

    test('listens otherwise', () {
      expect(
        first(
          inputs(
            week: const PeriodSummary(expenseMinor: 100, transactionCount: 1),
          ),
        ).mood,
        WidgetMood.listening,
      );
    });
  });

  group('timeline', () {
    test('steps through midnight, the next week and the next month', () {
      final snapshot = WidgetSnapshotBuilder.build(inputs(), l10n);

      expect(
        [for (final entry in snapshot.entries) entry.from],
        [
          DateTime(2026, 10, 7),
          DateTime(2026, 10, 8),
          DateTime(2026, 10, 12),
          DateTime(2026, 11),
        ],
      );
    });

    test('starts the week on the chosen day', () {
      DateTime weekBoundary(WeekStart weekStart) => WidgetSnapshotBuilder.build(
        inputs(weekStart: weekStart),
        l10n,
      ).entries[2].from;

      expect(weekBoundary(WeekStart.sunday), DateTime(2026, 10, 11));
      expect(weekBoundary(WeekStart.saturday), DateTime(2026, 10, 10));
    });

    test('starts each period over at its boundary', () {
      final entries = WidgetSnapshotBuilder.build(
        inputs(
          weekLimits: [
            limit(id: 2, amount: 10000, spent: 11240, category: eatingOut),
          ],
          monthLimits: [
            limit(
              id: 6,
              amount: 40000,
              spent: 32000,
              period: LimitPeriod.month,
              category: groceries,
            ),
          ],
        ),
        l10n,
      ).entries;

      // Tomorrow: a fresh day, the same week.
      expect(entries[1].today.hero, r'$0.00');
      expect(entries[1].today.caption, 'Nothing logged');
      expect(entries[1].today.weekValue, r'−$412.35');
      expect(entries[1].spending.kind, SpendingTileKind.over);

      // Next week: its limits start over, the month's don't.
      expect(entries[2].today.weekValue, r'$0.00');
      expect(entries[2].todayWeek.weekTitle, 'This week · Oct 12 – 18');
      expect(entries[2].todayWeek.topValue, '—');
      expect(entries[2].spending.kind, SpendingTileKind.normal);
      expect(entries[2].limits!.rows.single.spent, r'$0.00');
      // The month's limit is still at 80%.
      expect(entries[2].mood, WidgetMood.worried);

      // Next month: that one starts over too.
      expect(entries[3].mood, WidgetMood.happy);
    });
  });

  test('writes JSON the native widgets read', () {
    final json = WidgetSnapshotBuilder.build(
      inputs(
        weekLimits: [
          limit(id: 2, amount: 10000, spent: 8640, category: eatingOut),
        ],
      ),
      l10n,
    ).toJson();

    expect(json['version'], WidgetSnapshot.version);
    final entry = (json['entries']! as List<Object?>).first! as Map;
    expect(entry['from'], DateTime(2026, 10, 7).millisecondsSinceEpoch);
    expect(entry['mood'], 'worried');
    expect((entry['spending']! as Map)['kind'], 'normal');
    final row = ((entry['limits']! as Map)['rows']! as List<Object?>).single;
    expect(row, {
      'limitId': 2,
      'emoji': '🍔',
      'name': 'Eating Out',
      'spent': r'$86.40',
      'amount': r'$100.00',
      'fraction': 0.864,
      'status': 'near',
      'color': 'apricot',
      'link': 'cashund://limits/2',
    });
  });
}
