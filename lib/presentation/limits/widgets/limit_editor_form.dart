import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/amount_input.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/common/widgets/form_field_row.dart';
import 'package:cashund/presentation/common/widgets/limit_row.dart';
import 'package:cashund/presentation/common/widgets/picker_field.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:cashund/presentation/limits/bloc/limit_editor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The limit editor's fields: period, what it's on, the amount and a preview.
class LimitEditorForm extends StatelessWidget {
  const LimitEditorForm({required this.onChooseTarget, super.key});

  final VoidCallback onChooseTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<LimitEditorBloc>();
    final state = context.watch<LimitEditorBloc>().state;
    final (currency, preview) = (state.currency, state.preview);

    final targetText = switch (state.target) {
      CategoryTarget(:final category) => category.label(l10n),
      OverallTarget() => l10n.limitAllSpending,
      null => l10n.limitEditorChooseCategory,
    };
    final targetMark = switch (state.target) {
      CategoryTarget(:final category) => CategoryMark(color: category.color),
      _ => null,
    };

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
                child: Text(
                  state.isEditing ? l10n.limitEditorEdit : l10n.limitEditorNew,
                  style: CashundText.pageTitle.copyWith(
                    color: scheme.onSurface,
                  ),
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
              if (!state.isEditing) ...[
                FormFieldRow(
                  label: l10n.limitEditorPeriod,
                  child: SegmentedPills(
                    stretch: true,
                    segments: [
                      (LimitPeriod.week, l10n.limitPeriodWeek),
                      (LimitPeriod.month, l10n.limitPeriodMonth),
                    ],
                    selected: state.period,
                    onChanged: (period) =>
                        bloc.add(LimitEditorEvent.periodChanged(period)),
                  ),
                ),
                const SizedBox(height: CashundSpace.s5),
              ],
              FormFieldRow(
                label: l10n.limitEditorCategory,
                child: state.isEditing
                    ? _FixedField(text: targetText, leading: targetMark)
                    : PickerField(
                        leading: targetMark,
                        text: targetText,
                        placeholder: state.target == null,
                        onTap: onChooseTarget,
                      ),
              ),
              const SizedBox(height: CashundSpace.s5),
              FormFieldRow(
                label: l10n.limitEditorAmount(state.period.name),
                child: currency == null
                    ? const SizedBox(height: 58)
                    : AmountInput(
                        currency: currency,
                        initialText: state.amountText,
                        onChanged: (text) =>
                            bloc.add(LimitEditorEvent.amountChanged(text)),
                      ),
              ),
              if (preview != null && currency != null) ...[
                const SizedBox(height: CashundSpace.s6),
                FormFieldRow(
                  label: l10n.limitEditorPreview,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(CashundRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(CashundSpace.s4),
                      child: LimitRow(
                        progress: preview,
                        currency: currency,
                        today: state.today,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: CashundSpace.s3),
                Text(
                  preview.status == LimitStatus.under
                      ? l10n.limitEditorPreviewNote(state.period.name)
                      : l10n.limitEditorPreviewHeadsUp(
                          state.period.name,
                          state.preferences?.buddyName ?? '',
                        ),
                  style: CashundText.bodySm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: CashundSpace.s4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s2,
              CashundSpace.s6,
              0,
            ),
            child: Row(
              spacing: CashundSpace.s3,
              children: [
                if (state.isEditing)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error, width: 1.5),
                    ),
                    onPressed: state.status == LimitEditorStatus.saving
                        ? null
                        : () =>
                              bloc.add(const LimitEditorEvent.deletePressed()),
                    icon: const Icon(LucideIcons.trash2, size: 20),
                    label: Text(l10n.limitEditorDelete),
                  ),
                Expanded(
                  child: PrimaryButton(
                    label: state.isEditing
                        ? l10n.limitEditorSaveChanges
                        : l10n.limitEditorSave,
                    onPressed: state.canSave
                        ? () => bloc.add(const LimitEditorEvent.savePressed())
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

/// A field that can't change, with a lock and "Fixed".
class _FixedField extends StatelessWidget {
  const _FixedField({required this.text, this.leading});

  final String text;
  final Widget? leading;

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
        spacing: CashundSpace.s3,
        children: [
          ?leading,
          Expanded(
            child: Text(
              text,
              style: CashundText.bodyLg.copyWith(color: scheme.onSurface),
            ),
          ),
          Icon(LucideIcons.lock, size: 16, color: muted),
          Text(
            context.l10n.limitEditorFixed,
            style: CashundText.bodySm.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
