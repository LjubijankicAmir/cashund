import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/presentation/common/widgets/confirm_sheet.dart';
import 'package:cashund/presentation/data_settings/bloc/data_bloc.dart';
import 'package:cashund/presentation/data_settings/widgets/file_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What happens around Settings › Data's actions, wherever in Settings they
/// start: snackbars for backups, the restore sheets, and starting over.
class DataFlows extends StatelessWidget {
  const DataFlows({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DataBloc, DataState>(
          listenWhen: (previous, current) => previous.backup != current.backup,
          listener: (context, state) {
            final l10n = context.l10n;
            final message = switch (state.backup) {
              DataActionStatus.done => l10n.dataBackupSaved(
                state.counts?.transactions ?? 0,
              ),
              DataActionStatus.failed => l10n.dataBackupFailed,
              _ => null,
            };
            if (message != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            }
          },
        ),
        BlocListener<DataBloc, DataState>(
          listenWhen: (previous, current) =>
              previous.restore != current.restore,
          listener: (context, state) =>
              unawaited(_onRestoreStep(context, state.restore)),
        ),
        BlocListener<DataBloc, DataState>(
          listenWhen: (previous, current) => previous.delete != current.delete,
          listener: (context, state) {
            switch (state.delete) {
              case DataActionStatus.done:
                // Nothing left: start over, with no way back.
                unawaited(context.router.root.replaceAll([OnboardingRoute()]));
              case DataActionStatus.failed:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.deleteFailed)),
                );
              case DataActionStatus.idle || DataActionStatus.working:
                break;
            }
          },
        ),
      ],
      child: child,
    );
  }

  Future<void> _onRestoreStep(BuildContext context, RestoreStep step) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<DataBloc>();
    String day(BackupInfo info) =>
        DateFormat.yMMMd(locale).format(info.createdAt);

    switch (step) {
      case RestoreConfirming(:final file, :final info):
        final current = bloc.state.counts?.transactions ?? 0;
        final choice = await showChoiceSheet(
          context,
          icon: LucideIcons.download,
          title: l10n.restoreTitle,
          content: FileCard(
            name: file.name,
            meta: l10n.restoreFileMeta(day(info), info.transactionCount),
          ),
          notes: [
            (
              icon: LucideIcons.circleAlert,
              text: TextSpan(text: l10n.restoreReplaceNote(current)),
            ),
            (
              icon: LucideIcons.shield,
              text: TextSpan(text: l10n.restoreKeepNote),
            ),
          ],
          confirmLabel: l10n.restoreReplace,
          secondaryLabel: l10n.restoreBackUpFirst,
        );
        switch (choice) {
          case true:
            bloc.add(const DataEvent.restoreConfirmed());
          case false:
            bloc
              ..add(const DataEvent.restoreCancelled())
              ..add(const DataEvent.backupPressed());
          case null:
            bloc.add(const DataEvent.restoreCancelled());
        }
      case RestoreDone(:final info):
        if (!context.mounted) return;
        await showChoiceSheet(
          context,
          icon: LucideIcons.check,
          tone: ConfirmTone.success,
          title: l10n.restoreDoneTitle,
          body: l10n.restoreDoneBody(info.transactionCount, day(info)),
          confirmLabel: l10n.restoreGoHome,
        );
        bloc.add(const DataEvent.restoreCancelled());
        if (context.mounted) {
          unawaited(context.router.root.replaceAll([const MainShellRoute()]));
        }
      case RestoreFailed(:final fileName):
        final choice = await showChoiceSheet(
          context,
          icon: LucideIcons.fileX,
          tone: ConfirmTone.error,
          title: l10n.restoreFailedTitle,
          body: l10n.restoreFailedBody,
          content: fileName == null ? null : FileCard(name: fileName),
          confirmLabel: l10n.restoreChooseAnother,
          secondaryLabel: l10n.dataCancel,
        );
        bloc.add(const DataEvent.restoreCancelled());
        if (choice ?? false) bloc.add(const DataEvent.restorePressed());
      case RestoreIdle() || RestoreRestoring():
        break;
    }
  }
}
