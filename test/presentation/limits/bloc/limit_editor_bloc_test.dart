import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/limits/bloc/limit_editor_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockLimits extends Mock implements LimitRepository;

class _MockCategories extends Mock implements CategoryRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // Thursday; the week runs Monday Oct 5 to Sunday Oct 11.
  final today = DateTime(2026, 10, 8, 12);
  final week = DateRange(
    start: DateTime(2026, 10, 5),
    end: DateTime(2026, 10, 12),
  );
  const pets = Category(
    id: 13,
    type: TransactionType.expense,
    emoji: '🐾',
    color: CategoryColor.cocoa,
    sortOrder: 12,
    predefinedKey: 'pets',
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
    predefinedKey: 'groceries',
  );
  final groceriesLimit = SpendingLimit(
    id: 5,
    period: LimitPeriod.week,
    currencyCode: 'USD',
    createdAt: DateTime(2026, 9),
    categoryId: groceries.id,
  );

  late _MockLimits limits;
  late _MockTransactions transactions;

  setUpAll(() {
    registerFallbackValue(week);
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    limits = _MockLimits();
    transactions = _MockTransactions();
    when(() => limits.watchAll('USD'))
        .thenAnswer((_) => Stream.value(right([groceriesLimit])));
    when(
      () => transactions.watchExpensesByDay(
        any(),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) => Stream.value(right({DateTime(2026, 10, 6): 4275})));
  });

  LimitEditorBloc build() {
    final categories = _MockCategories();
    when(() => categories.watchActive(TransactionType.expense))
        .thenAnswer((_) => Stream.value(right([groceries, pets])));
    final preferences = _MockPreferences();
    when(preferences.get).thenAnswer(
      (_) async => right(
        const UserPreferences(
          currencyCode: 'USD',
          buddyName: 'Biscuit',
          weekStart: WeekStart.monday,
          onboardingCompleted: true,
        ),
      ),
    );
    final clock = _MockClock();
    when(clock.now).thenReturn(today);
    return LimitEditorBloc(
      limits,
      categories,
      transactions,
      preferences,
      clock,
    );
  }

  Future<LimitEditorBloc> opened({LimitProgress? editing}) async {
    final bloc = build()
      ..add(
        LimitEditorEvent.started(period: LimitPeriod.week, editing: editing),
      );
    await pumpEventQueue();
    return bloc;
  }

  test('a category with a limit for the period is taken', () async {
    final bloc = await opened();

    expect(bloc.state.isTaken(const LimitTarget.category(groceries)), isTrue);
    expect(bloc.state.isTaken(const LimitTarget.category(pets)), isFalse);
    expect(bloc.state.isTaken(const LimitTarget.overall()), isFalse);

    bloc.add(const LimitEditorEvent.periodChanged(LimitPeriod.month));
    await pumpEventQueue();
    expect(bloc.state.isTaken(const LimitTarget.category(groceries)), isFalse);
    await bloc.close();
  });

  test('the preview shows this period’s spending against the amount', () async {
    final bloc = await opened();

    bloc
      ..add(const LimitEditorEvent.targetChosen(LimitTarget.category(pets)))
      ..add(const LimitEditorEvent.amountChanged('50'));
    await pumpEventQueue();

    final preview = bloc.state.preview!;
    expect((preview.spentMinor, preview.amountMinor), (4275, 5000));
    expect(preview.status, LimitStatus.near);
    verify(
      () => transactions.watchExpensesByDay(
        week,
        currencyCode: 'USD',
        categoryId: pets.id,
      ),
    ).called(1);
    await bloc.close();
  });

  test('saves a new limit from the start of this period', () async {
    when(
      () => limits.create(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
        amountMinor: any(named: 'amountMinor'),
        effectiveFrom: any(named: 'effectiveFrom'),
      ),
    ).thenAnswer((_) async => right(groceriesLimit));
    final bloc = await opened();

    expect(bloc.state.canSave, isFalse);
    bloc
      ..add(const LimitEditorEvent.targetChosen(LimitTarget.category(pets)))
      ..add(const LimitEditorEvent.amountChanged('50'))
      ..add(const LimitEditorEvent.savePressed());
    await pumpEventQueue();

    verify(
      () => limits.create(
        period: LimitPeriod.week,
        currencyCode: 'USD',
        categoryId: pets.id,
        amountMinor: 5000,
        effectiveFrom: week.start,
      ),
    ).called(1);
    expect(bloc.state.status, LimitEditorStatus.saved);
    await bloc.close();
  });

  test('cannot save a second limit on a taken category', () async {
    final bloc = await opened();

    bloc
      ..add(
        const LimitEditorEvent.targetChosen(LimitTarget.category(groceries)),
      )
      ..add(const LimitEditorEvent.amountChanged('50'));
    await pumpEventQueue();

    expect(bloc.state.canSave, isFalse);
    await bloc.close();
  });

  group('editing', () {
    final editing = LimitProgress(
      limit: groceriesLimit,
      category: groceries,
      range: week,
      amountMinor: 20000,
      spentMinor: 14820,
    );

    test('opens with its amount, and its category stays fixed', () async {
      final bloc = await opened(editing: editing);

      expect(bloc.state.amountText, '200.00');
      expect(bloc.state.canSave, isTrue);

      bloc.add(const LimitEditorEvent.targetChosen(LimitTarget.category(pets)));
      await pumpEventQueue();
      expect(bloc.state.target, const LimitTarget.category(groceries));
      await bloc.close();
    });

    test('a new amount applies from this period on', () async {
      when(
        () => limits.changeAmount(
          any(),
          amountMinor: any(named: 'amountMinor'),
          effectiveFrom: any(named: 'effectiveFrom'),
        ),
      ).thenAnswer((_) async => right(unit));
      final bloc = await opened(editing: editing);

      bloc
        ..add(const LimitEditorEvent.amountChanged('250'))
        ..add(const LimitEditorEvent.savePressed());
      await pumpEventQueue();

      verify(
        () => limits.changeAmount(
          5,
          amountMinor: 25000,
          effectiveFrom: week.start,
        ),
      ).called(1);
      await bloc.close();
    });

    test('delete hands back the limit for undo', () async {
      final snapshot = (limit: groceriesLimit, amounts: <LimitAmount>[]);
      when(() => limits.delete(5)).thenAnswer((_) async => right(snapshot));
      final bloc = await opened(editing: editing);

      bloc.add(const LimitEditorEvent.deletePressed());
      await pumpEventQueue();

      expect(bloc.state.status, LimitEditorStatus.deleted);
      expect(bloc.state.deleted, snapshot);
      await bloc.close();
    });

    test('a failed save is reported', () async {
      when(
        () => limits.changeAmount(
          any(),
          amountMinor: any(named: 'amountMinor'),
          effectiveFrom: any(named: 'effectiveFrom'),
        ),
      ).thenAnswer((_) async => left(const Failure.database()));
      final bloc = await opened(editing: editing);

      bloc.add(const LimitEditorEvent.savePressed());
      await pumpEventQueue();

      expect(bloc.state.status, LimitEditorStatus.failure);
      await bloc.close();
    });
  });
}
