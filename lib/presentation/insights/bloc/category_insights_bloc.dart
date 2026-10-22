import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/limit_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/services/period_totals.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/insights_period.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/insights/bloc/insights_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'category_insights_bloc.freezed.dart';
part 'category_insights_event.dart';
part 'category_insights_state.dart';

/// What a category came to in one period of Insights, and how it's trending.
@injectable
class CategoryInsightsBloc
    extends Bloc<CategoryInsightsEvent, CategoryInsightsState> {
  CategoryInsightsBloc(
    @factoryParam CategoryInsightsArgs args,
    this._transactions,
    this._limits,
    this._preferences,
    Clock clock,
  ) : super(
        CategoryInsightsState(
          today: clock.now(),
          category: args.category,
          period: args.period,
          range: args.range,
        ),
      ) {
    on<_Started>(
      (event, emit) => emit.forEach(
        _preferences.watch(),
        onData: (result) {
          final next = state.copyWith(
            preferences: result.getRight().toNullable() ?? state.preferences,
          );
          final currencyCode = next.preferences?.currencyCode;
          if (currencyCode != null && currencyCode != _watching) {
            _watching = currencyCode;
            add(const CategoryInsightsEvent.dataWatched());
          }
          return next;
        },
      ),
    );
    on<_DataWatched>(_onDataWatched, transformer: restartable());
  }

  final TransactionRepository _transactions;
  final LimitRepository _limits;
  final PreferencesRepository _preferences;

  String? _watching;

  Future<void> _onDataWatched(
    _DataWatched event,
    Emitter<CategoryInsightsState> emit,
  ) async {
    final preferences = state.preferences;
    if (preferences == null) return;
    final (currencyCode, category, range) = (
      preferences.currencyCode,
      state.category,
      state.range,
    );
    final trend = state.trendRanges;
    final start = state.previousRange.start.isBefore(trend.first.start)
        ? state.previousRange.start
        : trend.first.start;

    Stream<CategoryInsightsState> limitIn(LimitPeriod period) => _limits
        .watchProgress(
          period: period,
          currencyCode: currencyCode,
          range: period.rangeContaining(
            state.today,
            weekStart: preferences.weekStart,
          ),
        )
        .map(
          (result) => switch (result.getRight().toNullable()) {
            final limits? => state.copyWith(
              limits: [
                // The other period's limit stays as it was.
                for (final limit in state.limits)
                  if (limit.limit.period != period) limit,
                for (final limit in limits)
                  if (limit.limit.categoryId == category.id) limit,
              ],
            ),
            null => state,
          },
        );

    await Future.wait([
      emit.forEach(
        _transactions.watchExpensesByDay(
          DateRange(start: start, end: trend.last.end),
          currencyCode: currencyCode,
          categoryId: category.id,
        ),
        onData: (result) => state.copyWith(
          expensesByDay: result.getRight().toNullable() ?? state.expensesByDay,
        ),
      ),
      emit.forEach(
        _transactions.watchSummary(range, currencyCode: currencyCode),
        onData: (result) => state.copyWith(
          totalExpenseMinor:
              result.getRight().toNullable()?.expenseMinor ??
              state.totalExpenseMinor,
        ),
      ),
      emit.forEach(
        _transactions.watchFiltered(
          TransactionFilter(
            type: TransactionType.expense,
            categoryIds: {category.id},
            range: range,
          ),
        ),
        onData: (result) => switch (result.getRight().toNullable()) {
          final entries? => state.copyWith(
            transactionCount: entries
                .where((e) => e.transaction.currencyCode == currencyCode)
                .length,
          ),
          null => state,
        },
      ),
      emit.forEach(limitIn(LimitPeriod.week), onData: (next) => next),
      emit.forEach(limitIn(LimitPeriod.month), onData: (next) => next),
    ]);
  }
}

/// Which category, and which period of Insights it was opened from.
typedef CategoryInsightsArgs = ({
  Category category,
  InsightsPeriod period,
  DateRange range,
});
