import 'dart:async';
import 'dart:math';

import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/reaction/buddy_line.dart';
import 'package:cashund/presentation/reaction/limit_line.dart';
import 'package:cashund/presentation/reaction/reaction_line.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'reaction_cubit.freezed.dart';

/// The buddy reacting to a transaction that was just logged.
@freezed
abstract class Reaction with _$Reaction {
  const factory Reaction({
    /// Tells two reactions to the same line apart, e.g. to restart the timer.
    required int id,
    required Transaction transaction,
    required BuddyLine line,
    required String buddyName,
  }) = _Reaction;
}

/// The reaction on screen after something is logged, if any. It shows for
/// [visibleFor], one at a time; a new one replaces the current one.
@injectable
class ReactionCubit extends Cubit<Reaction?> {
  ReactionCubit(
    TransactionRepository transactions,
    PreferencesRepository preferences,
    LimitRepository limits,
    Clock clock,
  ) : this.showingFor(
        transactions,
        preferences,
        limits,
        clock,
        const Duration(seconds: 4),
      );

  @visibleForTesting
  ReactionCubit.showingFor(
    this._transactions,
    this._preferences,
    this._limits,
    this._clock,
    this.visibleFor, [
    ReactionPicker? picker,
    Random? random,
  ]) : _picker = picker ?? ReactionPicker(random),
       _random = random ?? Random(),
       super(null);

  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;
  final LimitRepository _limits;
  final Clock _clock;
  final Random _random;

  /// The last limit line said, so the next one at that level differs.
  LimitLine? _previousLimitLine;
  final Duration visibleFor;

  Timer? _timer;
  final ReactionPicker _picker;
  var _count = 0;

  /// Reacts to [transaction], just logged in [category], if the user's
  /// reaction preference says so.
  Future<void> show(Transaction transaction, Category category) async {
    final preferences = (await _preferences.get()).getRight().toNullable();
    final frequency =
        preferences?.reactionFrequency ?? ReactionFrequency.always;
    final count = frequency == ReactionFrequency.sometimes
        ? (await _transactions.count()).getRight().toNullable()
        : null;
    if (!shouldReact(
      frequency,
      interval:
          preferences?.reactionInterval ??
          UserPreferences.defaultReactionInterval,
      transactionCount: count,
    )) {
      return;
    }

    // A limit this pushed to 80% or past it comes before anything else.
    final BuddyLine line;
    if (await _limitCrossedBy(transaction, category, preferences)
        case final crossed?) {
      line = _previousLimitLine = LimitLine.random(
        crossed,
        currency:
            currencyByCode(transaction.currencyCode) ??
            supportedCurrencies.first,
        random: _random,
        previous: _previousLimitLine,
      );
    } else {
      line = _picker.pick(
        type: transaction.type,
        predefinedKey: category.predefinedKey,
      );
    }
    _timer?.cancel();
    _timer = Timer(visibleFor, dismiss);
    emit(
      Reaction(
        id: ++_count,
        transaction: transaction,
        line: line,
        buddyName: preferences?.buddyName ?? UserPreferences.defaultBuddyName,
      ),
    );
  }

  /// The limit [transaction] just pushed to a new level, close or over: of
  /// its category's limits and the overall ones, this week's and this
  /// month's. Over comes first, then the bigger share.
  Future<LimitProgress?> _limitCrossedBy(
    Transaction transaction,
    Category category,
    UserPreferences? preferences,
  ) async {
    if (preferences == null ||
        transaction.type != TransactionType.expense ||
        transaction.currencyCode != preferences.currencyCode) {
      return null;
    }

    final crossed = <LimitProgress>[];
    for (final period in LimitPeriod.values) {
      final range = period.rangeContaining(
        _clock.now(),
        weekStart: preferences.weekStart,
      );
      if (!range.contains(transaction.occurredOn)) continue;
      final limits =
          (await _limits
                  .watchProgress(
                    period: period,
                    currencyCode: transaction.currencyCode,
                    range: range,
                  )
                  .first)
              .getRight()
              .toNullable();
      for (final after in limits ?? const <LimitProgress>[]) {
        if (!after.limit.isOverall && after.limit.categoryId != category.id) {
          continue;
        }
        final before = after.copyWith(
          spentMinor: after.spentMinor - transaction.amountMinor,
        );
        if (after.status.index > before.status.index) crossed.add(after);
      }
    }
    crossed.sort((a, b) {
      final byStatus = b.status.index.compareTo(a.status.index);
      return byStatus != 0 ? byStatus : b.fraction.compareTo(a.fraction);
    });
    return crossed.firstOrNull;
  }

  /// With [ReactionFrequency.sometimes], the buddy reacts when the
  /// [transactionCount] (the new one included) is a multiple of [interval].
  @visibleForTesting
  static bool shouldReact(
    ReactionFrequency frequency, {
    required int interval,
    required int? transactionCount,
  }) {
    return switch (frequency) {
      ReactionFrequency.always => true,
      ReactionFrequency.never => false,
      ReactionFrequency.sometimes =>
        transactionCount != null && transactionCount % interval == 0,
    };
  }

  void dismiss() {
    _timer?.cancel();
    if (state != null) emit(null);
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await super.close();
  }
}
