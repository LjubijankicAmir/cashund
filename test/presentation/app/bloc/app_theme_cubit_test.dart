import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/app/bloc/app_theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements PreferencesRepository;

void main() {
  const preferences = UserPreferences(
    currencyCode: 'EUR',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );

  late StreamController<Result<UserPreferences?>> updates;
  late _MockPreferences repository;

  setUp(() {
    updates = StreamController();
    repository = _MockPreferences();
    when(repository.watch).thenAnswer((_) => updates.stream);
  });
  tearDown(() => updates.close());

  test('follows the system until preferences load', () {
    expect(AppThemeCubit(repository).state, ThemeMode.system);
  });

  blocTest<AppThemeCubit, ThemeMode>(
    'follows every change of the theme preference',
    build: () => AppThemeCubit(repository),
    act: (_) async {
      updates.add(
        right(preferences.copyWith(themePreference: ThemePreference.dark)),
      );
      await Future<void>.delayed(Duration.zero);
      updates.add(
        right(preferences.copyWith(themePreference: ThemePreference.light)),
      );
      await Future<void>.delayed(Duration.zero);
      updates.add(right(preferences));
    },
    expect: () => [ThemeMode.dark, ThemeMode.light, ThemeMode.system],
  );

  blocTest<AppThemeCubit, ThemeMode>(
    'keeps the current mode when preferences are missing or fail to load',
    build: () => AppThemeCubit(repository),
    act: (_) {
      updates
        ..add(right(null))
        ..add(left(const Failure.database()));
    },
    expect: () => <ThemeMode>[],
  );
}
