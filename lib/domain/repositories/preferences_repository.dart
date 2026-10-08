import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PreferencesRepository {
  /// The saved preferences, or `null` before onboarding has saved any.
  FutureResult<UserPreferences?> get();

  /// Emits the current preferences and again on every change.
  StreamResult<UserPreferences?> watch();

  FutureResult<Unit> save(UserPreferences preferences);
}
