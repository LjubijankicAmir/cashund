import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/common/widgets/form_field_row.dart';
import 'package:cashund/presentation/common/widgets/picker_field.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/quick_chip.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:cashund/presentation/transaction_form/bloc/transaction_form_bloc.dart';
import 'package:cashund/presentation/transaction_form/widgets/amount_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The add form: type, amount, category, title and date.
class TransactionForm extends StatelessWidget {
  const TransactionForm({required this.onChooseCategory, super.key});

  final VoidCallback onChooseCategory;

  Future<void> _pickDate(
    BuildContext context,
    TransactionFormState state,
  ) async {
    final bloc = context.read<TransactionFormBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2000),
      lastDate: state.today,
    );
    if (picked != null) bloc.add(TransactionFormEvent.dateSelected(picked));
  }

  String _dateText(
    AppLocalizations l10n,
    String locale,
    TransactionFormState state,
  ) {
    final yesterday = DateTime(
      state.today.year,
      state.today.month,
      state.today.day - 1,
    );
    final day = DateFormat('EEE MMM d', locale).format(state.date);
    if (state.date == state.today) return l10n.addTransactionToday(day);
    if (state.date == yesterday) return l10n.addTransactionYesterday(day);
    return DateFormat.MMMEd(locale).format(state.date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<TransactionFormBloc>();
    final state = context.watch<TransactionFormBloc>().state;
    final isExpense = state.type == TransactionType.expense;
    final category = state.selectedCategory;
    final yesterday = DateTime(
      state.today.year,
      state.today.month,
      state.today.day - 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            0,
            CashundSpace.s4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  switch ((state.isEditing, isExpense)) {
                    (false, true) => l10n.addTransactionNewExpense,
                    (false, false) => l10n.addTransactionNewIncome,
                    (true, true) => l10n.editTransactionExpense,
                    (true, false) => l10n.editTransactionIncome,
                  },
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
              SegmentedPills(
                stretch: true,
                segments: [
                  (TransactionType.expense, l10n.transactionExpense),
                  (TransactionType.income, l10n.transactionIncome),
                ],
                selected: state.type,
                onChanged: (type) =>
                    bloc.add(TransactionFormEvent.typeChanged(type)),
              ),
              const SizedBox(height: CashundSpace.s8),
              if (state.currency case final currency?)
                AmountInput(
                  currency: currency,
                  initialText: state.amountText,
                  onChanged: (text) =>
                      bloc.add(TransactionFormEvent.amountChanged(text)),
                ),
              const SizedBox(height: CashundSpace.s8),
              FormFieldRow(
                label: l10n.addTransactionCategory,
                child: PickerField(
                  leading: category == null
                      ? null
                      : CategoryMark(color: category.color),
                  text:
                      category?.label(l10n) ??
                      l10n.addTransactionChooseCategory,
                  placeholder: category == null,
                  onTap: onChooseCategory,
                ),
              ),
              const SizedBox(height: CashundSpace.s5),
              FormFieldRow(
                label: l10n.addTransactionTitle,
                optional: true,
                child: TextFormField(
                  initialValue: state.title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 200,
                  onChanged: (title) =>
                      bloc.add(TransactionFormEvent.titleChanged(title)),
                  decoration: InputDecoration(
                    hintText: l10n.addTransactionTitleHint,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: CashundSpace.s5),
              FormFieldRow(
                label: l10n.addTransactionDate,
                child: PickerField(
                  leading: Icon(
                    LucideIcons.calendar,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  text: _dateText(l10n, locale, state),
                  onTap: () => _pickDate(context, state),
                ),
              ),
              const SizedBox(height: CashundSpace.s3),
              Wrap(
                spacing: CashundSpace.s2,
                children: [
                  QuickChip(
                    label: l10n.today,
                    selected: state.date == state.today,
                    onTap: () => bloc.add(
                      TransactionFormEvent.dateSelected(state.today),
                    ),
                  ),
                  QuickChip(
                    label: l10n.yesterday,
                    selected: state.date == yesterday,
                    onTap: () =>
                        bloc.add(TransactionFormEvent.dateSelected(yesterday)),
                  ),
                ],
              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CashundSpace.s2,
              children: [
                PrimaryButton(
                  label: state.isEditing
                      ? l10n.editTransactionSave
                      : isExpense
                      ? l10n.addTransactionSaveExpense
                      : l10n.addTransactionSaveIncome,
                  onPressed: state.canSave
                      ? () => bloc.add(const TransactionFormEvent.savePressed())
                      : null,
                ),
                if (state.isEditing)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error, width: 1.5),
                    ),
                    onPressed: state.status == TransactionFormStatus.saving
                        ? null
                        : () => bloc.add(
                            const TransactionFormEvent.deletePressed(),
                          ),
                    child: Text(l10n.editTransactionDelete),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
