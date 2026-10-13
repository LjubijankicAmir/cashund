import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/activity/bloc/activity_bloc.dart';
import 'package:cashund/presentation/activity/bloc/activity_filters_bloc.dart';
import 'package:cashund/presentation/activity/date_preset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository;

class _MockCategories extends Mock implements CategoryRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockClock extends Mock implements Clock;

void main() {
  // Thursday.
  final today = DateTime(2026, 10, 8);
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
  const preferences = UserPreferences(
    currencyCode: 'EUR',
    buddyName: 'Biscuit',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: 0,
  );
  const salary = Category(
    id: 20,
    type: TransactionType.income,
    emoji: '💼',
    color: CategoryColor.teal,
    sortOrder: 0,
  );

  late _MockTransactions transactions;
  late _MockCategories categories;
  late _MockPreferences preferencesRepository;
  late _MockClock clock;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    transactions = _MockTransactions();
    categories = _MockCategories();
    preferencesRepository = _MockPreferences();
    clock = _MockClock();
    when(clock.now).thenReturn(today.add(const Duration(hours: 10)));
    when(preferencesRepository.get).thenAnswer((_) async => right(preferences));
    when(preferencesRepository.watch)
        .thenAnswer((_) => Stream.value(right(preferences)));
    when(() => transactions.watchFiltered(any())).thenAnswer(
      (_) =>
          Stream<Result<List<TransactionWithCategory>>>.value(right(const [])),
    );
    when(() => categories.watchActive(TransactionType.expense)).thenAnswer(
      (_) => Stream<Result<List<Category>>>.value(right(const [groceries])),
    );
    when(() => categories.watchActive(TransactionType.income)).thenAnswer(
      (_) => Stream<Result<List<Category>>>.value(right(const [salary])),
    );
  });

  group('ActivityBloc', () {
    test('starts on all time and follows a new filter', () async {
      final bloc = ActivityBloc(transactions, preferencesRepository, clock)
        ..add(const ActivityEvent.started());
      await pumpEventQueue();

      expect(bloc.state.entries, isEmpty);
      expect(bloc.state.preferences, preferences);
      verify(() => transactions.watchFiltered(const TransactionFilter()))
          .called(1);

      bloc.add(ActivityEvent.filterChanged(TransactionFilter(range: october)));
      await pumpEventQueue();

      verify(
        () => transactions.watchFiltered(TransactionFilter(range: october)),
      ).called(1);
      await bloc.close();
    });

    test('keeps the search text', () async {
      final bloc = ActivityBloc(transactions, preferencesRepository, clock)
        ..add(const ActivityEvent.searchChanged('sushi'));
      await pumpEventQueue();

      expect(bloc.state.query, 'sushi');
      await bloc.close();
    });
  });

  group('swiping away', () {
    final lunch = Transaction(
      id: 7,
      type: TransactionType.expense,
      amountMinor: 1840,
      currencyCode: 'EUR',
      categoryId: groceries.id,
      occurredOn: today,
      createdAt: today,
    );

    setUp(() {
      registerFallbackValue(lunch);
      when(() => transactions.watchFiltered(any())).thenAnswer(
        (_) => Stream.value(
          right([
            TransactionWithCategory(transaction: lunch, category: groceries),
          ]),
        ),
      );
      when(() => transactions.restore(any()))
          .thenAnswer((_) async => right(unit));
    });

    Future<ActivityBloc> started() async {
      final bloc = ActivityBloc(transactions, preferencesRepository, clock)
        ..add(const ActivityEvent.started());
      await pumpEventQueue();
      return bloc;
    }

    test('hides the transaction at once and deletes it', () async {
      when(() => transactions.delete(7)).thenAnswer((_) async => right(unit));
      final bloc = await started();

      bloc.add(ActivityEvent.swipedAway(lunch));
      await pumpEventQueue();

      expect(bloc.state.shownEntries, isEmpty);
      verify(() => transactions.delete(7)).called(1);
      await bloc.close();
    });

    test('shows it again when the delete fails', () async {
      when(() => transactions.delete(7))
          .thenAnswer((_) async => left(const Failure.database('locked')));
      final bloc = await started();

      bloc.add(ActivityEvent.swipedAway(lunch));
      await pumpEventQueue();

      expect(bloc.state.shownEntries, hasLength(1));
      await bloc.close();
    });

    test('undo restores it and shows it again', () async {
      when(() => transactions.delete(7)).thenAnswer((_) async => right(unit));
      final bloc = await started();

      bloc.add(ActivityEvent.swipedAway(lunch));
      await pumpEventQueue();
      bloc.add(ActivityEvent.deletionUndone(lunch));
      await pumpEventQueue();

      verify(() => transactions.restore(lunch)).called(1);
      expect(bloc.state.hiddenIds, isEmpty);
      await bloc.close();
    });
  });

  group('ActivityFiltersBloc', () {
    Future<ActivityFiltersBloc> opened([
      TransactionFilter filter = const TransactionFilter(),
    ]) async {
      final bloc = ActivityFiltersBloc(
        categories,
        transactions,
        preferencesRepository,
        clock,
      )..add(ActivityFiltersEvent.started(filter));
      await pumpEventQueue();
      return bloc;
    }

    test('opens on the current filter and recognizes its preset', () async {
      final bloc = await opened(TransactionFilter(range: october));

      expect(bloc.state.draft.range, october);
      expect(bloc.state.preset, DatePreset.thisMonth);
      expect(bloc.state.categories, [groceries, salary]);
      await bloc.close();
    });

    test('picking a type drops categories of the other type', () async {
      final bloc = await opened(const TransactionFilter(categoryIds: {1, 20}));

      bloc.add(const ActivityFiltersEvent.typeChanged(TransactionType.income));
      await pumpEventQueue();

      expect(bloc.state.draft.categoryIds, {20});
      expect(bloc.state.categories, [salary]);
      await bloc.close();
    });

    test('tapping the chosen preset again goes back to all time', () async {
      final bloc = await opened();

      bloc.add(const ActivityFiltersEvent.presetSelected(DatePreset.thisMonth));
      await pumpEventQueue();
      expect(bloc.state.draft.range, october);

      bloc.add(const ActivityFiltersEvent.presetSelected(DatePreset.thisMonth));
      await pumpEventQueue();
      expect(bloc.state.draft.range, isNull);
      await bloc.close();
    });

    test(
      'a custom range includes its last day and stays at least a day long',
      () async {
        final bloc = await opened();

        bloc
          ..add(ActivityFiltersEvent.customFromChanged(DateTime(2026, 10, 2)))
          ..add(ActivityFiltersEvent.customToChanged(DateTime(2026, 10, 6)));
        await pumpEventQueue();
        expect(
          bloc.state.draft.range,
          DateRange(start: DateTime(2026, 10, 2), end: DateTime(2026, 10, 7)),
        );
        expect(bloc.state.preset, DatePreset.custom);

        bloc.add(
          ActivityFiltersEvent.customFromChanged(DateTime(2026, 10, 20)),
        );
        await pumpEventQueue();
        expect(
          bloc.state.draft.range,
          DateRange(start: DateTime(2026, 10, 20), end: DateTime(2026, 10, 21)),
        );
        await bloc.close();
      },
    );

    test('reset clears everything and the results follow the draft', () async {
      final bloc = await opened(
        TransactionFilter(
          type: TransactionType.expense,
          categoryIds: const {1},
          range: october,
        ),
      );

      bloc.add(const ActivityFiltersEvent.reset());
      await pumpEventQueue();

      expect(bloc.state.draft, const TransactionFilter());
      expect(bloc.state.preset, isNull);
      verify(() => transactions.watchFiltered(const TransactionFilter()))
          .called(1);
      await bloc.close();
    });
  });
}
