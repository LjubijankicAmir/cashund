import 'dart:async';

import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
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
    required ReactionLine line,
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
  ) : this.showingFor(transactions, preferences, const Duration(seconds: 4));

  @visibleForTesting
  ReactionCubit.showingFor(
    this._transactions,
    this._preferences,
    this.visibleFor, [
    ReactionPicker? picker,
  ]) : _picker = picker ?? ReactionPicker(),
       super(null);

  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;
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

    final line = _picker.pick(
      type: transaction.type,
      predefinedKey: category.predefinedKey,
    );
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
