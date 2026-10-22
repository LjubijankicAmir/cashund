import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/insights/bloc/category_insights_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository;

class _MockLimits extends Mock implements LimitRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  final today = DateTime(2026, 10, 22, 9);
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
    predefinedKey: 'groceries',
  );
  LimitProgress limitOn(int categoryId, LimitPeriod period) => LimitProgress(
    limit: SpendingLimit(
      id: categoryId * 10 + period.index,
      period: period,
      currencyCode: 'USD',
      createdAt: DateTime(2026, 9),
      categoryId: categoryId,
    ),
    range: october,
    amountMinor: 20000,
    spentMinor: 14820,
  );
  Transaction bought(String currencyCode) => Transaction(
    id: currencyCode.hashCode,
    type: TransactionType.expense,
    amountMinor: 100,
    currencyCode: currencyCode,
    categoryId: groceries.id,
    occurredOn: DateTime(2026, 10, 3),
    createdAt: DateTime(2026, 10, 3),
  );

  late _MockTransactions transactions;
  late _MockLimits limits;

  setUpAll(() {
    registerFallbackValue(october);
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(const TransactionFilter());
  });

  setUp(() {
    transactions = _MockTransactions();
    limits = _MockLimits();
    when(
      () => transactions.watchExpensesByDay(
        any(),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right({
          DateTime(2026, 9, 5): 40000,
          DateTime(2026, 9, 25): 9000,
          DateTime(2026, 10, 3): 51240,
        }),
      ),
    );
    when(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        right(const PeriodSummary(expenseMinor: 224765, transactionCount: 30)),
      ),
    );
    when(() => transactions.watchFiltered(any())).thenAnswer(
      (_) => Stream.value(
        right([
          for (final code in ['USD', 'USD', 'EUR'])
            TransactionWithCategory(
              transaction: bought(code),
              category: groceries,
            ),
        ]),
      ),
    );
    when(
      () => limits.watchProgress(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        range: any(named: 'range'),
      ),
    ).thenAnswer(
      (invocation) => Stream.value(
        right([
          limitOn(
            groceries.id,
            invocation.namedArguments[#period] as LimitPeriod,
          ),
          limitOn(99, LimitPeriod.week),
        ]),
      ),
    );
  });

  Future<CategoryInsightsBloc> opened() async {
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
    final bloc = CategoryInsightsBloc(
      (category: groceries, period: InsightsPeriod.month, range: october),
      transactions,
      limits,
      preferences,
      clock,
    )..add(const CategoryInsightsEvent.started());
    await pumpEventQueue();
    return bloc;
  }

  test('what the category came to and its share of spending', () async {
    final bloc = await opened();

    expect(bloc.state.spentMinor, 51240);
    expect(bloc.state.sharePercent, 22);
    expect(bloc.state.transactionCount, 2);
    await bloc.close();
  });

  test('compares with September by this point', () async {
    final bloc = await opened();

    // September 25 is past the 22nd, so it doesn't count yet.
    expect(bloc.state.comparison, (current: 51240, previous: 40000));
    expect(bloc.state.trend, hasLength(6));
    await bloc.close();
  });

  test('shows only this category’s weekly and monthly limits', () async {
    final bloc = await opened();

    expect(
      {for (final limit in bloc.state.limits) limit.limit.period},
      {LimitPeriod.week, LimitPeriod.month},
    );
    expect(
      bloc.state.limits.every((l) => l.limit.categoryId == groceries.id),
      isTrue,
    );
    await bloc.close();
  });
}
