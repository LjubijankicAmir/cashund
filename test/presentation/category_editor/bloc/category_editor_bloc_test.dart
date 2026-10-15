import 'package:cashund/core/error/failure.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/category_editor/bloc/category_editor_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategories extends Mock implements CategoryRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

void main() {
  const groceries = Category(
    id: 1,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.coral,
    sortOrder: 0,
    predefinedKey: 'groceries',
  );
  const hobbies = Category(
    id: 2,
    type: TransactionType.expense,
    emoji: '🎨',
    color: CategoryColor.sky,
    sortOrder: 1,
    customName: 'Hobbies',
  );

  String builtInName(String key) => switch (key) {
    'groceries' => 'Groceries',
    _ => key,
  };

  late _MockCategories categories;
  late _MockPreferences preferences;

  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
    registerFallbackValue(CategoryColor.coral);
  });

  setUp(() {
    categories = _MockCategories();
    preferences = _MockPreferences();
    when(preferences.get).thenAnswer(
      (_) async => right(
        const UserPreferences(
          currencyCode: 'EUR',
          buddyName: 'Biscuit',
          weekStart: WeekStart.monday,
          onboardingCompleted: true,
        ),
      ),
    );
    when(() => categories.watchByType(TransactionType.expense))
        .thenAnswer((_) => Stream.value(right([groceries, hobbies])));
    when(
      () => categories.update(
        id: any(named: 'id'),
        customName: any(named: 'customName'),
        emoji: any(named: 'emoji'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async => right(unit));
    when(() => categories.setArchived(any(), archived: any(named: 'archived')))
        .thenAnswer((_) async => right(unit));
  });

  Future<CategoryEditorBloc> opened({Category? editing}) async {
    final bloc = CategoryEditorBloc(categories, preferences)
      ..add(
        CategoryEditorEvent.started(
          type: TransactionType.expense,
          builtInName: builtInName,
          editing: editing,
        ),
      );
    await pumpEventQueue();
    return bloc;
  }

  group('a new category', () {
    test('starts blank with the first emoji and a free color', () async {
      final bloc = await opened();

      expect(bloc.state.isNew, isTrue);
      expect(bloc.state.currencyCode, 'EUR');
      expect(bloc.state.name, isEmpty);
      expect(bloc.state.emoji, suggestedCategoryEmoji.first);
      // Coral and sky are taken.
      expect(bloc.state.color, CategoryColor.mustard);
      expect(bloc.state.canSave, isFalse);
      await bloc.close();
    });

    test('cannot take the name of another category', () async {
      final bloc = await opened();

      bloc.add(const CategoryEditorEvent.nameChanged(' groceries '));
      await pumpEventQueue();

      expect(bloc.state.isNameTaken, isTrue);
      expect(bloc.state.canSave, isFalse);
      await bloc.close();
    });

    test('saves the trimmed name, the emoji and the color', () async {
      const created = Category(
        id: 3,
        type: TransactionType.expense,
        emoji: '🎮',
        color: CategoryColor.plum,
        sortOrder: 2,
        customName: 'Games',
      );
      when(
        () => categories.create(
          type: any(named: 'type'),
          name: any(named: 'name'),
          emoji: any(named: 'emoji'),
          color: any(named: 'color'),
        ),
      ).thenAnswer((_) async => right(created));
      final bloc = await opened();

      bloc
        ..add(const CategoryEditorEvent.nameChanged('  Games '))
        ..add(const CategoryEditorEvent.emojiSelected('🎮'))
        ..add(const CategoryEditorEvent.colorSelected(CategoryColor.plum))
        ..add(const CategoryEditorEvent.savePressed());
      await pumpEventQueue();

      verify(
        () => categories.create(
          type: TransactionType.expense,
          name: 'Games',
          emoji: '🎮',
          color: CategoryColor.plum,
        ),
      ).called(1);
      expect(bloc.state.status, CategoryEditorStatus.saved);
      expect(bloc.state.saved, created);
      await bloc.close();
    });
  });

  group('a built-in category', () {
    test('opens with its translated name and keeps its emoji', () async {
      final bloc = await opened(editing: groceries);

      expect(bloc.state.isBuiltIn, isTrue);
      expect(bloc.state.name, 'Groceries');
      expect(bloc.state.isNameTaken, isFalse);

      bloc.add(const CategoryEditorEvent.emojiSelected('🍕'));
      await pumpEventQueue();
      expect(bloc.state.emoji, '🛒');
      await bloc.close();
    });

    test('a rename is saved as a custom name', () async {
      final bloc = await opened(editing: groceries);

      bloc
        ..add(const CategoryEditorEvent.nameChanged('Food'))
        ..add(const CategoryEditorEvent.savePressed());
      await pumpEventQueue();

      verify(
        () => categories.update(
          id: 1,
          customName: 'Food',
          emoji: '🛒',
          color: CategoryColor.coral,
        ),
      ).called(1);
      expect(bloc.state.status, CategoryEditorStatus.saved);
      await bloc.close();
    });

    test('its default name is saved as no custom name', () async {
      final bloc = await opened(
        editing: groceries.copyWith(customName: 'Food'),
      );

      bloc
        ..add(const CategoryEditorEvent.nameChanged('Groceries'))
        ..add(const CategoryEditorEvent.savePressed());
      await pumpEventQueue();

      verify(
        () => categories.update(
          id: 1,
          customName: null,
          emoji: '🛒',
          color: CategoryColor.coral,
        ),
      ).called(1);
      await bloc.close();
    });
  });

  test('archive archives the category being edited', () async {
    final bloc = await opened(editing: hobbies);

    bloc.add(const CategoryEditorEvent.archivePressed());
    await pumpEventQueue();

    verify(() => categories.setArchived(2, archived: true)).called(1);
    expect(bloc.state.status, CategoryEditorStatus.archived);
    await bloc.close();
  });

  test('a failed save is reported', () async {
    when(
      () => categories.update(
        id: any(named: 'id'),
        customName: any(named: 'customName'),
        emoji: any(named: 'emoji'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async => left(const Failure.database()));
    final bloc = await opened(editing: hobbies);

    bloc.add(const CategoryEditorEvent.savePressed());
    await pumpEventQueue();

    expect(bloc.state.status, CategoryEditorStatus.failure);
    await bloc.close();
  });
}
