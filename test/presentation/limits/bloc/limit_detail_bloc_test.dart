import 'dart:async';

import 'package:cashund/core/error/result.dart';
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
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/limits/bloc/limit_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockLimits extends Mock implements LimitRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  final today = DateTime(2026, 10, 8, 12);
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  const eatingOut = Category(
    id: 2,
    type: TransactionType.expense,
    emoji: '🍔',
    color: CategoryColor.apricot,
    sortOrder: 1,
    predefinedKey: 'eating_out',
  );
  final limit = SpendingLimit(
    id: 9,
    period: LimitPeriod.week,
    currencyCode: 'USD',
    createdAt: DateTime(2026, 9),
    categoryId: eatingOut.id,
  );
  Transaction lunch(String currencyCode) => Transaction(
    id: currencyCode.hashCode,
    type: TransactionType.expense,
    amountMinor: 1840,
    currencyCode: currencyCode,
    categoryId: eatingOut.id,
    occurredOn: DateTime(2026, 10, 6),
    createdAt: DateTime(2026, 10, 6, 12),
  );

  late _MockLimits limits;
  late _MockTransactions transactions;
  late StreamController<Result<SpendingLimit?>> limitUpdates;

  setUpAll(() {
    registerFallbackValue(week);
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(const TransactionFilter());
  });

  setUp(() {
    limits = _MockLimits();
    transactions = _MockTransactions();
    limitUpdates = StreamController();
    when(() => limits.watch(9)).thenAnswer((_) => limitUpdates.stream);
    when(() => limits.watchAmounts(9)).thenAnswer(
      (_) => Stream.value(
        right([
          LimitAmount(effectiveFrom: DateTime(2026, 9, 14), amountMinor: 10000),
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
      (_) => Stream.value(
        right([
          LimitProgress(
            limit: limit,
            category: eatingOut,
            range: week,
            amountMinor: 10000,
            spentMinor: 8640,
          ),
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
          DateTime(2026, 9, 8): 10800,
          DateTime(2026, 9, 15): 10800,
          DateTime(2026, 9, 22): 6500,
          DateTime(2026, 10, 6): 8640,
        }),
      ),
    );
    when(() => transactions.watchFiltered(any())).thenAnswer(
      (_) => Stream.value(
        right([
          TransactionWithCategory(
            transaction: lunch('USD'),
            category: eatingOut,
          ),
          TransactionWithCategory(
            transaction: lunch('EUR'),
            category: eatingOut,
          ),
        ]),
      ),
    );
  });
  tearDown(() => limitUpdates.close());

  Future<LimitDetailBloc> opened() async {
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
    final bloc = LimitDetailBloc(
      limit,
      limits,
      transactions,
      preferences,
      clock,
    )..add(const LimitDetailEvent.started());
    await pumpEventQueue();
    return bloc;
  }

  test('shows this period and the last five against the limit', () async {
    final bloc = await opened();

    expect(bloc.state.progress?.spentMinor, 8640);
    expect(
      [for (final r in bloc.state.history) r.spentMinor],
      [10800, 10800, 6500, 0, 8640],
    );
    // Sep 7 is before the limit; of Sep 14, 21 and 28, two stayed under.
    expect(bloc.state.kept, (kept: 2, of: 3));
    verify(
      () => transactions.watchExpensesByDay(
        DateRange(start: DateTime(2026, 9, 7), end: week.end),
        currencyCode: 'USD',
        categoryId: eatingOut.id,
      ),
    ).called(1);
    await bloc.close();
  });

  test('lists this period’s transactions in the limit’s currency', () async {
    final bloc = await opened();

    expect(
      [
        for (final entry in bloc.state.transactions)
          entry.transaction.currencyCode,
      ],
      ['USD'],
    );
    verify(
      () => transactions.watchFiltered(
        TransactionFilter(
          type: TransactionType.expense,
          categoryIds: {eatingOut.id},
          range: week,
        ),
      ),
    ).called(1);
    await bloc.close();
  });

  test('notices when the limit is deleted', () async {
    final bloc = await opened();

    limitUpdates.add(right(null));
    await pumpEventQueue();

    expect(bloc.state.isDeleted, isTrue);
    await bloc.close();
  });
}
