import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/home/bloc/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesRepository extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // Thursday.
  final today = DateTime(2026, 10, 8, 9);
  const preferences = UserPreferences(
    currencyCode: 'EUR',
    buddyName: 'Noodle',
    weekStart: WeekStart.sunday,
    onboardingCompleted: true,
  );

  late _MockPreferencesRepository repository;
  late _MockClock clock;

  setUp(() {
    repository = _MockPreferencesRepository();
    clock = _MockClock();
    when(clock.now).thenReturn(today);
  });

  HomeBloc build() => HomeBloc(repository, clock);

  blocTest<HomeBloc, HomeState>(
    'follows the saved preferences',
    setUp: () => when(repository.watch).thenAnswer(
      (_) => Stream<Result<UserPreferences?>>.fromIterable([
        right(preferences),
        right(preferences.copyWith(buddyName: 'Waffles')),
      ]),
    ),
    build: build,
    act: (bloc) => bloc.add(const HomeEvent.started()),
    expect: () => [
      HomeState(today: today, preferences: preferences),
      HomeState(
        today: today,
        preferences: preferences.copyWith(buddyName: 'Waffles'),
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'keeps what it has when a read fails',
    setUp: () => when(repository.watch).thenAnswer(
      (_) => Stream<Result<UserPreferences?>>.fromIterable([
        right(preferences),
        left(const Failure.database('locked')),
      ]),
    ),
    build: build,
    act: (bloc) => bloc.add(const HomeEvent.started()),
    expect: () => [HomeState(today: today, preferences: preferences)],
  );

  blocTest<HomeBloc, HomeState>(
    'switches the period',
    build: build,
    act: (bloc) => bloc.add(const HomeEvent.periodSelected(Period.month)),
    expect: () => [HomeState(today: today, period: Period.month)],
  );

  blocTest<HomeBloc, HomeState>(
    'remembers that the buddy message was closed',
    build: build,
    act: (bloc) => bloc.add(const HomeEvent.buddyMessageDismissed()),
    expect: () => [HomeState(today: today, buddyMessageDismissed: true)],
  );

  test('covers the week around today, starting on the chosen day', () {
    final state = HomeState(today: today, preferences: preferences);

    expect(
      state.range,
      DateRange(start: DateTime(2026, 10, 4), end: DateTime(2026, 10, 11)),
    );
  });

  test('has no range before the preferences are loaded', () {
    expect(HomeState(today: today).range, isNull);
  });
}
