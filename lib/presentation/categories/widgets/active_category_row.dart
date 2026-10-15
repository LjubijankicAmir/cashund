import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_list_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An active category on the categories page: tap to edit, drag the grip
/// (or long-press anywhere) to reorder, swipe left or use the menu to
/// archive.
class ActiveCategoryRow extends StatelessWidget {
  const ActiveCategoryRow({
    required this.category,
    required this.index,
    required this.showDivider,
    required this.onEdit,
    required this.onArchive,
    super.key,
  });

  final Category category;

  /// Its position in the reorderable list.
  final int index;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final name = category.name(l10n);

    return ReorderableDelayedDragStartListener(
      index: index,
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.categoriesArchive): onArchive,
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDivider)
              Divider(
                height: 1,
                indent: CashundSpace.s4,
                endIndent: CashundSpace.s4,
                color: scheme.outlineVariant,
              ),
            Dismissible(
              key: ValueKey(category.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onArchive(),
              background: ColoredBox(
                color: scheme.primary,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        Icon(LucideIcons.archive, color: scheme.onPrimary),
                        Text(
                          l10n.categoriesArchive,
                          style: CashundText.labelSm.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: CategoryListRow(
                category: category,
                onTap: onEdit,
                trailing: [
                  PopupMenuButton<VoidCallback>(
                    tooltip: l10n.categoriesMoreOptions(name),
                    icon: Icon(
                      LucideIcons.ellipsisVertical,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    onSelected: (action) => action(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: onEdit,
                        child: _MenuItem(
                          icon: LucideIcons.pencil,
                          label: l10n.categoriesEdit,
                        ),
                      ),
                      PopupMenuItem(
                        value: onArchive,
                        child: _MenuItem(
                          icon: LucideIcons.archive,
                          label: l10n.categoriesArchive,
                        ),
                      ),
                    ],
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      label: l10n.categoriesDragHandle(name),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(
                          LucideIcons.gripVertical,
                          size: 20,
                          color: LiftedCategoryRow.isLifted(context)
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: CashundSpace.s3,
      children: [Icon(icon, size: 20), Text(label)],
    );
  }
}

/// The row being dragged: raised above the list, with its grip in primary.
class LiftedCategoryRow extends InheritedWidget {
  LiftedCategoryRow({required Widget child, super.key})
    : super(child: _Raised(child: child));

  /// Whether [context] is inside the row being dragged.
  static bool isLifted(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiftedCategoryRow>() != null;

  @override
  bool updateShouldNotify(LiftedCategoryRow oldWidget) => false;
}

class _Raised extends StatelessWidget {
  const _Raised({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(CashundRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
