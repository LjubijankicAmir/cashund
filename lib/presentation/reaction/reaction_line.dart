import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/reaction/buddy_line.dart';
import 'package:flutter/foundation.dart';

/// A set of lines the buddy picks from after something is logged: one per
/// built-in category, and a generic one per type for "Other" and the user's
/// own categories.
enum ReactionPool {
  groceries(TransactionType.expense, 'groceries', BuddyExpression.happy),
  eatingOut(TransactionType.expense, 'eating_out', BuddyExpression.listening),
  transport(TransactionType.expense, 'transport', BuddyExpression.listening),
  housing(TransactionType.expense, 'housing', BuddyExpression.listening),
  bills(TransactionType.expense, 'bills', BuddyExpression.listening),
  household(TransactionType.expense, 'household', BuddyExpression.listening),
  health(TransactionType.expense, 'health', BuddyExpression.listening),
  personalCare(TransactionType.expense, 'personal_care', BuddyExpression.happy),
  clothing(TransactionType.expense, 'clothing', BuddyExpression.happy),
  socialLife(TransactionType.expense, 'social_life', BuddyExpression.happy),
  giftsGiven(TransactionType.expense, 'gifts', BuddyExpression.happy),
  travel(TransactionType.expense, 'travel', BuddyExpression.happy),
  pets(TransactionType.expense, 'pets', BuddyExpression.happy),
  otherExpense(TransactionType.expense, null, BuddyExpression.listening),
  salary(TransactionType.income, 'salary', BuddyExpression.happy),
  bonus(TransactionType.income, 'bonus', BuddyExpression.happy),
  sideIncome(TransactionType.income, 'side_income', BuddyExpression.happy),
  giftsReceived(TransactionType.income, 'gifts', BuddyExpression.happy),
  refunds(TransactionType.income, 'refunds', BuddyExpression.happy),
  interest(TransactionType.income, 'interest', BuddyExpression.happy),
  otherIncome(TransactionType.income, null, BuddyExpression.happy);

  ReactionPool(this.type, this.predefinedKey, this.expression);

  final TransactionType type;

  /// The built-in category it's for; `null` for the generic pools.
  final String? predefinedKey;
  final BuddyExpression expression;

  /// Every pool has this many lines, indexed from 0.
  static const lineCount = 12;

  /// The pool for a transaction of [type] in the category with
  /// [predefinedKey], or the type's generic pool.
  static ReactionPool of(TransactionType type, String? predefinedKey) {
    for (final pool in values) {
      if (pool.type == type &&
          pool.predefinedKey != null &&
          pool.predefinedKey == predefinedKey) {
        return pool;
      }
    }
    return type == TransactionType.expense ? otherExpense : otherIncome;
  }

  String line(AppLocalizations l10n, int index) {
    final i = '$index';
    return switch (this) {
      groceries => l10n.reactionGroceries(i),
      eatingOut => l10n.reactionEatingOut(i),
      transport => l10n.reactionTransport(i),
      housing => l10n.reactionHousing(i),
      bills => l10n.reactionBills(i),
      household => l10n.reactionHousehold(i),
      health => l10n.reactionHealth(i),
      personalCare => l10n.reactionPersonalCare(i),
      clothing => l10n.reactionClothing(i),
      socialLife => l10n.reactionSocialLife(i),
      giftsGiven => l10n.reactionGiftsGiven(i),
      travel => l10n.reactionTravel(i),
      pets => l10n.reactionPets(i),
      otherExpense => l10n.reactionOtherExpense(i),
      salary => l10n.reactionSalary(i),
      bonus => l10n.reactionBonus(i),
      sideIncome => l10n.reactionSideIncome(i),
      giftsReceived => l10n.reactionGiftsReceived(i),
      refunds => l10n.reactionRefunds(i),
      interest => l10n.reactionInterest(i),
      otherIncome => l10n.reactionOtherIncome(i),
    };
  }
}

/// One line from a [pool]: what the buddy says, and how they look saying it.
@immutable
class ReactionLine implements BuddyLine {
  const ReactionLine(this.pool, this.index);

  final ReactionPool pool;
  final int index;

  @override
  BuddyExpression get expression => pool.expression;

  @override
  String text(AppLocalizations l10n) => pool.line(l10n, index);

  @override
  bool operator ==(Object other) =>
      other is ReactionLine && other.pool == pool && other.index == index;

  @override
  int get hashCode => Object.hash(pool, index);

  @override
  String toString() => 'ReactionLine(${pool.name}, $index)';
}

/// Picks lines at random, avoiding the last few said from the same pool so
/// the buddy doesn't repeat themself.
class ReactionPicker {
  ReactionPicker([Random? random]) : _random = random ?? Random();

  final Random _random;
  final _recent = <ReactionPool, List<int>>{};

  /// How many of a pool's latest lines are skipped.
  static const memory = 6;

  ReactionLine pick({
    required TransactionType type,
    required String? predefinedKey,
  }) {
    final pool = ReactionPool.of(type, predefinedKey);
    final recent = _recent.putIfAbsent(pool, () => []);
    final fresh = [
      for (var i = 0; i < ReactionPool.lineCount; i++)
        if (!recent.contains(i)) i,
    ];
    final index = fresh[_random.nextInt(fresh.length)];

    recent.add(index);
    if (recent.length > memory) recent.removeAt(0);
    return ReactionLine(pool, index);
  }
}
