import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'categories_bloc.freezed.dart';
part 'categories_event.dart';
part 'categories_state.dart';

/// The categories page: one type at a time, reordered and archived in place.
///
/// Changes show right away, before they're saved, so a dragged or swiped
/// row never jumps back; the saved list replaces them once it arrives.
@injectable
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._categories) : super(const CategoriesState()) {
    on<_TypeSelected>(
      (event, emit) {
        emit(CategoriesState(type: event.type));
        return emit.forEach(
          _categories.watchByType(event.type),
          onData: (result) => switch (result.getRight().toNullable()) {
            final categories? => state.copyWith(categories: categories),
            null => state,
          },
        );
      },
      // A new type replaces the old subscription.
      transformer: restartable(),
    );
    on<_Reordered>(_onReordered);
    on<_Archived>(
      (event, emit) => _setArchived(emit, event.id, archived: true),
    );
    on<_Restored>(
      (event, emit) => _setArchived(emit, event.id, archived: false),
    );
  }

  final CategoryRepository _categories;

  Future<void> _onReordered(
    _Reordered event,
    Emitter<CategoriesState> emit,
  ) async {
    final all = state.categories;
    if (all == null || event.oldIndex == event.newIndex) return;

    final reordered = moveActive(all, event.oldIndex, event.newIndex);
    emit(state.copyWith(categories: reordered, saveFailed: false));
    await _save(
      emit,
      _categories.reorder(state.type, [for (final c in reordered) c.id]),
    );
  }

  Future<void> _setArchived(
    Emitter<CategoriesState> emit,
    int id, {
    required bool archived,
  }) async {
    final all = state.categories;
    if (all == null) return;

    emit(
      state.copyWith(
        categories: [
          for (final category in all)
            if (category.id == id)
              category.copyWith(isArchived: archived)
            else
              category,
        ],
        saveFailed: false,
      ),
    );
    await _save(emit, _categories.setArchived(id, archived: archived));
  }

  Future<void> _save(
    Emitter<CategoriesState> emit,
    FutureResult<Unit> saving,
  ) async {
    if ((await saving).isLeft()) {
      // Shows the saved list again, without the change that failed.
      final saved = (await _categories.watchByType(state.type).first)
          .getRight()
          .toNullable();
      emit(
        state.copyWith(categories: saved ?? state.categories, saveFailed: true),
      );
    }
  }

  /// [all] with the active category at [oldIndex] moved to [newIndex] among
  /// the active ones. Archived categories keep their places, so a restored
  /// one comes back where it was.
  @visibleForTesting
  static List<Category> moveActive(
    List<Category> all,
    int oldIndex,
    int newIndex,
  ) {
    final active = [
      for (final category in all)
        if (!category.isArchived) category,
    ];
    active.insert(newIndex, active.removeAt(oldIndex));

    var next = 0;
    return [
      for (final category in all)
        if (category.isArchived) category else active[next++],
    ];
  }
}
