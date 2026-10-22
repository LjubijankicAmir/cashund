import 'dart:async';

import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/dismissed_message_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/home_messages.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/home/bloc/home_message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockLimits extends Mock implements LimitRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockDismissed extends Mock implements DismissedMessageRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // Tuesday, a few days into a new week and well into October.
  final today = DateTime(2026, 10, 13, 9);
  final thisWeek = DateRange(
    start: DateTime(2026, 10, 12),
    end: DateTime(2026, 10, 19),
  );
  final lastWeek = DateRange(start: DateTime(2026, 10, 5), end: thisWeek.start);
  final weekBefore = DateRange(
    start: DateTime(2026, 9, 28),
    end: lastWeek.start,
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
  );
  LimitProgress limit(int spentMinor) => LimitProgress(
    limit: SpendingLimit(
      id: 3,
      period: LimitPeriod.week,
      currencyCode: 'USD',
      createdAt: DateTime(2026, 9),
      categoryId: groceries.id,
    ),
    category: groceries,
    range: thisWeek,
    amountMinor: 10000,
    spentMinor: spentMinor,
  );

  late _MockLimits limits;
  late _MockDismissed dismissed;
  late StreamController<Result<Map<String, DateTime>>> dismissals;
  late List<LimitProgress> currentLimits;

  setUpAll(() {
    registerFallbackValue(thisWeek);
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    currentLimits = [];
    limits = _MockLimits();
    when(
      () => limits.watchProgress(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        range: any(named: 'range'),
      ),
    ).thenAnswer(
      (invocation) => Stream.value(
        right(
          invocation.namedArguments[#range] == thisWeek
              ? currentLimits
              : <LimitProgress>[],
        ),
      ),
    );
    dismissed = _MockDismissed();
    dismissals = StreamController();
    when(dismissed.watchAll).thenAnswer((_) => dismissals.stream);
    when(() => dismissed.dismiss(any(), any()))
        .thenAnswer((_) async => right(unit));
  });
  // Closing a stream nobody listened to never completes.
  tearDown(() => dismissals.hasListener ? dismissals.close() : null);

  Future<HomeMessageBloc> opened() async {
    final transactions = _MockTransactions();
    when(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((invocation) {
      final range = invocation.positionalArguments.first as DateRange;
      return Stream.value(
        right(switch (range) {
          _ when range == lastWeek => const PeriodSummary(
            expenseMinor: 46890,
            transactionCount: 9,
          ),
          _ when range == weekBefore => const PeriodSummary(
            expenseMinor: 51030,
            transactionCount: 11,
          ),
          _ => const PeriodSummary(),
        }),
      );
    });
    when(
      () => transactions.watchSpendingByCategory(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right([
          const CategorySpending(category: groceries, amountMinor: 17280),
        ]),
      ),
    );
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
    final bloc = HomeMessageBloc(
      limits,
      transactions,
      preferences,
      dismissed,
      clock,
    )..add(const HomeMessageEvent.started());
    dismissals.add(right({}));
    await pumpEventQueue();
    return bloc;
  }

  test('recaps last week against the week before', () async {
    final bloc = await opened();

    final message = bloc.state.message;
    expect(message, isA<RecapMessage>());
    final recap = (message! as RecapMessage).recap;
    expect(recap.range, lastWeek);
    expect((recap.spentMinor, recap.previousSpentMinor), (46890, 51030));
    expect(recap.top?.category, groceries);
    expect(recap.line, RecapLine.weekLess);
    await bloc.close();
  });

  test('a limit close to its end comes before the recap', () async {
    currentLimits = [limit(9000)];
    final bloc = await opened();

    expect(bloc.state.message, HomeMessage.limit(limit(9000)));
    await bloc.close();
  });

  test('closing a message remembers it for today', () async {
    currentLimits = [limit(9000)];
    final bloc = await opened();

    bloc.add(HomeMessageEvent.closed(HomeMessage.limit(limit(9000))));
    await pumpEventQueue();

    verify(() => dismissed.dismiss('limit:3:near', today)).called(1);
    await bloc.close();
  });

  test('shows nothing until it knows what was already closed', () {
    final state = HomeMessageState(
      today: today,
      preferences: const UserPreferences(
        currencyCode: 'USD',
        buddyName: 'Biscuit',
        weekStart: WeekStart.monday,
        onboardingCompleted: true,
      ),
      limits: {
        LimitPeriod.week: [limit(9000)],
      },
    );

    expect(state.message, isNull);
    expect(
      state.copyWith(dismissed: {}).message,
      HomeMessage.limit(limit(9000)),
    );
  });
}
