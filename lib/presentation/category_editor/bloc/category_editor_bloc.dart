import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'category_editor_bloc.freezed.dart';
part 'category_editor_event.dart';
part 'category_editor_state.dart';

/// The category editor sheet, for new and existing categories alike.
@injectable
class CategoryEditorBloc
    extends Bloc<CategoryEditorEvent, CategoryEditorState> {
  CategoryEditorBloc(this._categories, this._preferences)
    : super(const CategoryEditorState()) {
    on<_Started>(_onStarted);
    on<_NameChanged>((event, emit) => emit(state.copyWith(name: event.name)));
    on<_EmojiSelected>((event, emit) {
      if (!state.isBuiltIn) emit(state.copyWith(emoji: event.emoji));
    });
    on<_ColorSelected>(
      (event, emit) => emit(state.copyWith(color: event.color)),
    );
    on<_SavePressed>(_onSavePressed);
    on<_ArchivePressed>(_onArchivePressed);
  }

  final CategoryRepository _categories;
  final PreferencesRepository _preferences;

  /// Set on start; see [CategoryEditorEvent.started].
  String Function(String predefinedKey) _builtInName = (key) => key;

  String _nameOf(Category category) =>
      category.customName ?? _builtInName(category.predefinedKey ?? '');

  Future<void> _onStarted(
    _Started event,
    Emitter<CategoryEditorState> emit,
  ) async {
    _builtInName = event.builtInName;
    final editing = event.editing;
    emit(
      CategoryEditorState(
        type: event.type,
        original: editing,
        name: editing == null ? '' : _nameOf(editing),
        emoji: editing?.emoji ?? suggestedCategoryEmoji.first,
        color: editing?.color ?? CategoryColor.coral,
      ),
    );

    final preferences = (await _preferences.get()).getRight().toNullable();
    if (preferences != null) {
      emit(state.copyWith(currencyCode: preferences.currencyCode));
    }

    final others = (await _categories.watchByType(event.type).first)
        .getRight()
        .toNullable();
    if (others == null) return;

    // A new category gets the first color nothing active uses yet.
    final usedColors = {
      for (final other in others)
        if (!other.isArchived) other.color,
    };
    emit(
      state.copyWith(
        takenNames: {
          for (final other in others)
            if (other.id != editing?.id) _nameOf(other).toLowerCase(),
        },
        color:
            editing?.color ??
            CategoryColor.values.firstWhere(
              (color) => !usedColors.contains(color),
              orElse: () => CategoryColor.values.first,
            ),
      ),
    );
  }

  Future<void> _onSavePressed(
    _SavePressed event,
    Emitter<CategoryEditorState> emit,
  ) async {
    if (!state.canSave) return;
    emit(state.copyWith(status: CategoryEditorStatus.saving));

    final original = state.original;
    if (original == null) {
      final result = await _categories.create(
        type: state.type,
        name: state.trimmedName,
        emoji: state.emoji,
        color: state.color,
      );
      emit(
        result.match(
          (_) => state.copyWith(status: CategoryEditorStatus.failure),
          (created) => state.copyWith(
            status: CategoryEditorStatus.saved,
            saved: created,
          ),
        ),
      );
      return;
    }

    // A built-in category named as its default keeps following translations.
    final key = original.predefinedKey;
    final customName = key != null && state.trimmedName == _builtInName(key)
        ? null
        : state.trimmedName;
    final result = await _categories.update(
      id: original.id,
      customName: customName,
      emoji: state.emoji,
      color: state.color,
    );
    emit(
      state.copyWith(
        status: result.isRight()
            ? CategoryEditorStatus.saved
            : CategoryEditorStatus.failure,
        saved: original.copyWith(
          customName: customName,
          emoji: state.emoji,
          color: state.color,
        ),
      ),
    );
  }

  Future<void> _onArchivePressed(
    _ArchivePressed event,
    Emitter<CategoryEditorState> emit,
  ) async {
    final original = state.original;
    if (original == null || state.status == CategoryEditorStatus.saving) {
      return;
    }
    emit(state.copyWith(status: CategoryEditorStatus.saving));
    final result = await _categories.setArchived(original.id, archived: true);
    emit(
      state.copyWith(
        status: result.isRight()
            ? CategoryEditorStatus.archived
            : CategoryEditorStatus.failure,
      ),
    );
  }
}
