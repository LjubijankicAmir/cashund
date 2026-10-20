import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/limits/bloc/limits_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockLimits extends Mock implements LimitRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  final today = DateTime(2026, 10, 8, 12);
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));

  SpendingLimit limit(int id, {int? categoryId}) => SpendingLimit(
    id: id,
    period: LimitPeriod.week,
    currencyCode: 'USD',
    createdAt: DateTime(2026, 9),
    categoryId: categoryId,
  );
  LimitProgress progress(SpendingLimit limit, int spentMinor) => LimitProgress(
    limit: limit,
    range: week,
    amountMinor: 10000,
    spentMinor: spentMinor,
  );

  final overall = progress(limit(1), 6900);
  final groceries = progress(limit(2, categoryId: 7), 8640);

  late _MockLimits limits;

  setUpAll(() {
    registerFallbackValue(week);
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue((limit: limit(0), amounts: <LimitAmount>[]));
  });

  setUp(() {
    limits = _MockLimits();
    when(
      () => limits.watchProgress(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        range: any(named: 'range'),
      ),
    ).thenAnswer((_) => Stream.value(right([groceries, overall])));
    when(
      () => limits.watchAll(any()),
    ).thenAnswer((_) => Stream.value(right([groceries.limit, overall.limit])));
  });

  Future<LimitsBloc> opened(LimitPeriod period) async {
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
    final bloc = LimitsBloc(limits, preferences, clock)
      ..add(LimitsEvent.started(period));
    await pumpEventQueue();
    return bloc;
  }

  test('splits the overall limit from the category ones', () async {
    final bloc = await opened(LimitPeriod.week);

    expect(bloc.state.overall, overall);
    expect(bloc.state.byCategory, [groceries]);
    expect(bloc.state.limitCount, 2);
    verify(
      () => limits.watchProgress(
        period: LimitPeriod.week,
        currencyCode: 'USD',
        range: week,
      ),
    ).called(1);
    await bloc.close();
  });

  test('switching period follows that period’s range', () async {
    final bloc = await opened(LimitPeriod.week);

    bloc.add(const LimitsEvent.periodSelected(LimitPeriod.month));
    await pumpEventQueue();

    expect(bloc.state.period, LimitPeriod.month);
    verify(
      () => limits.watchProgress(
        period: LimitPeriod.month,
        currencyCode: 'USD',
        range: october,
      ),
    ).called(1);
    await bloc.close();
  });

  test('undo restores a deleted limit, and reports a failure', () async {
    final snapshot = (limit: groceries.limit, amounts: <LimitAmount>[]);
    when(() => limits.restore(any())).thenAnswer((_) async => right(unit));
    final bloc = await opened(LimitPeriod.week);

    bloc.add(LimitsEvent.restored(snapshot));
    await pumpEventQueue();
    verify(() => limits.restore(snapshot)).called(1);
    expect(bloc.state.restoreFailed, isFalse);

    when(() => limits.restore(any()))
        .thenAnswer((_) async => left(const Failure.database()));
    bloc.add(LimitsEvent.restored(snapshot));
    await pumpEventQueue();
    expect(bloc.state.restoreFailed, isTrue);
    await bloc.close();
  });
}
