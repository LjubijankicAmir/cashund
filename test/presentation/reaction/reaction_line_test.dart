import 'dart:math';
import 'dart:ui';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/reaction/reaction_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReactionPool.of', () {
    test('built-in categories get their own pool', () {
      expect(
        ReactionPool.of(TransactionType.expense, 'pets'),
        ReactionPool.pets,
      );
      expect(
        ReactionPool.of(TransactionType.income, 'salary'),
        ReactionPool.salary,
      );
    });

    test('"gifts" depends on the type', () {
      expect(
        ReactionPool.of(TransactionType.expense, 'gifts'),
        ReactionPool.giftsGiven,
      );
      expect(
        ReactionPool.of(TransactionType.income, 'gifts'),
        ReactionPool.giftsReceived,
      );
    });

    test('"other" and custom categories get the generic pool', () {
      expect(
        ReactionPool.of(TransactionType.expense, 'other'),
        ReactionPool.otherExpense,
      );
      expect(
        ReactionPool.of(TransactionType.expense, null),
        ReactionPool.otherExpense,
      );
      expect(
        ReactionPool.of(TransactionType.income, null),
        ReactionPool.otherIncome,
      );
    });
  });

  test('every pool has its full set of distinct lines', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    for (final pool in ReactionPool.values) {
      final lines = {
        for (var i = 0; i < ReactionPool.lineCount; i++) pool.line(l10n, i),
      };
      expect(lines, hasLength(ReactionPool.lineCount), reason: pool.name);
      expect(lines.every((line) => line.isNotEmpty), isTrue);
    }
  });

  group('ReactionPicker', () {
    ReactionLine pick(ReactionPicker picker) =>
        picker.pick(type: TransactionType.expense, predefinedKey: 'pets');

    test('picks from the transaction’s pool', () {
      expect(pick(ReactionPicker(Random(1))).pool, ReactionPool.pets);
    });

    test('never repeats one of the last few lines of a pool', () {
      final picker = ReactionPicker(Random(7));
      final picked = [for (var i = 0; i < 200; i++) pick(picker).index];

      for (var i = 0; i < picked.length; i++) {
        final window = picked.sublist(max(0, i - ReactionPicker.memory), i);
        expect(window, isNot(contains(picked[i])), reason: 'pick $i');
      }
    });

    test('uses every line of a pool over time', () {
      final picker = ReactionPicker(Random(3));
      final seen = {for (var i = 0; i < 200; i++) pick(picker).index};

      expect(seen, hasLength(ReactionPool.lineCount));
    });
  });
}
