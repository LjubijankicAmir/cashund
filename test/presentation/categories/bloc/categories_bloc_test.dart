import 'dart:async';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/categories/bloc/categories_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoryRepository;

Category _category(int id, {bool archived = false}) => Category(
  id: id,
  type: TransactionType.expense,
  emoji: '🛒',
  color: CategoryColor.olive,
  sortOrder: id,
  isArchived: archived,
);

List<int> _ids(List<Category> categories) => [
  for (final category in categories) category.id,
];

void main() {
  final a = _category(1);
  final b = _category(2);
  final archived = _category(3, archived: true);
  final c = _category(4);
  final saved = [a, b, archived, c];

  late _MockCategories categories;

  setUpAll(() => registerFallbackValue(TransactionType.expense));

  setUp(() {
    categories = _MockCategories();
    when(() => categories.watchByType(TransactionType.expense))
        .thenAnswer((_) => Stream.value(right(saved)));
    when(() => categories.watchByType(TransactionType.income))
        .thenAnswer((_) => Stream.value(right(<Category>[])));
    when(() => categories.reorder(any(), any()))
        .thenAnswer((_) async => right(unit));
    when(() => categories.setArchived(any(), archived: any(named: 'archived')))
        .thenAnswer((_) async => right(unit));
  });

  Future<CategoriesBloc> opened() async {
    final bloc = CategoriesBloc(categories)
      ..add(const CategoriesEvent.typeSelected(TransactionType.expense));
    await pumpEventQueue();
    return bloc;
  }

  test('splits the categories into active and archived ones', () async {
    final bloc = await opened();

    expect(bloc.state.active, [a, b, c]);
    expect(bloc.state.archived, [archived]);
    await bloc.close();
  });

  test('switching type shows the other type only', () async {
    final bloc = await opened();

    bloc.add(const CategoriesEvent.typeSelected(TransactionType.income));
    await pumpEventQueue();

    expect(bloc.state.type, TransactionType.income);
    expect(bloc.state.categories, isEmpty);
    await bloc.close();
  });

  group('moveActive', () {
    test('moves among the active categories only', () {
      expect(_ids(CategoriesBloc.moveActive(saved, 2, 0)), [4, 1, 3, 2]);
      expect(_ids(CategoriesBloc.moveActive(saved, 0, 2)), [2, 4, 3, 1]);
    });
  });

  test('reordering shows the new order at once and saves it', () async {
    final updates = StreamController<Result<List<Category>>>();
    when(() => categories.watchByType(TransactionType.expense))
        .thenAnswer((_) => updates.stream);
    final bloc = CategoriesBloc(categories)
      ..add(const CategoriesEvent.typeSelected(TransactionType.expense));
    updates.add(right(saved));
    await pumpEventQueue();

    bloc.add(const CategoriesEvent.reordered(2, 0));
    await pumpEventQueue();

    expect(_ids(bloc.state.active), [4, 1, 2]);
    verify(() => categories.reorder(TransactionType.expense, [4, 1, 3, 2]))
        .called(1);
    await bloc.close();
    await updates.close();
  });

  test('archiving moves the category to the archived ones at once', () async {
    final bloc = await opened();

    bloc.add(CategoriesEvent.archived(b.id));
    await pumpEventQueue();

    expect(bloc.state.active, [a, c]);
    expect(_ids(bloc.state.archived), [2, 3]);
    verify(() => categories.setArchived(b.id, archived: true)).called(1);
    await bloc.close();
  });

  test('restoring saves the category as active', () async {
    final bloc = await opened();

    bloc.add(CategoriesEvent.restored(archived.id));
    await pumpEventQueue();

    expect(_ids(bloc.state.active), [1, 2, 3, 4]);
    verify(() => categories.setArchived(archived.id, archived: false))
        .called(1);
    await bloc.close();
  });

  test('a failed save shows the saved list again and reports it', () async {
    when(() => categories.setArchived(any(), archived: any(named: 'archived')))
        .thenAnswer((_) async => left(const Failure.database()));
    final bloc = await opened();

    bloc.add(CategoriesEvent.archived(b.id));
    await pumpEventQueue();

    expect(bloc.state.categories, saved);
    expect(bloc.state.saveFailed, isTrue);
    await bloc.close();
  });
}
