import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/transaction_form/bloc/transaction_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoryRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

Category _category(int id, TransactionType type) => Category(
  id: id,
  type: type,
  emoji: '🛒',
  color: CategoryColor.olive,
  sortOrder: id,
);

void main() {
  final today = DateTime(2026, 10, 8);
  final groceries = _category(1, TransactionType.expense);
  final eatingOut = _category(2, TransactionType.expense);
  final transport = _category(3, TransactionType.expense);
  final salary = _category(20, TransactionType.income);

  late _MockCategories categories;
  late _MockTransactions transactions;
  late _MockPreferences preferences;

  // `any()` needs a stand-in value for non-nullable parameter types.
  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    categories = _MockCategories();
    transactions = _MockTransactions();
    preferences = _MockPreferences();

    when(() => preferences.get()).thenAnswer(
      (_) async => right(
        const UserPreferences(
          currencyCode: 'EUR',
          buddyName: 'Biscuit',
          weekStart: WeekStart.monday,
          onboardingCompleted: true,
        ),
      ),
    );
    when(() => categories.watchActive(TransactionType.expense)).thenAnswer(
      (_) => Stream<Result<List<Category>>>.value(
        right([groceries, eatingOut, transport]),
      ),
    );
    when(
      () => categories.watchRecent(
        TransactionType.expense,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) =>
          Stream<Result<List<Category>>>.value(right([eatingOut, groceries])),
    );
    when(
      () => categories.watchActive(TransactionType.income),
    ).thenAnswer((_) => Stream<Result<List<Category>>>.value(right([salary])));
    when(
      () => categories.watchRecent(
        TransactionType.income,
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) => Stream<Result<List<Category>>>.value(right(<Category>[])),
    );
  });

  TransactionFormBloc build() {
    final clock = _MockClock();
    when(clock.now).thenReturn(today.add(const Duration(hours: 15)));
    return TransactionFormBloc(categories, transactions, preferences, clock);
  }

  Future<TransactionFormBloc> opened(TransactionType type) async {
    final bloc = build()..add(TransactionFormEvent.started(type));
    await pumpEventQueue();
    return bloc;
  }

  test('opens on today with the currency and the last used category', () async {
    final bloc = await opened(TransactionType.expense);

    expect(bloc.state.date, today);
    expect(bloc.state.currency, currencyByCode('EUR'));
    expect(bloc.state.selectedCategory, eatingOut);
    await bloc.close();
  });

  test(
    'switching type clears the category and follows the other lists',
    () async {
      final bloc = await opened(TransactionType.expense);

      bloc.add(const TransactionFormEvent.typeChanged(TransactionType.income));
      await pumpEventQueue();

      expect(bloc.state.type, TransactionType.income);
      expect(bloc.state.categories, [salary]);
      expect(bloc.state.selectedCategory, isNull);
      await bloc.close();
    },
  );

  test('cannot save without an amount above zero', () async {
    final bloc = await opened(TransactionType.expense);

    bloc.add(const TransactionFormEvent.amountChanged('0.'));
    await pumpEventQueue();
    bloc.add(const TransactionFormEvent.savePressed());
    await pumpEventQueue();

    expect(bloc.state.canSave, isFalse);
    verifyNever(
      () => transactions.add(
        type: any(named: 'type'),
        amountMinor: any(named: 'amountMinor'),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
        occurredOn: any(named: 'occurredOn'),
        title: any(named: 'title'),
      ),
    );
    await bloc.close();
  });

  test('saves the parsed amount with the chosen details', () async {
    when(
      () => transactions.add(
        type: any(named: 'type'),
        amountMinor: any(named: 'amountMinor'),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
        occurredOn: any(named: 'occurredOn'),
        title: any(named: 'title'),
      ),
    ).thenAnswer((_) async => right(unit));
    final bloc = await opened(TransactionType.expense);

    bloc
      ..add(const TransactionFormEvent.amountChanged('18.4'))
      ..add(TransactionFormEvent.categorySelected(transport.id))
      ..add(const TransactionFormEvent.titleChanged('Bus pass'))
      ..add(TransactionFormEvent.dateSelected(DateTime(2026, 10, 7, 9)))
      ..add(const TransactionFormEvent.savePressed());
    await pumpEventQueue();

    expect(bloc.state.status, TransactionFormStatus.saved);
    verify(
      () => transactions.add(
        type: TransactionType.expense,
        amountMinor: 1840,
        currencyCode: 'EUR',
        categoryId: transport.id,
        occurredOn: DateTime(2026, 10, 7),
        title: 'Bus pass',
      ),
    ).called(1);
    await bloc.close();
  });

  blocTest<TransactionFormBloc, TransactionFormState>(
    'reports a failed save',
    setUp: () => when(
      () => transactions.add(
        type: any(named: 'type'),
        amountMinor: any(named: 'amountMinor'),
        currencyCode: any(named: 'currencyCode'),
        categoryId: any(named: 'categoryId'),
        occurredOn: any(named: 'occurredOn'),
        title: any(named: 'title'),
      ),
    ).thenAnswer((_) async => left(const Failure.database('disk full'))),
    build: build,
    act: (bloc) async {
      bloc.add(const TransactionFormEvent.started(TransactionType.expense));
      await pumpEventQueue();
      bloc
        ..add(const TransactionFormEvent.amountChanged('5'))
        ..add(const TransactionFormEvent.savePressed());
    },
    verify: (bloc) => expect(bloc.state.status, TransactionFormStatus.failure),
  );

  group('editing', () {
    final lunch = Transaction(
      id: 7,
      type: TransactionType.expense,
      amountMinor: 1840,
      currencyCode: 'USD',
      categoryId: transport.id,
      title: 'Bus pass',
      occurredOn: DateTime(2026, 10, 6),
      createdAt: DateTime(2026, 10, 6, 9),
    );

    Future<TransactionFormBloc> editing() async {
      final bloc = build()..add(TransactionFormEvent.editStarted(lunch));
      await pumpEventQueue();
      return bloc;
    }

    test('fills the form from the transaction, in its own currency', () async {
      final bloc = await editing();

      expect(bloc.state.isEditing, isTrue);
      expect(bloc.state.amountText, '18.40');
      expect(bloc.state.currency, currencyByCode('USD'));
      expect(bloc.state.selectedCategory, transport);
      expect(
        (bloc.state.title, bloc.state.date),
        ('Bus pass', DateTime(2026, 10, 6)),
      );
      await bloc.close();
    });

    test('saving updates the transaction instead of adding one', () async {
      when(
        () => transactions.update(
          id: any(named: 'id'),
          type: any(named: 'type'),
          amountMinor: any(named: 'amountMinor'),
          categoryId: any(named: 'categoryId'),
          occurredOn: any(named: 'occurredOn'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => right(unit));
      final bloc = await editing();

      bloc
        ..add(const TransactionFormEvent.amountChanged('20'))
        ..add(const TransactionFormEvent.savePressed());
      await pumpEventQueue();

      expect(bloc.state.status, TransactionFormStatus.saved);
      verify(
        () => transactions.update(
          id: 7,
          type: TransactionType.expense,
          amountMinor: 2000,
          categoryId: transport.id,
          occurredOn: DateTime(2026, 10, 6),
          title: 'Bus pass',
        ),
      ).called(1);
      await bloc.close();
    });

    test('delete removes it and reports it', () async {
      when(() => transactions.delete(7)).thenAnswer((_) async => right(unit));
      final bloc = await editing();

      bloc.add(const TransactionFormEvent.deletePressed());
      await pumpEventQueue();

      expect(bloc.state.status, TransactionFormStatus.deleted);
      expect(bloc.state.original, lunch);
      await bloc.close();
    });

    test('there is nothing to delete while adding', () async {
      final bloc = await opened(TransactionType.expense);

      bloc.add(const TransactionFormEvent.deletePressed());
      await pumpEventQueue();

      verifyNever(() => transactions.delete(any()));
      await bloc.close();
    });
  });
}
