import 'dart:async';

import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// The app's light/dark mode, following the user's theme preference. Until
/// preferences load, or if reading them fails, it follows the system.
@injectable
class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit(PreferencesRepository preferences) : super(ThemeMode.system) {
    _subscription = preferences.watch().listen((result) {
      final preference = result.getRight().toNullable()?.themePreference;
      if (preference != null) emit(_modeFor(preference));
    });
  }

  late final StreamSubscription<void> _subscription;

  static ThemeMode _modeFor(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
