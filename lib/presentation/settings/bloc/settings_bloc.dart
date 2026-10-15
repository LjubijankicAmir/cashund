import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'settings_bloc.freezed.dart';
part 'settings_event.dart';
part 'settings_state.dart';

/// Settings and its detail pages. Every change is saved right away.
@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._preferences, this._categories, this._transactions)
    : super(const SettingsState()) {
    on<_Started>(
      (event, emit) => Future.wait([
        emit.forEach(
          _preferences.watch(),
          onData: (result) {
            final next = state.copyWith(
              preferences: result.getRight().toNullable() ?? state.preferences,
            );
            _watchCountFor(next.preferences?.currencyCode);
            return next;
          },
        ),
        emit.forEach(
          _categories.watchActiveCounts(),
          onData: (result) => state.copyWith(
            categoryCounts:
                result.getRight().toNullable() ?? state.categoryCounts,
          ),
        ),
      ]),
    );
    on<_CurrencyCountWatched>(
      (event, emit) => emit.forEach(
        _transactions.watchCountInCurrency(event.currencyCode),
        onData: (result) => state.copyWith(
          transactionsInCurrency:
              result.getRight().toNullable() ?? state.transactionsInCurrency,
        ),
      ),
      // A new currency replaces the old subscription.
      transformer: restartable(),
    );
    on<_CurrencyChosen>(_onCurrencyChosen);
    on<_CurrencySwitchConfirmed>((event, emit) async {
      final code = state.pendingCurrencyCode;
      emit(state.copyWith(pendingCurrencyCode: null));
      if (code != null) {
        await _save(
          emit,
          (preferences) => preferences.copyWith(currencyCode: code),
        );
      }
    });
    on<_CurrencySwitchCancelled>(
      (event, emit) => emit(state.copyWith(pendingCurrencyCode: null)),
    );
    on<_WeekStartChosen>(
      (event, emit) => _save(
        emit,
        (preferences) => preferences.copyWith(weekStart: event.weekStart),
      ),
    );
    on<_ThemeChosen>(
      (event, emit) => _save(
        emit,
        (preferences) => preferences.copyWith(themePreference: event.theme),
      ),
    );
    on<_ReactionFrequencyChosen>(
      (event, emit) => _save(
        emit,
        (preferences) =>
            preferences.copyWith(reactionFrequency: event.frequency),
      ),
    );
    on<_ReactionIntervalChanged>(
      (event, emit) => _save(
        emit,
        (preferences) => preferences.copyWith(
          reactionInterval: event.interval.clamp(
            UserPreferences.minReactionInterval,
            UserPreferences.maxReactionInterval,
          ),
        ),
      ),
    );
    on<_BuddyNameSaved>((event, emit) {
      final name = event.buddyName.trim();
      return _save(
        emit,
        (preferences) => preferences.copyWith(
          buddyName: name.isEmpty ? UserPreferences.defaultBuddyName : name,
        ),
      );
    });
  }

  final PreferencesRepository _preferences;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;

  /// The currency the count subscription follows, to restart it only when
  /// the currency changes.
  String? _countedCurrency;

  void _watchCountFor(String? currencyCode) {
    if (currencyCode == null || currencyCode == _countedCurrency) return;
    _countedCurrency = currencyCode;
    add(SettingsEvent.currencyCountWatched(currencyCode));
  }

  Future<void> _onCurrencyChosen(
    _CurrencyChosen event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state.preferences?.currencyCode;
    if (current == null || event.currencyCode == current) return;

    // With nothing logged in the old currency, there's nothing to warn about.
    if (state.transactionsInCurrency == 0) {
      await _save(
        emit,
        (preferences) => preferences.copyWith(currencyCode: event.currencyCode),
      );
    } else {
      emit(state.copyWith(pendingCurrencyCode: event.currencyCode));
    }
  }

  Future<void> _save(
    Emitter<SettingsState> emit,
    UserPreferences Function(UserPreferences) change,
  ) async {
    final preferences = state.preferences;
    if (preferences == null) return;

    emit(state.copyWith(status: SettingsStatus.saving));
    final result = await _preferences.save(change(preferences));
    emit(
      state.copyWith(
        status: result.isRight()
            ? SettingsStatus.saved
            : SettingsStatus.failure,
      ),
    );
  }
}
