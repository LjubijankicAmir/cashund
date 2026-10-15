part of 'category_editor_bloc.dart';

enum CategoryEditorStatus { editing, saving, saved, archived, failure }

/// Emoji offered for new categories, in grid order. The first is the
/// default.
const suggestedCategoryEmoji = [
  '🎨', '🎮', '📚', '🎬', '🎵', '⚽', '🏋️', '☕', //
  '🍷', '🚗', '⛽', '📱', '💡', '🎓', '👶', '🌱', //
  '🧸', '🛠️', '💈', '🏖️', '🎟️', '💐', '🍼', //
];

@freezed
abstract class CategoryEditorState with _$CategoryEditorState {
  const factory CategoryEditorState({
    @Default(TransactionType.expense) TransactionType type,

    /// The category being changed, as it was; `null` for a new one.
    Category? original,
    @Default('') String name,
    @Default('🎨') String emoji,
    @Default(CategoryColor.coral) CategoryColor color,

    /// For the preview's sample amount; `null` until loaded.
    String? currencyCode,

    /// The names of the type's other categories, lowercased.
    @Default(<String>{}) Set<String> takenNames,
    @Default(CategoryEditorStatus.editing) CategoryEditorStatus status,

    /// The category as saved, once [status] is `saved`.
    Category? saved,
  }) = _CategoryEditorState;

  const CategoryEditorState._();

  bool get isNew => original == null;

  /// Built-in categories can be renamed and recolored, but keep their emoji.
  bool get isBuiltIn => original?.predefinedKey != null;

  String get trimmedName => name.trim();

  bool get isNameTaken => takenNames.contains(trimmedName.toLowerCase());

  bool get canSave =>
      trimmedName.isNotEmpty &&
      !isNameTaken &&
      status != CategoryEditorStatus.saving;
}
