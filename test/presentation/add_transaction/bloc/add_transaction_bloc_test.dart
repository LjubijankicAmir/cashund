import 'package:bloc_test/bloc_test.dart';
import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/add_transaction/bloc/add_transaction_bloc.dart';
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

  AddTransactionBloc build() {
    final clock = _MockClock();
    when(clock.now).thenReturn(today.add(const Duration(hours: 15)));
    return AddTransactionBloc(categories, transactions, preferences, clock);
  }

  Future<AddTransactionBloc> opened(TransactionType type) async {
    final bloc = build()..add(AddTransactionEvent.started(type));
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

      bloc.add(const AddTransactionEvent.typeChanged(TransactionType.income));
      await pumpEventQueue();

      expect(bloc.state.type, TransactionType.income);
      expect(bloc.state.categories, [salary]);
      expect(bloc.state.selectedCategory, isNull);
      await bloc.close();
    },
  );

  test('cannot save without an amount above zero', () async {
    final bloc = await opened(TransactionType.expense);

    bloc.add(const AddTransactionEvent.amountChanged('0.'));
    await pumpEventQueue();
    bloc.add(const AddTransactionEvent.savePressed());
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
      ..add(const AddTransactionEvent.amountChanged('18.4'))
      ..add(AddTransactionEvent.categorySelected(transport.id))
      ..add(const AddTransactionEvent.titleChanged('Bus pass'))
      ..add(AddTransactionEvent.dateSelected(DateTime(2026, 10, 7, 9)))
      ..add(const AddTransactionEvent.savePressed());
    await pumpEventQueue();

    expect(bloc.state.status, AddTransactionStatus.saved);
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

  blocTest<AddTransactionBloc, AddTransactionState>(
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
      bloc.add(const AddTransactionEvent.started(TransactionType.expense));
      await pumpEventQueue();
      bloc
        ..add(const AddTransactionEvent.amountChanged('5'))
        ..add(const AddTransactionEvent.savePressed());
    },
    verify: (bloc) => expect(bloc.state.status, AddTransactionStatus.failure),
  );
}
