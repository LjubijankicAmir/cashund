import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/category_editor/bloc/category_editor_bloc.dart';
import 'package:cashund/presentation/category_editor/widgets/category_preview.dart';
import 'package:cashund/presentation/category_editor/widgets/color_swatches.dart';
import 'package:cashund/presentation/category_editor/widgets/emoji_grid.dart';
import 'package:cashund/presentation/common/widgets/form_field_row.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens the editor for a new category of [type], or to change [editing].
///
/// Returns the category as saved, or `null` if it was closed or archived.
Future<Category?> showCategoryEditor(
  BuildContext context, {
  required TransactionType type,
  Category? editing,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<CategoryEditorBloc>()
        ..add(
          CategoryEditorEvent.started(
            type: editing?.type ?? type,
            editing: editing,
            builtInName: l10n.categoryName,
          ),
        ),
      child: const CategoryEditorSheet(),
    ),
  );
}

class CategoryEditorSheet extends StatelessWidget {
  const CategoryEditorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<CategoryEditorBloc, CategoryEditorState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case CategoryEditorStatus.saved:
            Navigator.of(context).pop(state.saved);
          case CategoryEditorStatus.archived:
            Navigator.of(context).pop();
          case CategoryEditorStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.categoryEditorSaveFailed)),
            );
          case CategoryEditorStatus.editing || CategoryEditorStatus.saving:
            break;
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: const FractionallySizedBox(heightFactor: 0.92, child: _Editor()),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoryEditorBloc>();
    final state = context.watch<CategoryEditorBloc>().state;
    final typeName = state.type == TransactionType.expense
        ? l10n.transactionExpense
        : l10n.transactionIncome;
    final original = state.original;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s2,
            CashundSpace.s4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isNew ? l10n.newCategory : l10n.categoryEditorEdit,
                      style: CashundText.pageTitle.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      state.isBuiltIn
                          ? l10n.categoryEditorBuiltIn(typeName)
                          : typeName,
                      style: CashundText.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s5,
              CashundSpace.s6,
              CashundSpace.s6,
            ),
            children: [
              if (state.currencyCode case final currencyCode?) ...[
                FormFieldRow(
                  label: l10n.categoryEditorPreview,
                  child: CategoryPreview(
                    currencyCode: currencyCode,
                    category: Category(
                      id: original?.id ?? 0,
                      type: state.type,
                      emoji: state.emoji,
                      color: state.color,
                      sortOrder: 0,
                      // Shown as typed, or as the default name until then.
                      customName: state.trimmedName.isEmpty
                          ? null
                          : state.trimmedName,
                      predefinedKey: original?.predefinedKey,
                    ),
                  ),
                ),
                const SizedBox(height: CashundSpace.s5),
              ],
              FormFieldRow(
                label: l10n.categoryEditorName,
                child: TextFormField(
                  initialValue: state.name,
                  // Rebuilt with the loaded name when editing.
                  key: ValueKey(original?.id),
                  autofocus: state.isNew,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (name) =>
                      bloc.add(CategoryEditorEvent.nameChanged(name)),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: state.isNameTaken
                        ? l10n.categoryEditorNameTaken
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: CashundSpace.s5),
              FormFieldRow(
                label: l10n.categoryEditorEmoji,
                child: state.isBuiltIn
                    ? _LockedEmoji(emoji: state.emoji)
                    : EmojiGrid(
                        selected: state.emoji,
                        onSelected: (emoji) =>
                            bloc.add(CategoryEditorEvent.emojiSelected(emoji)),
                      ),
              ),
              const SizedBox(height: CashundSpace.s5),
              FormFieldRow(
                label: l10n.categoryEditorColor,
                trailing: l10n.categoryColorName(state.color.name),
                child: ColorSwatches(
                  selected: state.color,
                  onSelected: (color) =>
                      bloc.add(CategoryEditorEvent.colorSelected(color)),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s3,
              CashundSpace.s6,
              CashundSpace.s4,
            ),
            child: state.isNew || original!.isArchived
                ? PrimaryButton(
                    label: state.isNew
                        ? l10n.categoryEditorSave
                        : l10n.categoryEditorSaveChanges,
                    onPressed: state.canSave
                        ? () =>
                              bloc.add(const CategoryEditorEvent.savePressed())
                        : null,
                  )
                : Row(
                    spacing: CashundSpace.s3,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => bloc.add(
                          const CategoryEditorEvent.archivePressed(),
                        ),
                        icon: const Icon(LucideIcons.archive),
                        label: Text(l10n.categoryEditorArchive),
                      ),
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.categoryEditorSaveChanges,
                          onPressed: state.canSave
                              ? () => bloc.add(
                                  const CategoryEditorEvent.savePressed(),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// A built-in category's emoji, which can't change.
class _LockedEmoji extends StatelessWidget {
  const _LockedEmoji({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CashundRadius.md),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const Spacer(),
          Icon(LucideIcons.lock, size: 16, color: muted),
          const SizedBox(width: CashundSpace.s2),
          Text(
            context.l10n.categoryEditorEmojiLocked,
            style: CashundText.bodySm.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
