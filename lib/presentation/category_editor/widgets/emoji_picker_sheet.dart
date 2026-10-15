import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as picker;
import 'package:flutter/material.dart';

/// Opens a picker with every emoji, by category and with search. Resolves
/// to the chosen emoji, or `null` if closed without one.
Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _EmojiPickerSheet(),
  );
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.surfaceContainerHigh;
    final muted = scheme.onSurfaceVariant;

    return SafeArea(
      child: Padding(
        // Room for the keyboard while searching.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: picker.EmojiPicker(
          onEmojiSelected: (_, emoji) => Navigator.of(context).pop(emoji.emoji),
          config: picker.Config(
            height: 360,
            locale: Localizations.localeOf(context),
            emojiViewConfig: picker.EmojiViewConfig(
              columns: 8,
              backgroundColor: background,
              noRecents: Text(
                l10n.emojiPickerNoRecents,
                textAlign: TextAlign.center,
                style: CashundText.body.copyWith(color: muted),
              ),
            ),
            categoryViewConfig: picker.CategoryViewConfig(
              backgroundColor: background,
              indicatorColor: scheme.primary,
              iconColor: muted,
              iconColorSelected: scheme.primary,
              dividerColor: scheme.outlineVariant,
            ),
            bottomActionBarConfig: picker.BottomActionBarConfig(
              // Only the search button; there's nothing to backspace.
              showBackspaceButton: false,
              backgroundColor: background,
              buttonColor: background,
              buttonIconColor: muted,
            ),
            searchViewConfig: picker.SearchViewConfig(
              backgroundColor: background,
              buttonIconColor: muted,
              hintText: l10n.emojiPickerSearchHint,
              inputTextStyle: CashundText.body.copyWith(
                color: scheme.onSurface,
              ),
              hintTextStyle: CashundText.body.copyWith(color: muted),
            ),
          ),
        ),
      ),
    );
  }
}
