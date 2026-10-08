import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesRepository extends Mock implements PreferencesRepository;

void main() {
  late _MockPreferencesRepository preferences;

  setUpAll(() {
    registerFallbackValue(
      const UserPreferences(
        currencyCode: 'USD',
        buddyName: 'Biscuit',
        weekStart: WeekStart.monday,
        onboardingCompleted: false,
      ),
    );
  });

  setUp(() {
    preferences = _MockPreferencesRepository();
    when(() => preferences.save(any())).thenAnswer((_) async => right(unit));
  });

  OnboardingBloc build() => OnboardingBloc(preferences);

  blocTest<OnboardingBloc, OnboardingState>(
    'started seeds the region defaults',
    build: build,
    act: (bloc) => bloc.add(
      const OnboardingEvent.started(
        currencyCode: 'BAM',
        weekStart: WeekStart.sunday,
      ),
    ),
    expect: () => [
      const OnboardingState(currencyCode: 'BAM', weekStart: WeekStart.sunday),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'next and back move between steps',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingEvent.nextPressed())
      ..add(const OnboardingEvent.nextPressed())
      ..add(const OnboardingEvent.backPressed()),
    expect: () => [
      const OnboardingState(step: 1),
      const OnboardingState(step: 2),
      const OnboardingState(step: 1),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'steps stay within the first and last step',
    build: build,
    act: (bloc) async {
      bloc.add(const OnboardingEvent.backPressed());
      await pumpEventQueue();
      expect(bloc.state.step, 0);

      for (var i = 0; i < OnboardingState.stepCount + 2; i++) {
        bloc.add(const OnboardingEvent.nextPressed());
      }
    },
    verify: (bloc) => expect(bloc.state.step, OnboardingState.stepCount - 1),
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'finish saves the choices and completes',
    build: build,
    seed: () => const OnboardingState(
      step: 3,
      currencyCode: 'EUR',
      buddyName: '  Noodle ',
      weekStart: WeekStart.saturday,
    ),
    act: (bloc) => bloc.add(const OnboardingEvent.finishPressed()),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.status,
        'status',
        OnboardingStatus.saving,
      ),
      isA<OnboardingState>().having(
        (s) => s.status,
        'status',
        OnboardingStatus.completed,
      ),
    ],
    verify: (_) => verify(
      () => preferences.save(
        const UserPreferences(
          currencyCode: 'EUR',
          buddyName: 'Noodle',
          weekStart: WeekStart.saturday,
          onboardingCompleted: true,
        ),
      ),
    ).called(1),
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'skip keeps the defaults and falls back to the default buddy name',
    build: build,
    seed: () => const OnboardingState(step: 1, buddyName: '   '),
    act: (bloc) => bloc.add(const OnboardingEvent.skipPressed()),
    skip: 1,
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.status,
        'status',
        OnboardingStatus.completed,
      ),
    ],
    verify: (_) {
      final saved =
          verify(() => preferences.save(captureAny())).captured.single
              as UserPreferences;
      expect(saved.buddyName, UserPreferences.defaultBuddyName);
      expect(saved.onboardingCompleted, isTrue);
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'reports a failed save',
    build: () {
      when(() => preferences.save(any()))
          .thenAnswer((_) async => left(const Failure.database('disk full')));
      return build();
    },
    act: (bloc) => bloc.add(const OnboardingEvent.finishPressed()),
    skip: 1,
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.status,
        'status',
        OnboardingStatus.failure,
      ),
    ],
  );
}
