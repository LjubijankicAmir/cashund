part of 'category_editor_bloc.dart';

@freezed
sealed class CategoryEditorEvent with _$CategoryEditorEvent {
  /// Opens the editor for a new category of [type], or for [editing].
  ///
  /// [builtInName] translates a built-in category's key into its default
  /// name, so names can be compared the way the user sees them.
  const factory CategoryEditorEvent.started({
    required TransactionType type,
    required String Function(String predefinedKey) builtInName,
    Category? editing,
  }) = _Started;

  const factory CategoryEditorEvent.nameChanged(String name) = _NameChanged;
  const factory CategoryEditorEvent.emojiSelected(String emoji) =
      _EmojiSelected;
  const factory CategoryEditorEvent.colorSelected(CategoryColor color) =
      _ColorSelected;
  const factory CategoryEditorEvent.savePressed() = _SavePressed;
  const factory CategoryEditorEvent.archivePressed() = _ArchivePressed;
}
