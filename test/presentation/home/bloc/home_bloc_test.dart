import 'dart:async';

import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/home/bloc/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // Thursday.
  final today = DateTime(2026, 10, 8, 9);
  final sundayWeek = DateRange(
    start: DateTime(2026, 10, 4),
    end: DateTime(2026, 10, 11),
  );
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
  const preferences = UserPreferences(
    currencyCode: 'EUR',
    buddyName: 'Noodle',
    weekStart: WeekStart.sunday,
    onboardingCompleted: true,
  );
  const summary = PeriodSummary(
    incomeMinor: 1000,
    expenseMinor: 400,
    transactionCount: 2,
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
  );

  late StreamController<Result<UserPreferences?>> preferenceUpdates;
  late _MockTransactions transactions;
  late HomeBloc bloc;

  setUpAll(() => registerFallbackValue(sundayWeek));

  setUp(() {
    preferenceUpdates = StreamController();
    final preferencesRepository = _MockPreferences();
    when(preferencesRepository.watch)
        .thenAnswer((_) => preferenceUpdates.stream);

    transactions = _MockTransactions();
    when(transactions.watchHasAny).thenAnswer((_) => Stream.value(right(true)));
    when(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value(right(summary)));
    when(
      () => transactions.watchSpendingByCategory(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right([const CategorySpending(category: groceries, amountMinor: 400)]),
      ),
    );

    final clock = _MockClock();
    when(clock.now).thenReturn(today);
    bloc = HomeBloc(preferencesRepository, transactions, clock)
      ..add(const HomeEvent.started());
  });

  tearDown(() async {
    await bloc.close();
    await preferenceUpdates.close();
  });

  Future<void> loadPreferences([UserPreferences value = preferences]) async {
    preferenceUpdates.add(right(value));
    await pumpEventQueue();
  }

  test('loads the preferences and the current week', () async {
    await loadPreferences();

    expect(bloc.state.preferences, preferences);
    expect(bloc.state.range, sundayWeek);
    expect(bloc.state.hasTransactions, isTrue);
  });

  test(
    'follows the totals and spending of the period in the chosen currency',
    () async {
      await loadPreferences();

      expect(bloc.state.summary, summary);
      expect(bloc.state.slices.single.category, groceries);
      expect(bloc.state.slices.single.percent, 100);
      verify(() => transactions.watchSummary(sundayWeek, currencyCode: 'EUR'))
          .called(1);
    },
  );

  test('switching the period follows the new range', () async {
    await loadPreferences();

    bloc.add(const HomeEvent.periodSelected(Period.month));
    await pumpEventQueue();

    verify(() => transactions.watchSummary(october, currencyCode: 'EUR'))
        .called(1);
  });

  test('a renamed buddy keeps the same subscription', () async {
    await loadPreferences();
    await loadPreferences(preferences.copyWith(buddyName: 'Waffles'));

    expect(bloc.state.preferences?.buddyName, 'Waffles');
    verify(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).called(1);
  });

  test('remembers that the buddy message was closed', () async {
    bloc.add(const HomeEvent.buddyMessageDismissed());
    await pumpEventQueue();

    expect(bloc.state.buddyMessageDismissed, isTrue);
  });

  test('has no range before the preferences are loaded', () {
    expect(HomeState(today: today).range, isNull);
  });
}
