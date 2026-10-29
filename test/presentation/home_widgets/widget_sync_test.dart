import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/home_screen_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/period_summary.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/home_widgets/widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockLimits extends Mock implements LimitRepository;

class _MockHomeScreen extends Mock implements HomeScreenRepository;

class _MockClock extends Mock implements Clock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 7, 14, 30);
  const preferences = UserPreferences(
    currencyCode: 'USD',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );

  late StreamController<Result<UserPreferences?>> preferenceUpdates;
  late StreamController<Result<PeriodSummary>> weekUpdates;
  late _MockPreferences preferencesRepository;
  late _MockTransactions transactions;
  late _MockLimits limits;
  late _MockHomeScreen homeScreen;
  late WidgetSync sync;

  setUpAll(() async {
    registerFallbackValue(DateRange(start: now, end: now));
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(<DateTime>[]);
    await initializeDateFormatting('en');
  });

  setUp(() {
    preferenceUpdates = StreamController();
    // Each switch of currency watches the week again.
    weekUpdates = StreamController.broadcast();
    preferencesRepository = _MockPreferences();
    transactions = _MockTransactions();
    limits = _MockLimits();
    homeScreen = _MockHomeScreen();
    final clock = _MockClock();

    when(clock.now).thenReturn(now);
    when(preferencesRepository.watch)
        .thenAnswer((_) => preferenceUpdates.stream);
    when(() => transactions.watchCountInCurrency(any()))
        .thenAnswer((_) => Stream.value(right(3)));
    when(
      () => transactions.watchSummary(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((invocation) {
      final range = invocation.positionalArguments.single as DateRange;
      // The day's summary is fixed; the week's comes as the test says.
      return range.lastDay == range.start
          ? Stream.value(
              right(
                const PeriodSummary(expenseMinor: 4275, transactionCount: 2),
              ),
            )
          : weekUpdates.stream;
    });
    when(
      () => transactions.watchSpendingByCategory(
        any(),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) => Stream.value(right(const [])));
    when(
      () => limits.watchProgress(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        range: any(named: 'range'),
      ),
    ).thenAnswer((_) => Stream.value(right(const [])));
    when(
      () => homeScreen.showOnWidgets(any(), redrawAt: any(named: 'redrawAt')),
    ).thenAnswer((_) async => right(unit));

    sync = WidgetSync(
      preferencesRepository,
      transactions,
      limits,
      homeScreen,
      clock,
      lookupAppLocalizations(const Locale('en')),
    );
  });

  tearDown(() async {
    await sync.dispose();
    await preferenceUpdates.close();
    await weekUpdates.close();
  });

  /// Lets the stream updates settle into a snapshot.
  Future<void> settled() => Future<void>.delayed(WidgetSync.settle * 2);

  List<Map<String, Object?>> shown() => [
    for (final json in verify(
      () => homeScreen.showOnWidgets(
        captureAny(),
        redrawAt: any(named: 'redrawAt'),
      ),
    ).captured)
      jsonDecode(json as String) as Map<String, Object?>,
  ];

  test('shows nothing before onboarding', () async {
    sync.start();
    preferenceUpdates.add(right(null));
    await settled();

    expect(shown().single['entries'], isEmpty);
    verifyNever(() => transactions.watchCountInCurrency(any()));
  });

  test('shows a snapshot once everything has loaded', () async {
    sync.start();
    preferenceUpdates.add(right(preferences));
    await settled();
    verifyNever(
      () => homeScreen.showOnWidgets(any(), redrawAt: any(named: 'redrawAt')),
    );

    weekUpdates.add(
      right(const PeriodSummary(expenseMinor: 41235, transactionCount: 9)),
    );
    await settled();

    final [json, redrawAt] = verify(
      () => homeScreen.showOnWidgets(
        captureAny(),
        redrawAt: captureAny(named: 'redrawAt'),
      ),
    ).captured;
    final snapshot = jsonDecode(json as String) as Map<String, Object?>;
    final entry = (snapshot['entries']! as List<Object?>).first! as Map;
    // Redrawn at midnight, when the week starts over and when the month does.
    expect(redrawAt, [
      DateTime(2026, 10, 8),
      DateTime(2026, 10, 12),
      DateTime(2026, 11),
    ]);
    expect((entry['spending']! as Map)['hero'], r'$412.35');
    expect((entry['today']! as Map)['hero'], r'−$42.75');
  });

  test('skips a snapshot the widgets show already', () async {
    sync.start();
    preferenceUpdates.add(right(preferences));
    const week = PeriodSummary(expenseMinor: 41235, transactionCount: 9);
    weekUpdates.add(right(week));
    await settled();
    weekUpdates.add(right(week));
    await settled();
    weekUpdates.add(
      right(const PeriodSummary(expenseMinor: 50000, transactionCount: 10)),
    );
    await settled();

    expect(shown(), hasLength(2));
  });

  test('follows the new currency after a switch', () async {
    sync.start();
    preferenceUpdates
      ..add(right(preferences))
      ..add(right(preferences.copyWith(buddyName: 'Noodle')))
      ..add(right(preferences.copyWith(currencyCode: 'EUR')));
    await settled();

    verify(() => transactions.watchCountInCurrency('USD')).called(1);
    verify(() => transactions.watchCountInCurrency('EUR')).called(1);
  });
}
