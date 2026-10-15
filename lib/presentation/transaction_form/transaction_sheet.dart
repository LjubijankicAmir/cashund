import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/transaction_form/bloc/transaction_form_bloc.dart';
import 'package:cashund/presentation/transaction_form/widgets/category_picker.dart';
import 'package:cashund/presentation/transaction_form/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What happened in the transaction sheet, if anything.
sealed class TransactionSheetResult {
  const TransactionSheetResult(this.transaction);

  final Transaction transaction;
}

/// The transaction was logged ([isNew]) or changed.
final class TransactionSaved extends TransactionSheetResult {
  const TransactionSaved(
    super.transaction, {
    required this.category,
    required this.isNew,
  });

  final Category category;
  final bool isNew;
}

/// The transaction was deleted, so the caller can offer to undo it.
final class TransactionDeleted extends TransactionSheetResult {
  const TransactionDeleted(super.transaction, {this.category});

  /// `null` when its category is archived, so not in the form's list.
  final Category? category;
}

/// Opens the sheet to log a new transaction of [type], or to change or
/// delete [editing]. The only way to log a transaction by hand.
///
/// Resolves to `null` when closed without saving or deleting.
Future<TransactionSheetResult?> showTransactionSheet(
  BuildContext context, {
  TransactionType type = TransactionType.expense,
  Transaction? editing,
}) {
  return showModalBottomSheet<TransactionSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, bottom bar included, from whichever tab opens it.
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<TransactionFormBloc>()
        ..add(switch (editing) {
          final transaction? => TransactionFormEvent.editStarted(transaction),
          null => TransactionFormEvent.started(type),
        }),
      child: const TransactionSheet(),
    ),
  );
}

/// The form, and the category picker sliding over it within the same sheet.
class TransactionSheet extends StatefulWidget {
  const TransactionSheet({super.key});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  var _choosingCategory = false;

  void _showPicker(bool show) {
    FocusScope.of(context).unfocus();
    setState(() => _choosingCategory = show);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<TransactionFormBloc, TransactionFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case TransactionFormStatus.saved:
            Navigator.of(context).pop(
              TransactionSaved(
                state.saved!,
                category: state.selectedCategory!,
                isNew: !state.isEditing,
              ),
            );
          case TransactionFormStatus.deleted:
            Navigator.of(context).pop(
              TransactionDeleted(
                state.original!,
                category: state.selectedCategory,
              ),
            );
          case TransactionFormStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addTransactionSaveFailed)),
            );
          case TransactionFormStatus.editing || TransactionFormStatus.saving:
            break;
        }
      },
      // In the picker, back returns to the form instead of closing the sheet.
      child: PopScope(
        canPop: !_choosingCategory,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showPicker(false);
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final fromRight = child.key == const ValueKey('picker');
                return SlideTransition(
                  position: Tween(
                    begin: Offset(fromRight ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: _choosingCategory
                  ? CategoryPicker(
                      key: const ValueKey('picker'),
                      onBack: () => _showPicker(false),
                    )
                  : TransactionForm(
                      key: const ValueKey('form'),
                      onChooseCategory: () => _showPicker(true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
