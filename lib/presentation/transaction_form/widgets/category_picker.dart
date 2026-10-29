import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/category_editor/category_editor_sheet.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/transaction_form/bloc/transaction_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks the category inside the add sheet: search, recent ones, then all.
class CategoryPicker extends StatefulWidget {
  const CategoryPicker({required this.onBack, super.key});

  /// Returns to the form, after a pick or from the back button.
  final VoidCallback onBack;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  String _query = '';

  void _pick(Category category) {
    context.read<TransactionFormBloc>().add(
      TransactionFormEvent.categorySelected(category.id),
    );
    widget.onBack();
  }

  /// Opens the editor; a category made there is picked right away.
  Future<void> _create() async {
    final type = context.read<TransactionFormBloc>().state.type;
    final created = await showCategoryEditor(context, type: type);
    if (created != null && mounted) _pick(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<TransactionFormBloc>().state;
    final query = _query.trim().toLowerCase();
    final matching = [
      for (final category in state.categories)
        if (category.name(l10n).toLowerCase().contains(query)) category,
    ];
    final sectionStyle = CashundText.labelSm.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: CashundSpace.s5,
        bottom: CashundSpace.s1,
      ),
      child: Text(title, style: sectionStyle),
    );

    List<Widget> rows(List<Category> categories) => [
      for (final (index, category) in categories.indexed) ...[
        if (index > 0) const Divider(),
        _CategoryRow(
          category: category,
          selected: category.id == state.categoryId,
          onTap: () => _pick(category),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s5),
          child: Row(
            spacing: CashundSpace.s3,
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed: widget.onBack,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Expanded(
                child: Text(
                  l10n.categoryPickerTitle,
                  style: CashundText.pageTitle.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s4,
            CashundSpace.s6,
            0,
          ),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.categoryPickerSearchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              0,
              CashundSpace.s6,
              CashundSpace.s4,
            ),
            children: [
              if (query.isEmpty) ...[
                if (state.recentCategories.isNotEmpty) ...[
                  section(l10n.categoryPickerRecent),
                  ...rows(state.recentCategories),
                ],
                section(
                  state.type == TransactionType.expense
                      ? l10n.categoryPickerAllExpense
                      : l10n.categoryPickerAllIncome,
                ),
                ...rows(state.categories),
              ] else if (matching.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: CashundSpace.s6,
                  ),
                  child: Text(
                    l10n.categoryPickerNoResults(_query.trim()),
                    textAlign: TextAlign.center,
                    style: CashundText.body.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else ...[
                const SizedBox(height: CashundSpace.s3),
                ...rows(matching),
              ],
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s6,
                CashundSpace.s4,
                CashundSpace.s6,
                CashundSpace.s4,
              ),
              child: FilledButton.tonalIcon(
                onPressed: _create,
                icon: const Icon(LucideIcons.plus),
                label: Text(l10n.newCategory),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            spacing: CashundSpace.s3,
            children: [
              CategoryMark(color: category.color),
              Expanded(
                child: Text(
                  category.label(context.l10n),
                  style: CashundText.bodyLg.copyWith(
                    color: scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) Icon(LucideIcons.check, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
