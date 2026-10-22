import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/settings_group.dart';
import 'package:cashund/presentation/data_settings/bloc/data_bloc.dart';
import 'package:cashund/presentation/data_settings/export_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings › Data: a reminder when a backup is due, back up, restore,
/// export, and on its own, deleting everything.
class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<DataBloc>();
    final state = context.watch<DataBloc>().state;
    final last = state.lastBackupAt;
    final day = DateTime(state.today.year, state.today.month, state.today.day);
    final age = last == null
        ? null
        : day.difference(DateTime(last.year, last.month, last.day)).inDays;
    final muted = scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.remindToBackUp) ...[
          _Reminder(
            text: age == null
                ? l10n.dataReminderNone
                : l10n.dataReminderOld(age),
            onBackUp: () => bloc.add(const DataEvent.backupPressed()),
          ),
          const SizedBox(height: CashundSpace.s4),
        ],
        SettingsGroup(
          label: l10n.settingsData,
          rows: [
            SettingsRow(
              leading: const Icon(LucideIcons.upload),
              title: l10n.dataBackUp,
              subtitle: last == null
                  ? l10n.dataNoBackup
                  : l10n.dataLastBackup(
                      DateFormat.MMMd(locale).format(last),
                      l10n.dataBackupAge(age!),
                    ),
              onTap: () => bloc.add(const DataEvent.backupPressed()),
            ),
            SettingsRow(
              leading: const Icon(LucideIcons.download),
              title: l10n.dataRestore,
              subtitle: l10n.dataRestoreSubtitle,
              onTap: () => bloc.add(const DataEvent.restorePressed()),
            ),
            SettingsRow(
              leading: const Icon(LucideIcons.sheet),
              title: l10n.dataExport,
              subtitle: l10n.dataExportSubtitle,
              onTap: () => unawaited(showExportSheet(context)),
            ),
          ],
        ),
        const SizedBox(height: CashundSpace.s4),
        // Alone and quiet: no red until the delete page itself.
        SettingsGroup(
          rows: [
            SettingsRow(
              leading: Icon(LucideIcons.trash2, color: muted),
              title: l10n.dataDelete,
              titleStyle: CashundText.body.copyWith(
                fontWeight: FontWeight.w500,
                color: muted,
              ),
              onTap: () => unawaited(
                context.router.push(const SettingsDeleteDataRoute()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gentle nudge to back up: never a warning.
class _Reminder extends StatelessWidget {
  const _Reminder({required this.text, required this.onBackUp});

  final String text;
  final VoidCallback onBackUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(CashundSpace.s4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(CashundRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CashundSpace.s3,
        children: [
          Icon(LucideIcons.shieldCheck, color: scheme.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CashundSpace.s3,
              children: [
                Text(
                  text,
                  style: CashundText.body.copyWith(color: scheme.onSurface),
                ),
                FilledButton(
                  onPressed: onBackUp,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: Text(context.l10n.dataBackUpNow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
