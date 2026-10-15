import 'dart:async';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/reaction/bloc/reaction_cubit.dart';
import 'package:cashund/presentation/transaction_form/transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Logging, changing and deleting transactions from anywhere under the main
// shell, where the buddy's reactions and the undo snackbar live.

/// Opens the add sheet. Something newly logged gets the buddy's reaction.
Future<void> logTransaction(
  BuildContext context, {
  TransactionType type = TransactionType.expense,
}) async {
  final reactions = context.read<ReactionCubit>()..dismiss();
  final messenger = ScaffoldMessenger.of(context);
  final result = await showTransactionSheet(context, type: type);
  if (result case TransactionSaved(
    :final transaction,
    :final category,
    isNew: true,
  )) {
    // One transient message at a time.
    messenger.hideCurrentSnackBar();
    await reactions.show(transaction, category);
  }
}

/// Opens [transaction] to change it. After a delete, offers [onUndo].
Future<void> editTransaction(
  BuildContext context,
  Transaction transaction, {
  required ValueChanged<Transaction> onUndo,
}) async {
  final result = await showTransactionSheet(context, editing: transaction);
  if (result case TransactionDeleted(:final category) when context.mounted) {
    offerUndo(context, transaction, category: category, onUndo: onUndo);
  }
}

/// "Deleted “Lunch with Sara”" with an Undo button, for 5 seconds.
void offerUndo(
  BuildContext context,
  Transaction deleted, {
  required Category? category,
  required ValueChanged<Transaction> onUndo,
}) {
  final l10n = context.l10n;
  final title = deleted.title;
  final name = title == null || title.isEmpty ? category?.name(l10n) : title;

  context.read<ReactionCubit>().dismiss();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          switch ((name, deleted.type)) {
            (final name?, _) => l10n.transactionDeletedNamed(name),
            (null, TransactionType.expense) => l10n.transactionDeletedExpense,
            (null, TransactionType.income) => l10n.transactionDeletedIncome,
          },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => onUndo(deleted),
        ),
      ),
    );
}
