import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/category_editor/bloc/category_editor_bloc.dart';
import 'package:cashund/presentation/category_editor/widgets/emoji_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The suggested emoji, then a cell that opens a picker with every other
/// one. An emoji picked there takes that last cell.
class EmojiGrid extends StatelessWidget {
  const EmojiGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _columns = 8;

  Future<void> _pickOther(BuildContext context) async {
    final emoji = await showEmojiPicker(context);
    if (emoji != null) onSelected(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final other = suggestedCategoryEmoji.contains(selected) ? null : selected;

    return GridView.count(
      crossAxisCount: _columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: CashundSpace.s2,
      crossAxisSpacing: CashundSpace.s1,
      children: [
        for (final emoji in suggestedCategoryEmoji)
          _Cell(
            selected: emoji == selected,
            onTap: () => onSelected(emoji),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        _Cell(
          selected: other != null,
          background: other == null ? scheme.surfaceContainerHighest : null,
          semanticLabel: context.l10n.categoryEditorOtherEmoji,
          onTap: () => _pickOther(context),
          child: other == null
              ? Icon(LucideIcons.smile, color: scheme.onSurfaceVariant)
              : Text(other, style: const TextStyle(fontSize: 22)),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.selected,
    required this.onTap,
    required this.child,
    this.background,
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color? background;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Center(
        child: Material(
          color: background ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CashundRadius.md),
            side: selected
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(dimension: 40, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
