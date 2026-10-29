import 'dart:async';
import 'dart:convert';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/home_screen_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/presentation/home_widgets/widget_snapshot.dart';
import 'package:cashund/presentation/home_widgets/widget_snapshot_builder.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Keeps the home-screen widgets up to date while the app runs: whenever
/// something they show changes, it hands them a new snapshot.
@lazySingleton
class WidgetSync {
  WidgetSync(
    this._preferences,
    this._transactions,
    this._limits,
    this._homeScreen,
    this._clock,
    this._l10n,
  );

  final PreferencesRepository _preferences;
  final TransactionRepository _transactions;
  final LimitRepository _limits;
  final HomeScreenRepository _homeScreen;
  final Clock _clock;
  final AppLocalizations _l10n;

  /// Changes that come together, like a save that touches several totals,
  /// make one snapshot.
  static const settle = Duration(milliseconds: 300);

  /// What the widgets show before onboarding, or after deleting everything.
  static final String _nothing = jsonEncode(
    const WidgetSnapshot(entries: []).toJson(),
  );

  StreamSubscription<void>? _preferencesSubscription;
  AppLifecycleListener? _lifecycle;
  final _subscriptions = <StreamSubscription<void>>[];
  Timer? _settling;
  String? _shown;

  UserPreferences? _current;
  bool? _hasTransactions;
  PeriodSummary? _today;
  PeriodSummary? _week;
  List<CategorySpending>? _weekSpending;
  List<LimitProgress>? _weekLimits;
  List<LimitProgress>? _monthLimits;

  void start() {
    _preferencesSubscription ??= _preferences.watch().listen((result) {
      final preferences = result.getOrElse((_) => null);
      if (preferences == null || !preferences.onboardingCompleted) {
        _current = null;
        _stopWatching();
        unawaited(_show(_nothing));
        return;
      }
      final previous = _current;
      _current = preferences;
      if (previous?.currencyCode != preferences.currencyCode ||
          previous?.weekStart != preferences.weekStart) {
        _watch();
      }
    });
    // Back in the app on another day, today and maybe the week moved on.
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        if (_current != null) _watch();
      },
    );
  }

  /// Watches everything the widgets show, for the periods around now.
  void _watch() {
    _stopWatching();
    final preferences = _current!;
    final code = preferences.currencyCode;
    final now = _clock.now();
    final day = Period.day.rangeContaining(
      now,
      weekStart: preferences.weekStart,
    );
    final week = Period.week.rangeContaining(
      now,
      weekStart: preferences.weekStart,
    );
    final month = Period.month.rangeContaining(
      now,
      weekStart: preferences.weekStart,
    );

    void follow<T>(Stream<T> stream, void Function(T value) keep) =>
        _subscriptions.add(
          stream.listen((value) {
            keep(value);
            _settling?.cancel();
            _settling = Timer(settle, _update);
          }),
        );

    follow(_transactions.watchCountInCurrency(code), (result) {
      result.map((count) => _hasTransactions = count > 0);
    });
    follow(_transactions.watchSummary(day, currencyCode: code), (result) {
      result.map((summary) => _today = summary);
    });
    follow(_transactions.watchSummary(week, currencyCode: code), (result) {
      result.map((summary) => _week = summary);
    });
    follow(
      _transactions.watchSpendingByCategory(week, currencyCode: code),
      (result) => result.map((spending) => _weekSpending = spending),
    );
    follow(
      _limits.watchProgress(
        period: LimitPeriod.week,
        currencyCode: code,
        range: week,
      ),
      (result) => result.map((limits) => _weekLimits = limits),
    );
    follow(
      _limits.watchProgress(
        period: LimitPeriod.month,
        currencyCode: code,
        range: month,
      ),
      (result) => result.map((limits) => _monthLimits = limits),
    );
  }

  void _stopWatching() {
    _settling?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _hasTransactions = _today = _week = null;
    _weekSpending = _weekLimits = _monthLimits = null;
  }

  /// Hands the widgets a new snapshot once everything has loaded.
  void _update() {
    if ((
          _current,
          _hasTransactions,
          _today,
          _week,
          _weekSpending,
          _weekLimits,
          _monthLimits,
        )
        case (
          final preferences?,
          final hasTransactions?,
          final today?,
          final week?,
          final weekSpending?,
          final weekLimits?,
          final monthLimits?,
        )) {
      final snapshot = WidgetSnapshotBuilder.build((
        now: _clock.now(),
        currency:
            currencyByCode(preferences.currencyCode) ??
            supportedCurrencies.first,
        weekStart: preferences.weekStart,
        hasTransactions: hasTransactions,
        today: today,
        week: week,
        weekTopCategory: weekSpending.firstOrNull?.category,
        weekLimits: weekLimits,
        monthLimits: monthLimits,
      ), _l10n);
      unawaited(_show(jsonEncode(snapshot.toJson())));
    }
  }

  /// Hands [json] to the widgets, unless they show it already.
  Future<void> _show(String json) async {
    if (json == _shown) return;
    _shown = json;
    final result = await _homeScreen.showOnWidgets(json);
    // Tried again with the next change.
    if (result.isLeft()) _shown = null;
  }

  @disposeMethod
  Future<void> dispose() async {
    _stopWatching();
    _lifecycle?.dispose();
    await _preferencesSubscription?.cancel();
  }
}
