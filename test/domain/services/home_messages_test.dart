import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 13, 9);
  final week = DateRange(
    start: DateTime(2026, 10, 12),
    end: DateTime(2026, 10, 19),
  );
  final lastWeek = DateRange(start: DateTime(2026, 10, 5), end: week.start);
  final september = DateRange(
    start: DateTime(2026, 9),
    end: DateTime(2026, 10),
  );

  LimitProgress limit(int id, int spentMinor) => LimitProgress(
    limit: SpendingLimit(
      id: id,
      period: LimitPeriod.week,
      currencyCode: 'USD',
      createdAt: DateTime(2026, 9),
      categoryId: id,
    ),
    range: week,
    amountMinor: 10000,
    spentMinor: spentMinor,
  );
  PeriodRecap recap({
    LimitPeriod period = LimitPeriod.week,
    int spentMinor = 46890,
    int previousSpentMinor = 51030,
    int incomeMinor = 0,
    ({int kept, int of})? limitsKept,
  }) => PeriodRecap(
    period: period,
    range: period == LimitPeriod.week ? lastWeek : september,
    spentMinor: spentMinor,
    previousSpentMinor: previousSpentMinor,
    incomeMinor: incomeMinor,
    limitsKept: limitsKept,
  );

  HomeMessage? pick({
    List<LimitProgress> limits = const [],
    List<PeriodRecap> recaps = const [],
    Map<String, DateTime> dismissed = const {},
  }) => HomeMessages.pick(
    limits: limits,
    recaps: recaps,
    dismissed: dismissed,
    today: today,
  );

  group('pick', () {
    test('a limit over comes before one close to it, then by share', () {
      final close = limit(1, 9500);
      final over = limit(2, 10500);
      final further = limit(3, 13000);

      expect(
        pick(limits: [close, over, further], recaps: [recap()]),
        HomeMessage.limit(further),
      );
      expect(pick(limits: [close, limit(4, 5000)]), HomeMessage.limit(close));
    });

    test('a limit closed today stays closed until tomorrow or over', () {
      final close = limit(1, 9500);
      final key = HomeMessages.limitKey(close);

      expect(
        pick(limits: [close], dismissed: {key: DateTime(2026, 10, 13)}),
        isNull,
      );
      expect(
        pick(limits: [close], dismissed: {key: DateTime(2026, 10, 12)}),
        HomeMessage.limit(close),
      );
      final over = limit(1, 10500);
      expect(
        pick(limits: [over], dismissed: {key: DateTime(2026, 10, 13)}),
        HomeMessage.limit(over),
      );
    });

    test('without warnings, the first recap not closed yet, month first', () {
      final month = recap(period: LimitPeriod.month);
      final week = recap();

      expect(pick(recaps: [month, week]), HomeMessage.recap(month));
      expect(
        pick(
          recaps: [month, week],
          dismissed: {HomeMessages.recapKey(month): DateTime(2026, 10, 2)},
        ),
        HomeMessage.recap(week),
      );
    });

    test('a recap with nothing spent has nothing to say', () {
      expect(pick(recaps: [recap(spentMinor: 0)]), isNull);
    });
  });

  group('recap lines', () {
    test('a week: less, all limits kept, more, or the top category', () {
      expect(recap().line, RecapLine.weekLess);
      expect(
        recap(spentMinor: 60000, limitsKept: (kept: 3, of: 3)).line,
        RecapLine.weekLimitsKept,
      );
      expect(recap(spentMinor: 60000).line, RecapLine.weekMore);
      expect(recap(previousSpentMinor: 0).line, RecapLine.weekTopCategory);
    });

    test('a month: less, more, kept some income, or a summary', () {
      const month = LimitPeriod.month;
      expect(recap(period: month).line, RecapLine.monthLess);
      expect(recap(period: month, spentMinor: 60000).line, RecapLine.monthMore);
      expect(
        recap(period: month, previousSpentMinor: 0, incomeMinor: 275000).line,
        RecapLine.monthKept,
      );
      expect(
        recap(period: month, previousSpentMinor: 0).line,
        RecapLine.monthSummary,
      );
    });

    test('kept share and difference', () {
      final month = recap(
        period: LimitPeriod.month,
        spentMinor: 225000,
        incomeMinor: 275000,
      );
      expect(month.keptPercent, 18);
      expect(recap().differenceMinor, 4140);
    });
  });
}
