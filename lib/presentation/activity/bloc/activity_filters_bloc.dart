import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/activity/date_preset.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'activity_filters_bloc.freezed.dart';
part 'activity_filters_event.dart';
part 'activity_filters_state.dart';

/// The filters sheet's draft, and how many results it would show.
@injectable
class ActivityFiltersBloc
    extends Bloc<ActivityFiltersEvent, ActivityFiltersState> {
  ActivityFiltersBloc(
    this._categories,
    this._transactions,
    this._preferences,
    Clock clock,
  ) : super(ActivityFiltersState(today: _dateOnly(clock.now()))) {
    on<_Started>(_onStarted);
    on<_TypeChanged>(_onTypeChanged);
    on<_CategoryToggled>((event, emit) {
      final ids = {...state.draft.categoryIds};
      if (!ids.remove(event.categoryId)) ids.add(event.categoryId);
      _setDraft(emit, state.draft.copyWith(categoryIds: ids));
    });
    on<_CategoriesCleared>(
      (event, emit) => _setDraft(emit, state.draft.copyWith(categoryIds: {})),
    );
    on<_PresetSelected>(_onPresetSelected);
    on<_CustomFromChanged>((event, emit) => _setCustom(emit, from: event.day));
    on<_CustomToChanged>((event, emit) => _setCustom(emit, to: event.day));
    on<_Reset>((event, emit) {
      emit(state.copyWith(preset: null));
      _setDraft(emit, const TransactionFilter());
    });
    on<_ResultsWatched>(_onResultsWatched, transformer: restartable());
  }

  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final PreferencesRepository _preferences;

  static DateTime _dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  Future<void> _onStarted(
    _Started event,
    Emitter<ActivityFiltersState> emit,
  ) async {
    final weekStart =
        (await _preferences.get()).getRight().toNullable()?.weekStart ??
        WeekStart.monday;
    final range = event.filter.range;
    emit(
      state.copyWith(
        weekStart: weekStart,
        draft: event.filter,
        preset: range == null
            ? null
            : DatePreset.of(range, state.today, weekStart),
      ),
    );
    add(ActivityFiltersEvent.resultsWatched(event.filter));

    await Future.wait([
      emit.forEach(
        _categories.watchActive(TransactionType.expense),
        onData: (result) => state.copyWith(
          expenseCategories: result.getRight().toNullable() ?? [],
        ),
      ),
      emit.forEach(
        _categories.watchActive(TransactionType.income),
        onData: (result) => state.copyWith(
          incomeCategories: result.getRight().toNullable() ?? [],
        ),
      ),
    ]);
  }

  void _onTypeChanged(_TypeChanged event, Emitter<ActivityFiltersState> emit) {
    // Categories of the other type can't match anymore.
    final keep = {
      for (final category in [
        ...state.expenseCategories,
        ...state.incomeCategories,
      ])
        if (event.type == null || category.type == event.type) category.id,
    };
    _setDraft(
      emit,
      state.draft.copyWith(
        type: event.type,
        categoryIds: state.draft.categoryIds.intersection(keep),
      ),
    );
  }

  void _onPresetSelected(
    _PresetSelected event,
    Emitter<ActivityFiltersState> emit,
  ) {
    // Tapping the selected chip again goes back to all time.
    if (event.preset == state.preset) {
      emit(state.copyWith(preset: null));
      _setDraft(emit, state.draft.copyWith(range: null));
      return;
    }
    emit(state.copyWith(preset: event.preset));
    // Custom starts from whatever range is set, or this month.
    final range =
        event.preset.rangeAround(state.today, state.weekStart) ??
        state.draft.range ??
        DatePreset.thisMonth.rangeAround(state.today, state.weekStart);
    _setDraft(emit, state.draft.copyWith(range: range));
  }

  /// Sets one end of a custom range, keeping it at least one day long.
  void _setCustom(
    Emitter<ActivityFiltersState> emit, {
    DateTime? from,
    DateTime? to,
  }) {
    final current =
        state.draft.range ??
        DatePreset.thisMonth.rangeAround(state.today, state.weekStart)!;
    var start = from == null ? current.start : _dateOnly(from);
    // The range's end is exclusive; the chosen "to" day is included.
    var end = to == null
        ? current.end
        : DateTime(to.year, to.month, to.day + 1);
    if (!start.isBefore(end)) {
      if (from != null) end = DateTime(start.year, start.month, start.day + 1);
      if (to != null) start = DateTime(end.year, end.month, end.day - 1);
    }
    emit(state.copyWith(preset: DatePreset.custom));
    _setDraft(
      emit,
      state.draft.copyWith(
        range: DateRange(start: start, end: end),
      ),
    );
  }

  void _setDraft(Emitter<ActivityFiltersState> emit, TransactionFilter draft) {
    emit(state.copyWith(draft: draft));
    add(ActivityFiltersEvent.resultsWatched(draft));
  }

  Future<void> _onResultsWatched(
    _ResultsWatched event,
    Emitter<ActivityFiltersState> emit,
  ) {
    return emit.forEach(
      _transactions.watchFiltered(event.filter),
      onData: (result) => state.copyWith(
        results: result.getRight().toNullable() ?? state.results,
      ),
    );
  }
}
