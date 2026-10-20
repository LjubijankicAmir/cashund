import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/limits/bloc/limit_editor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks what a new limit is on: all spending first, then categories without
/// a limit for the period, then the ones that already have one (disabled).
class LimitTargetPicker extends StatelessWidget {
  const LimitTargetPicker({required this.onPicked, super.key});

  /// Returns to the form, after a pick or from the back button.
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<LimitEditorBloc>();
    final state = context.watch<LimitEditorBloc>().state;
    final period = state.period.name;

    SpendingLimit? limitOn(int? categoryId) {
      for (final limit in state.limits) {
        if (limit.period == state.period && limit.categoryId == categoryId) {
          return limit;
        }
      }
      return null;
    }

    final available = [
      for (final category in state.categories)
        if (limitOn(category.id) == null) category,
    ];
    final taken = [
      for (final category in state.categories)
        if (limitOn(category.id) != null) category,
    ];
    final overallTaken = limitOn(null) != null;

    void pick(LimitTarget target) {
      bloc.add(LimitEditorEvent.targetChosen(target));
      onPicked();
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: CashundSpace.s5,
        bottom: CashundSpace.s1,
      ),
      child: Text(
        title,
        style: CashundText.labelSm.copyWith(color: scheme.onSurfaceVariant),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s4,
            CashundSpace.s2,
            CashundSpace.s6,
            0,
          ),
          child: Row(
            spacing: CashundSpace.s2,
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Expanded(
                child: Text(
                  l10n.limitPickerTitle(period),
                  style: CashundText.title.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s2,
              CashundSpace.s6,
              CashundSpace.s6,
            ),
            children: [
              _TargetRow(
                text: l10n.limitAllSpending,
                note: overallTaken ? l10n.limitPickerHasLimit(period) : null,
                selected: state.target == const LimitTarget.overall(),
                onTap: overallTaken
                    ? null
                    : () => pick(const LimitTarget.overall()),
              ),
              if (available.isNotEmpty) ...[
                section(l10n.limitPickerAvailable(period)),
                for (final (index, category) in available.indexed) ...[
                  if (index > 0) const Divider(),
                  _TargetRow(
                    category: category,
                    text: category.label(l10n),
                    selected: state.target == LimitTarget.category(category),
                    onTap: () => pick(LimitTarget.category(category)),
                  ),
                ],
              ],
              if (taken.isNotEmpty) ...[
                section(l10n.limitPickerTaken(period)),
                for (final (index, category) in taken.indexed) ...[
                  if (index > 0) const Divider(),
                  _TargetRow(
                    category: category,
                    text: category.label(l10n),
                    selected: false,
                    onTap: null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.text,
    required this.selected,
    required this.onTap,
    this.category,
    this.note,
  });

  final Category? category;
  final String text;

  /// Why it's disabled, e.g. "Has a weekly limit".
  final String? note;
  final bool selected;

  /// `null` disables the row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Semantics(
        selected: selected,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              spacing: CashundSpace.s3,
              children: [
                if (category case final category?)
                  CategoryMark(color: category.color),
                Expanded(
                  child: Text(
                    text,
                    style: CashundText.bodyLg.copyWith(
                      color: scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                if (note case final note?)
                  Text(
                    note,
                    style: CashundText.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (selected)
                  Icon(LucideIcons.check, size: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
