import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/form_field_row.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/data_settings/bloc/export_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks which transactions to export as CSV, then shares the file.
Future<void> showExportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<ExportBloc>()..add(const ExportEvent.started()),
      child: const _ExportSheet(),
    ),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  Future<void> _pickDay(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final state = context.read<ExportBloc>().state;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: state.today,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final bloc = context.read<ExportBloc>();
    final state = context.watch<ExportBloc>().state;
    final dateFormat = DateFormat.yMMMd(locale);

    return BlocListener<ExportBloc, ExportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ExportStatus.shared:
            Navigator.of(context).pop();
          case ExportStatus.failed:
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
          case ExportStatus.editing || ExportStatus.working:
            break;
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s2,
              CashundSpace.s6,
              CashundSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CashundSpace.s3,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.exportTitle,
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
                const SizedBox(height: CashundSpace.s2),
                for (final (option, label) in [
                  (ExportOption.allTime, l10n.exportAllTime),
                  (ExportOption.thisMonth, l10n.exportThisMonth),
                  (ExportOption.lastMonth, l10n.exportLastMonth),
                  (ExportOption.custom, l10n.exportCustom),
                ])
                  OptionCard(
                    title: label,
                    selected: option == state.option,
                    trailing: Text(
                      '${state.counts[option] ?? ''}',
                      style: CashundText.body.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: CashundText.amount.fontFeatures,
                      ),
                    ),
                    onTap: () => bloc.add(ExportEvent.optionSelected(option)),
                  ),
                if (state.option == ExportOption.custom)
                  Row(
                    spacing: CashundSpace.s3,
                    children: [
                      for (final (label, day, isFrom) in [
                        (l10n.exportFrom, state.customFrom, true),
                        (l10n.exportTo, state.customTo, false),
                      ])
                        Expanded(
                          child: FormFieldRow(
                            label: label,
                            child: Material(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                CashundRadius.md,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _pickDay(
                                  context,
                                  initial: day,
                                  onPicked: (picked) => bloc.add(
                                    ExportEvent.customRangeChanged(
                                      from: isFrom ? picked : state.customFrom,
                                      to: isFrom ? state.customTo : picked,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    CashundSpace.s4,
                                  ),
                                  child: Text(
                                    dateFormat.format(day),
                                    style: CashundText.bodyLg.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CashundSpace.s3,
                  children: [
                    Icon(
                      LucideIcons.sheet,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Text(
                        l10n.exportNote,
                        style: CashundText.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CashundSpace.s2),
                PrimaryButton(
                  label: l10n.exportButton(state.count),
                  onPressed: state.canExport
                      ? () => bloc.add(
                          ExportEvent.exportPressed(
                            (category) => category.name(l10n),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
