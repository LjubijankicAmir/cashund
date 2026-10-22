import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/reaction/bloc/reaction_cubit.dart';
import 'package:cashund/presentation/reaction/limit_line.dart';
import 'package:cashund/presentation/reaction/reaction_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository;

class _MockPreferences extends Mock implements PreferencesRepository;

class _MockLimits extends Mock implements LimitRepository;

class _MockClock extends Mock implements Clock;

void main() {
  const pets = Category(
    id: 13,
    type: TransactionType.expense,
    emoji: '🐾',
    color: CategoryColor.cocoa,
    sortOrder: 12,
    predefinedKey: 'pets',
  );
  final dogFood = Transaction(
    id: 1,
    type: TransactionType.expense,
    amountMinor: 4275,
    currencyCode: 'USD',
    categoryId: pets.id,
    occurredOn: DateTime(2026, 10, 8),
    createdAt: DateTime(2026, 10, 8, 12),
    title: 'Dog food',
  );

  const settings = UserPreferences(
    currencyCode: 'USD',
    buddyName: 'Noodle',
    weekStart: WeekStart.monday,
    onboardingCompleted: true,
  );

  late _MockPreferences preferences;
  late _MockTransactions transactions;
  late _MockLimits limits;
  late _MockClock clock;

  /// What the pets limit stands at after the save, $42.75 more than before.
  var petsSpent = 0;

  void prefer(ReactionFrequency frequency, {int interval = 3}) {
    when(preferences.get).thenAnswer(
      (_) async => right(
        settings.copyWith(
          reactionFrequency: frequency,
          reactionInterval: interval,
        ),
      ),
    );
  }

  setUp(() {
    preferences = _MockPreferences();
    transactions = _MockTransactions();
    when(preferences.get).thenAnswer((_) async => right(settings));
    clock = _MockClock();
    when(clock.now).thenReturn(DateTime(2026, 10, 8, 12));
    petsSpent = 0;
    limits = _MockLimits();
    when(
      () => limits.watchProgress(
        period: any(named: 'period'),
        currencyCode: any(named: 'currencyCode'),
        range: any(named: 'range'),
      ),
    ).thenAnswer(
      (invocation) => Stream.value(
        right([
          if (invocation.namedArguments[#period] == LimitPeriod.week)
            LimitProgress(
              limit: SpendingLimit(
                id: 4,
                period: LimitPeriod.week,
                currencyCode: 'USD',
                createdAt: DateTime(2026, 9),
                categoryId: pets.id,
              ),
              category: pets,
              range: invocation.namedArguments[#range] as DateRange,
              amountMinor: 5000,
              spentMinor: petsSpent,
            ),
        ]),
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(LimitPeriod.week);
    registerFallbackValue(
      DateRange(start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 12)),
    );
  });

  test('shows a reaction for the logged transaction', () async {
    final cubit = ReactionCubit(transactions, preferences, limits, clock);
    await cubit.show(dogFood, pets);

    expect(cubit.state?.transaction, dogFood);
    expect(cubit.state?.buddyName, 'Noodle');
    expect((cubit.state?.line as ReactionLine?)?.pool, ReactionPool.pets);
    await cubit.close();
  });

  test('does not repeat the previous line', () async {
    final cubit = ReactionCubit(transactions, preferences, limits, clock);
    await cubit.show(dogFood, pets);
    final first = cubit.state!;
    await cubit.show(dogFood, pets);

    expect(cubit.state!.line, isNot(first.line));
    expect(cubit.state!.id, isNot(first.id));
    await cubit.close();
  });

  test('goes away on its own after a while', () async {
    final cubit = ReactionCubit.showingFor(
      transactions,
      preferences,
      limits,
      clock,
      const Duration(milliseconds: 20),
    );
    await cubit.show(dogFood, pets);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(cubit.state, isNull);
    await cubit.close();
  });

  test('a new reaction gets the full time again', () async {
    final cubit = ReactionCubit.showingFor(
      transactions,
      preferences,
      limits,
      clock,
      const Duration(milliseconds: 60),
    );
    await cubit.show(dogFood, pets);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    await cubit.show(dogFood, pets);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(cubit.state, isNotNull);
    await cubit.close();
  });

  test('dismiss hides it right away', () async {
    final cubit = ReactionCubit(transactions, preferences, limits, clock);
    await cubit.show(dogFood, pets);
    cubit.dismiss();

    expect(cubit.state, isNull);
    await cubit.close();
  });

  group('how often', () {
    test('never reacts when turned off', () async {
      prefer(ReactionFrequency.never);
      final cubit = ReactionCubit(transactions, preferences, limits, clock);

      await cubit.show(dogFood, pets);

      expect(cubit.state, isNull);
      await cubit.close();
    });

    test('every n-th transaction reacts only on a multiple of n', () async {
      prefer(ReactionFrequency.sometimes);
      final cubit = ReactionCubit(transactions, preferences, limits, clock);

      when(transactions.count).thenAnswer((_) async => right(4));
      await cubit.show(dogFood, pets);
      expect(cubit.state, isNull);

      when(transactions.count).thenAnswer((_) async => right(6));
      await cubit.show(dogFood, pets);
      expect(cubit.state, isNotNull);
      await cubit.close();
    });

    test('shouldReact', () {
      bool react(ReactionFrequency frequency, int? count) =>
          ReactionCubit.shouldReact(
            frequency,
            interval: 3,
            transactionCount: count,
          );

      expect(react(ReactionFrequency.always, null), isTrue);
      expect(react(ReactionFrequency.never, 3), isFalse);
      expect(react(ReactionFrequency.sometimes, 3), isTrue);
      expect(react(ReactionFrequency.sometimes, 5), isFalse);
      // Without a count, it stays quiet.
      expect(react(ReactionFrequency.sometimes, null), isFalse);
    });
  });

  group('limits', () {
    test(
      'a save that brings a limit to 80% gets a worried limit line',
      () async {
        // $10.00 before, $52.75 of $50.00 after: over.
        petsSpent = 1000 + 4275;
        final cubit = ReactionCubit(transactions, preferences, limits, clock);
        await cubit.show(dogFood, pets);

        final line = cubit.state!.line;
        expect(line, isA<LimitLine>());
        expect((line as LimitLine).progress.status, LimitStatus.over);
        expect(line.expression, BuddyExpression.worried);
        await cubit.close();
      },
    );

    test('a limit that stays under gets the usual line', () async {
      // $30.00 of $50.00 after the save: 60%.
      petsSpent = 3000;
      final cubit = ReactionCubit(transactions, preferences, limits, clock);
      await cubit.show(dogFood, pets);

      expect(cubit.state!.line, isA<ReactionLine>());
      await cubit.close();
    });
  });
}
