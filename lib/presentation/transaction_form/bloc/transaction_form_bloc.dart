import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/amount_input.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'transaction_form_bloc.freezed.dart';
part 'transaction_form_event.dart';
part 'transaction_form_state.dart';

@injectable
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
    this._categories,
    this._transactions,
    this._preferences,
    Clock clock,
  ) : super(_initialState(clock.now())) {
    on<_Started>(_onStarted);
    on<_EditStarted>(_onEditStarted);
    on<_DeletePressed>(_onDeletePressed);
    on<_TypeChanged>(_onTypeChanged);
    on<_AmountChanged>(
      (event, emit) => emit(state.copyWith(amountText: event.text)),
    );
    on<_CategorySelected>(
      (event, emit) => emit(state.copyWith(categoryId: event.categoryId)),
    );
    on<_TitleChanged>(
      (event, emit) => emit(state.copyWith(title: event.title)),
    );
    on<_DateSelected>(
      (event, emit) => emit(state.copyWith(date: _dateOnly(event.date))),
    );
    on<_SavePressed>(_onSavePressed);
    // Switching type starts following the other type's lists and drops the
    // old subscription.
    on<_CategoriesWatched>(_onCategoriesWatched, transformer: restartable());
  }

  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  static TransactionFormState _initialState(DateTime now) {
    final today = _dateOnly(now);
    return TransactionFormState(today: today, date: today);
  }

  static DateTime _dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  Future<void> _onStarted(
    _Started event,
    Emitter<TransactionFormState> emit,
  ) async {
    emit(state.copyWith(type: event.type));
    add(TransactionFormEvent.categoriesWatched(event.type));

    final preferences = (await _preferences.get()).getRight().toNullable();
    emit(
      state.copyWith(
        currency:
            currencyByCode(preferences?.currencyCode ?? '') ??
            supportedCurrencies.first,
      ),
    );
  }

  void _onTypeChanged(_TypeChanged event, Emitter<TransactionFormState> emit) {
    if (event.type == state.type) return;
    emit(
      state.copyWith(
        type: event.type,
        categoryId: null,
        categories: const [],
        recentCategories: const [],
      ),
    );
    add(TransactionFormEvent.categoriesWatched(event.type));
  }

  Future<void> _onCategoriesWatched(
    _CategoriesWatched event,
    Emitter<TransactionFormState> emit,
  ) async {
    await Future.wait([
      emit.forEach(
        _categories.watchActive(event.type),
        onData: (result) => state.copyWith(
          categories: result.getRight().toNullable() ?? state.categories,
        ),
      ),
      emit.forEach(
        _categories.watchRecent(
          event.type,
          limit: TransactionFormState.recentCount,
        ),
        onData: (result) {
          final recent =
              result.getRight().toNullable() ?? state.recentCategories;
          // Nothing picked yet: start with the most recently used category.
          final categoryId =
              state.categoryId ?? (recent.isEmpty ? null : recent.first.id);
          return state.copyWith(
            recentCategories: recent,
            categoryId: categoryId,
          );
        },
      ),
    ]);
  }

  Future<void> _onSavePressed(
    _SavePressed event,
    Emitter<TransactionFormState> emit,
  ) async {
    final (amountMinor, category, currency) = (
      state.amountMinor,
      state.selectedCategory,
      state.currency,
    );
    if (!state.canSave ||
        amountMinor == null ||
        category == null ||
        currency == null) {
      return;
    }

    emit(state.copyWith(status: TransactionFormStatus.saving));
    final result = switch (state.original) {
      final original? => await _transactions.update(
        id: original.id,
        type: state.type,
        amountMinor: amountMinor,
        categoryId: category.id,
        occurredOn: state.date,
        title: state.title,
      ),
      null => await _transactions.add(
        type: state.type,
        amountMinor: amountMinor,
        currencyCode: currency.code,
        categoryId: category.id,
        occurredOn: state.date,
        title: state.title,
      ),
    };
    emit(
      state.copyWith(
        status: result.isRight()
            ? TransactionFormStatus.saved
            : TransactionFormStatus.failure,
      ),
    );
  }

  /// Fills the form with [_EditStarted.transaction], in its own currency.
  void _onEditStarted(_EditStarted event, Emitter<TransactionFormState> emit) {
    final transaction = event.transaction;
    final currency =
        currencyByCode(transaction.currencyCode) ??
        Currency(
          code: transaction.currencyCode,
          symbol: transaction.currencyCode,
          decimalDigits: 2,
        );
    emit(
      state.copyWith(
        original: transaction,
        type: transaction.type,
        currency: currency,
        amountText: formatAmountText(transaction.amountMinor, currency),
        categoryId: transaction.categoryId,
        title: transaction.title ?? '',
        date: transaction.occurredOn,
      ),
    );
    add(TransactionFormEvent.categoriesWatched(transaction.type));
  }

  Future<void> _onDeletePressed(
    _DeletePressed event,
    Emitter<TransactionFormState> emit,
  ) async {
    final original = state.original;
    if (original == null || state.status == TransactionFormStatus.saving) {
      return;
    }

    emit(state.copyWith(status: TransactionFormStatus.saving));
    final result = await _transactions.delete(original.id);
    emit(
      state.copyWith(
        status: result.isRight()
            ? TransactionFormStatus.deleted
            : TransactionFormStatus.failure,
      ),
    );
  }
}
