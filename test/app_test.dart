import 'package:cashund/app.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    configureDependencies();
    // Everything stays real except where the data lives.
    await getIt.unregister<AppDatabase>();
    getIt.registerSingleton(
      AppDatabase(NativeDatabase.memory()),
      dispose: (db) => db.close(),
    );
  });
  tearDown(getIt.reset);

  /// Renders at a real phone's size instead of the default 800×600.
  void usePhoneSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  PreferencesRepository preferences() => getIt<PreferencesRepository>();

  testWidgets('first launch opens onboarding', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CashundApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('opens Home once onboarding is done', (tester) async {
    await tester.runAsync(
      () => preferences().save(
        const UserPreferences(
          currencyCode: 'EUR',
          buddyName: 'Biscuit',
          weekStart: WeekStart.monday,
          onboardingCompleted: true,
        ),
      ),
    );

    await tester.pumpWidget(const CashundApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsNothing);
    expect(find.text('Cashund'), findsOneWidget);
  });

  testWidgets('going through onboarding saves the choices and opens Home', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CashundApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Euro'));
    await tester.tap(find.text('Euro'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Noodle');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunday'));
    await tester.tap(find.text('Start tracking'));
    await tester.pumpAndSettle();

    expect(find.text('Cashund'), findsOneWidget);
    final saved = await tester.runAsync(() => preferences().get());
    expect(
      saved!.getRight().toNullable(),
      const UserPreferences(
        currencyCode: 'EUR',
        buddyName: 'Noodle',
        weekStart: WeekStart.sunday,
        onboardingCompleted: true,
      ),
    );
  });

  testWidgets('back on the first step returns to the welcome screen', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(const CashundApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Which currency do you use?'), findsNothing);
  });
}
