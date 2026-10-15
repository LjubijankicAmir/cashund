import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/categories/bloc/categories_bloc.dart';
import 'package:cashund/presentation/categories/widgets/active_category_row.dart';
import 'package:cashund/presentation/category_editor/category_editor_sheet.dart';
import 'package:cashund/presentation/common/widgets/category_list_row.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every category of one type: reorder, archive, restore, edit or add.
@RoutePage()
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CategoriesBloc>()
            ..add(const CategoriesEvent.typeSelected(TransactionType.expense)),
      child: BlocListener<CategoriesBloc, CategoriesState>(
        listenWhen: (previous, current) =>
            !previous.saveFailed && current.saveFailed,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(content: Text(context.l10n.categoriesSaveFailed)),
            ),
        child: const _CategoriesView(),
      ),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  var _archivedExpanded = false;

  static const _sidePadding = EdgeInsets.symmetric(horizontal: CashundSpace.s6);

  void _edit(Category category) {
    unawaited(
      showCategoryEditor(context, type: category.type, editing: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final state = context.watch<CategoriesBloc>().state;
    final active = state.active;
    final archived = state.archived;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      CashundSpace.s6,
                      CashundSpace.s3,
                      CashundSpace.s6,
                      CashundSpace.s4,
                    ),
                    sliver: SliverList.list(
                      children: [
                        PushedPageHeader(title: l10n.settingsCategories),
                        const SizedBox(height: CashundSpace.s5),
                        SegmentedPills(
                          stretch: true,
                          segments: [
                            (TransactionType.expense, l10n.activityExpenses),
                            (TransactionType.income, l10n.activityIncomes),
                          ],
                          selected: state.type,
                          onChanged: (type) {
                            setState(() => _archivedExpanded = false);
                            bloc.add(CategoriesEvent.typeSelected(type));
                          },
                        ),
                        const SizedBox(height: CashundSpace.s4),
                        Text(
                          l10n.categoriesHint,
                          style: CashundText.body.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active.isNotEmpty)
                    SliverPadding(
                      padding: _sidePadding,
                      sliver: DecoratedSliver(
                        decoration: _cardDecoration(theme),
                        sliver: SliverReorderableList(
                          itemCount: active.length,
                          // The new index already counts without the moved row.
                          onReorderItem: (oldIndex, newIndex) => bloc.add(
                            CategoriesEvent.reordered(oldIndex, newIndex),
                          ),
                          proxyDecorator: (child, _, _) =>
                              LiftedCategoryRow(child: child),
                          itemBuilder: (context, index) {
                            final category = active[index];
                            return ActiveCategoryRow(
                              key: ValueKey(category.id),
                              category: category,
                              index: index,
                              showDivider: index > 0,
                              onEdit: () => _edit(category),
                              onArchive: () => bloc.add(
                                CategoriesEvent.archived(category.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (archived.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        CashundSpace.s6,
                        CashundSpace.s5,
                        CashundSpace.s6,
                        CashundSpace.s6,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _ArchivedHeader(
                            count: archived.length,
                            expanded: _archivedExpanded,
                            onToggle: () => setState(
                              () => _archivedExpanded = !_archivedExpanded,
                            ),
                          ),
                          if (_archivedExpanded) ...[
                            const SizedBox(height: CashundSpace.s3),
                            DecoratedBox(
                              decoration: _cardDecoration(theme),
                              child: Column(
                                children: [
                                  for (final (index, category)
                                      in archived.indexed) ...[
                                    if (index > 0) _divider(scheme),
                                    CategoryListRow(
                                      category: category,
                                      trailing: [
                                        TextButton.icon(
                                          onPressed: () => bloc.add(
                                            CategoriesEvent.restored(
                                              category.id,
                                            ),
                                          ),
                                          icon: const Icon(
                                            LucideIcons.rotateCcw,
                                            size: 18,
                                          ),
                                          label: Text(l10n.categoriesRestore),
                                        ),
                                        const SizedBox(width: CashundSpace.s2),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: CashundSpace.s3),
                            Text(
                              l10n.categoriesArchivedNote,
                              style: CashundText.body.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    const SliverToBoxAdapter(
                      child: SizedBox(height: CashundSpace.s6),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: CashundSpace.s4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CashundSpace.s6,
                    CashundSpace.s4,
                    CashundSpace.s6,
                    0,
                  ),
                  child: FilledButton.tonalIcon(
                    onPressed: () => unawaited(
                      showCategoryEditor(context, type: state.type),
                    ),
                    icon: const Icon(LucideIcons.plus),
                    label: Text(l10n.newCategory),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration(ThemeData theme) {
    final scheme = theme.colorScheme;
    return BoxDecoration(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(CashundRadius.lg),
      // On the dark page the card needs an edge to stand out.
      border: theme.brightness == Brightness.dark
          ? Border.all(color: scheme.outlineVariant)
          : null,
    );
  }

  static Widget _divider(ColorScheme scheme) => Divider(
    height: 1,
    indent: CashundSpace.s4,
    endIndent: CashundSpace.s4,
    color: scheme.outlineVariant,
  );
}

/// "Archived · N", tapping it shows or hides the archived categories.
class _ArchivedHeader extends StatelessWidget {
  const _ArchivedHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(CashundRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CashundSpace.s1,
            vertical: CashundSpace.s2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.categoriesArchived(count),
                  style: CashundText.label.copyWith(color: muted),
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronDown, size: 20, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
