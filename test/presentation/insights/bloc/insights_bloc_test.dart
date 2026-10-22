import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/insights/bloc/insights_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // October 22: 22 days into the month.
  final today = DateTime(2026, 10, 22, 9);
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
  final september = DateRange(
    start: DateTime(2026, 9),
    end: DateTime(2026, 10),
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
  );

  late _MockTransactions transactions;

  setUpAll(() => registerFallbackValue(october));

  setUp(() {
    transactions = _MockTransactions();
    when(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (invocation) => Stream.value(
        right(
          invocation.positionalArguments.first == october
              ? const PeriodSummary(
                  incomeMinor: 275000,
                  expenseMinor: 224765,
                  transactionCount: 30,
                )
              : const PeriodSummary(),
        ),
      ),
    );
    when(
      () => transactions.watchSpendingByCategory(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right([
          const CategorySpending(category: groceries, amountMinor: 51240),
        ]),
      ),
    );
    when(
      () => transactions.watchExpensesByDay(
        any(),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right({
          DateTime(2026, 5, 10): 210000,
          // By September 22 and after it.
          DateTime(2026, 9, 10): 230000,
          DateTime(2026, 9, 28): 1000,
          DateTime(2026, 10, 3): 224765,
        }),
      ),
    );
    when(() => transactions.watchFirstDay(any()))
        .thenAnswer((_) => Stream.value(right(DateTime(2026, 5, 2))));
  });

  Future<InsightsBloc> opened(InsightsPeriod period) async {
    final preferences = _MockPreferences();
    when(preferences.watch).thenAnswer(
      (_) => Stream.value(
        right(
          const UserPreferences(
            currencyCode: 'USD',
            buddyName: 'Biscuit',
            weekStart: WeekStart.monday,
            onboardingCompleted: true,
          ),
        ),
      ),
    );
    final clock = _MockClock();
    when(clock.now).thenReturn(today);
    final bloc = InsightsBloc(transactions, preferences, clock)
      ..add(InsightsEvent.started(period));
    await pumpEventQueue();
    return bloc;
  }

  test('opens on the current period, so far', () async {
    final bloc = await opened(InsightsPeriod.month);

    expect(bloc.state.range, october);
    expect(bloc.state.isCurrent, isTrue);
    expect(bloc.state.canGoForward, isFalse);
    expect(bloc.state.canGoBack, isTrue);
    expect(bloc.state.slices.single.category, groceries);
    await bloc.close();
  });

  test('the trend covers 6 months, and the average skips empty ones', () async {
    final bloc = await opened(InsightsPeriod.month);

    expect(
      [for (final p in bloc.state.trend) p.totalMinor],
      [210000, 0, 0, 0, 231000, 224765],
    );
    expect(bloc.state.averageMinor, (210000 + 231000 + 224765) ~/ 3 + 1);
    await bloc.close();
  });

  test('a running month compares with the last one by this point', () async {
    final bloc = await opened(InsightsPeriod.month);

    // September 28 is past "by this point" (the 22nd).
    expect(bloc.state.comparison, (current: 224765, previous: 230000));
    await bloc.close();
  });

  test('steps back a period and forward again', () async {
    final bloc = await opened(InsightsPeriod.month);

    bloc.add(const InsightsEvent.previousPressed());
    await pumpEventQueue();
    expect(bloc.state.range, september);
    expect(bloc.state.isEmpty, isTrue);
    expect(bloc.state.canGoForward, isTrue);

    bloc.add(const InsightsEvent.nextPressed());
    await pumpEventQueue();
    expect(bloc.state.range, october);
    await bloc.close();
  });

  test('stops going back at the first period with data', () async {
    final bloc = await opened(InsightsPeriod.year);

    expect(bloc.state.canGoBack, isFalse);
    bloc.add(const InsightsEvent.previousPressed());
    await pumpEventQueue();
    expect(bloc.state.range?.start, DateTime(2026));
    expect(bloc.state.comparison, isNull);
    expect(bloc.state.monthsSoFar, 10);
    await bloc.close();
  });

  test('an empty period jumps to the current one', () async {
    final bloc = await opened(InsightsPeriod.month);

    bloc
      ..add(const InsightsEvent.previousPressed())
      ..add(const InsightsEvent.jumpedToData());
    await pumpEventQueue();

    expect(bloc.state.range, october);
    await bloc.close();
  });
}
