import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/add_transaction/bloc/add_transaction_bloc.dart';
import 'package:cashund/presentation/add_transaction/widgets/category_picker.dart';
import 'package:cashund/presentation/add_transaction/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the add sheet for [type]. The only way to log a transaction by hand.
Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionType type = TransactionType.expense,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Over the whole app, bottom bar included, from whichever tab opens it.
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<AddTransactionBloc>()..add(AddTransactionEvent.started(type)),
      child: const AddTransactionSheet(),
    ),
  );
}

/// The form, and the category picker sliding over it within the same sheet.
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  var _choosingCategory = false;

  void _showPicker(bool show) {
    FocusScope.of(context).unfocus();
    setState(() => _choosingCategory = show);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<AddTransactionBloc, AddTransactionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case AddTransactionStatus.saved:
            Navigator.of(context).pop();
          case AddTransactionStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addTransactionSaveFailed)),
            );
          case AddTransactionStatus.editing || AddTransactionStatus.saving:
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
