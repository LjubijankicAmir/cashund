import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/amount_input.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show unit;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'limit_editor_bloc.freezed.dart';
part 'limit_editor_event.dart';
part 'limit_editor_state.dart';

/// The limit editor sheet, for new and existing limits alike.
@injectable
class LimitEditorBloc extends Bloc<LimitEditorEvent, LimitEditorState> {
  LimitEditorBloc(
    this._limits,
    this._categories,
    this._transactions,
    this._preferences,
    Clock clock,
  ) : super(LimitEditorState(today: clock.now())) {
    on<_Started>(_onStarted);
    on<_PeriodChanged>((event, emit) {
      if (state.isEditing || event.period == state.period) return;
      emit(state.copyWith(period: event.period));
      add(const LimitEditorEvent.previewWatched());
    });
    on<_TargetChosen>((event, emit) {
      if (state.isEditing) return;
      emit(state.copyWith(target: event.target, spentMinor: 0));
      add(const LimitEditorEvent.previewWatched());
    });
    on<_AmountChanged>(
      (event, emit) => emit(state.copyWith(amountText: event.text)),
    );
    on<_SavePressed>(_onSavePressed);
    on<_DeletePressed>(_onDeletePressed);
    // A new period or target replaces the old subscription.
    on<_PreviewWatched>(_onPreviewWatched, transformer: restartable());
  }

  final LimitRepository _limits;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  Future<void> _onStarted(
    _Started event,
    Emitter<LimitEditorState> emit,
  ) async {
    final editing = event.editing;
    final preferences = (await _preferences.get()).getRight().toNullable();
    final currency = currencyByCode(preferences?.currencyCode ?? '');
    emit(
      state.copyWith(
        preferences: preferences,
        period: editing?.limit.period ?? event.period,
        editing: editing,
        target: switch (editing) {
          null => null,
          LimitProgress(:final category?) => LimitTarget.category(category),
          _ => const LimitTarget.overall(),
        },
        amountText: editing == null || currency == null
            ? ''
            : formatAmountText(editing.amountMinor, currency),
      ),
    );
    if (editing != null) add(const LimitEditorEvent.previewWatched());
    if (preferences == null) return;

    await Future.wait([
      emit.forEach(
        _categories.watchActive(TransactionType.expense),
        onData: (result) => state.copyWith(
          categories: result.getRight().toNullable() ?? state.categories,
        ),
      ),
      emit.forEach(
        _limits.watchAll(preferences.currencyCode),
        onData: (result) => state.copyWith(
          limits: result.getRight().toNullable() ?? state.limits,
        ),
      ),
    ]);
  }

  Future<void> _onPreviewWatched(
    _PreviewWatched event,
    Emitter<LimitEditorState> emit,
  ) {
    final (range, preferences, target) = (
      state.range,
      state.preferences,
      state.target,
    );
    if (range == null || preferences == null || target == null) {
      return Future.value();
    }
    return emit.forEach(
      _transactions.watchExpensesByDay(
        range,
        currencyCode: preferences.currencyCode,
        categoryId: target.categoryId,
      ),
      onData: (result) => switch (result.getRight().toNullable()) {
        final days? => state.copyWith(
          spentMinor: days.values.fold(0, (sum, day) => sum + day),
        ),
        null => state,
      },
    );
  }

  Future<void> _onSavePressed(
    _SavePressed event,
    Emitter<LimitEditorState> emit,
  ) async {
    final (target, amount, range, preferences) = (
      state.target,
      state.amountMinor,
      state.range,
      state.preferences,
    );
    if (!state.canSave ||
        target == null ||
        amount == null ||
        range == null ||
        preferences == null) {
      return;
    }

    emit(state.copyWith(status: LimitEditorStatus.saving));
    final saved = switch (state.editing) {
      // From this period on; past periods keep their amount.
      final editing? => await _limits.changeAmount(
        editing.limit.id,
        amountMinor: amount,
        effectiveFrom: range.start,
      ),
      null => (await _limits.create(
        period: state.period,
        currencyCode: preferences.currencyCode,
        categoryId: target.categoryId,
        amountMinor: amount,
        effectiveFrom: range.start,
      )).map((_) => unit),
    };
    emit(
      state.copyWith(
        status: saved.isRight()
            ? LimitEditorStatus.saved
            : LimitEditorStatus.failure,
      ),
    );
  }

  Future<void> _onDeletePressed(
    _DeletePressed event,
    Emitter<LimitEditorState> emit,
  ) async {
    final editing = state.editing;
    if (editing == null || state.status == LimitEditorStatus.saving) return;

    emit(state.copyWith(status: LimitEditorStatus.saving));
    final deleted = await _limits.delete(editing.limit.id);
    emit(
      deleted.match(
        (_) => state.copyWith(status: LimitEditorStatus.failure),
        (snapshot) => state.copyWith(
          status: LimitEditorStatus.deleted,
          deleted: snapshot,
        ),
      ),
    );
  }
}
