import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockCategories extends Mock implements CategoryRepository;

class _MockTransactions extends Mock implements TransactionRepository;

void main() {
  const preferences = UserPreferences(
    currencyCode: 'USD',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );

  late _MockPreferences preferencesRepository;
  late _MockCategories categories;
  late _MockTransactions transactions;

  setUpAll(() => registerFallbackValue(preferences));

  setUp(() {
    preferencesRepository = _MockPreferences();
    categories = _MockCategories();
    transactions = _MockTransactions();
    when(preferencesRepository.watch)
        .thenAnswer((_) => Stream.value(right(preferences)));
    when(categories.watchActiveCounts)
        .thenAnswer((_) => Stream.value(right((expense: 14, income: 7))));
    when(() => transactions.watchCountInCurrency(any()))
        .thenAnswer((_) => Stream.value(right(23)));
    when(() => preferencesRepository.save(any()))
        .thenAnswer((_) async => right(unit));
  });

  SettingsBloc build() =>
      SettingsBloc(preferencesRepository, categories, transactions);

  /// Starts the bloc and waits until everything it shows has loaded.
  Future<SettingsBloc> started() async {
    final bloc = build()..add(const SettingsEvent.started());
    await bloc.stream.firstWhere(
      (state) =>
          state.preferences != null &&
          state.categoryCounts != null &&
          state.transactionsInCurrency > 0,
    );
    return bloc;
  }

  UserPreferences saved() =>
      verify(() => preferencesRepository.save(captureAny())).captured.last
          as UserPreferences;

  test('loads the preferences and the counts', () async {
    final bloc = await started();

    expect(bloc.state.preferences, preferences);
    expect(bloc.state.categoryCounts, (expense: 14, income: 7));
    expect(bloc.state.transactionsInCurrency, 23);
    verify(() => transactions.watchCountInCurrency('USD')).called(1);
    await bloc.close();
  });

  test('follows the count of the new currency after a switch', () async {
    final updates = StreamController<Result<UserPreferences?>>();
    when(preferencesRepository.watch).thenAnswer((_) => updates.stream);
    final bloc = build()..add(const SettingsEvent.started());

    updates.add(right(preferences));
    await pumpEventQueue();
    updates.add(right(preferences.copyWith(buddyName: 'Noodle')));
    await pumpEventQueue();
    updates.add(right(preferences.copyWith(currencyCode: 'EUR')));
    await pumpEventQueue();

    verify(() => transactions.watchCountInCurrency('USD')).called(1);
    verify(() => transactions.watchCountInCurrency('EUR')).called(1);
    await bloc.close();
    await updates.close();
  });

  group('choosing a currency', () {
    test('asks first when transactions exist in the current one', () async {
      final bloc = await started();

      bloc.add(const SettingsEvent.currencyChosen('EUR'));
      await pumpEventQueue();

      expect(bloc.state.pendingCurrencyCode, 'EUR');
      verifyNever(() => preferencesRepository.save(any()));
      await bloc.close();
    });

    test('switches after the user confirms', () async {
      final bloc = await started();

      bloc
        ..add(const SettingsEvent.currencyChosen('EUR'))
        ..add(const SettingsEvent.currencySwitchConfirmed());
      await pumpEventQueue();

      expect(saved().currencyCode, 'EUR');
      expect(bloc.state.pendingCurrencyCode, isNull);
      expect(bloc.state.status, SettingsStatus.saved);
      await bloc.close();
    });

    test('keeps the currency when the user backs out', () async {
      final bloc = await started();

      bloc
        ..add(const SettingsEvent.currencyChosen('EUR'))
        ..add(const SettingsEvent.currencySwitchCancelled());
      await pumpEventQueue();

      expect(bloc.state.pendingCurrencyCode, isNull);
      verifyNever(() => preferencesRepository.save(any()));
      await bloc.close();
    });

    test('switches right away when nothing is logged yet', () async {
      when(() => transactions.watchCountInCurrency(any()))
          .thenAnswer((_) => Stream.value(right(0)));
      final bloc = build()..add(const SettingsEvent.started());
      await pumpEventQueue();

      bloc.add(const SettingsEvent.currencyChosen('EUR'));
      await pumpEventQueue();

      expect(saved().currencyCode, 'EUR');
      expect(bloc.state.pendingCurrencyCode, isNull);
      await bloc.close();
    });

    test('ignores the currency already in use', () async {
      final bloc = await started();

      bloc.add(const SettingsEvent.currencyChosen('USD'));
      await pumpEventQueue();

      expect(bloc.state.pendingCurrencyCode, isNull);
      verifyNever(() => preferencesRepository.save(any()));
      await bloc.close();
    });
  });

  test('saves the week start and the theme', () async {
    final bloc = await started();

    bloc.add(const SettingsEvent.weekStartChosen(WeekStart.sunday));
    await pumpEventQueue();
    expect(saved().weekStart, WeekStart.sunday);

    bloc.add(const SettingsEvent.themeChosen(ThemePreference.dark));
    await pumpEventQueue();
    expect(saved().themePreference, ThemePreference.dark);
    await bloc.close();
  });

  test('saves how often the buddy reacts, within limits', () async {
    final bloc = await started();

    bloc.add(
      const SettingsEvent.reactionFrequencyChosen(ReactionFrequency.sometimes),
    );
    await pumpEventQueue();
    expect(saved().reactionFrequency, ReactionFrequency.sometimes);

    bloc.add(const SettingsEvent.reactionIntervalChanged(5));
    await pumpEventQueue();
    expect(saved().reactionInterval, 5);

    bloc.add(const SettingsEvent.reactionIntervalChanged(99));
    await pumpEventQueue();
    expect(saved().reactionInterval, UserPreferences.maxReactionInterval);
    await bloc.close();
  });

  test('saves a trimmed buddy name, or the default when blank', () async {
    final bloc = await started();

    bloc.add(const SettingsEvent.buddyNameSaved('  Noodle '));
    await pumpEventQueue();
    expect(saved().buddyName, 'Noodle');

    bloc.add(const SettingsEvent.buddyNameSaved('   '));
    await pumpEventQueue();
    expect(saved().buddyName, UserPreferences.defaultBuddyName);
    await bloc.close();
  });

  blocTest<SettingsBloc, SettingsState>(
    'reports a failed save',
    setUp: () =>
        when(() => preferencesRepository.save(any()))
            .thenAnswer((_) async => left(const Failure.database())),
    build: build,
    seed: () => const SettingsState(preferences: preferences),
    act: (bloc) =>
        bloc.add(const SettingsEvent.themeChosen(ThemePreference.light)),
    expect: () => [
      const SettingsState(
        preferences: preferences,
        status: SettingsStatus.saving,
      ),
      const SettingsState(
        preferences: preferences,
        status: SettingsStatus.failure,
      ),
    ],
  );
}
