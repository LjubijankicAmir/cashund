import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/transaction_form/bloc/transaction_form_bloc.dart';
import 'package:cashund/presentation/transaction_form/widgets/category_picker.dart';
import 'package:cashund/presentation/transaction_form/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the sheet to log a new transaction of [type], or to change or
/// delete [editing]. The only way to log a transaction by hand.
///
/// Returns the transaction if it was deleted, so the caller can offer undo.
Future<Transaction?> showTransactionSheet(
  BuildContext context, {
  TransactionType type = TransactionType.expense,
  Transaction? editing,
}) {
  return showModalBottomSheet<Transaction>(
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
            Navigator.of(context).pop();
          case TransactionFormStatus.deleted:
            // Hands the deleted transaction back, so the caller can offer undo.
            Navigator.of(context).pop(state.original);
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
