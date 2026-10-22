import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/surface_card.dart';
import 'package:cashund/presentation/data_settings/bloc/data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Deleting everything: the one place that uses the danger color, and only
/// after typing a word to confirm.
@RoutePage()
class SettingsDeleteDataScreen extends StatefulWidget {
  const SettingsDeleteDataScreen({super.key});

  @override
  State<SettingsDeleteDataScreen> createState() =>
      _SettingsDeleteDataScreenState();
}

class _SettingsDeleteDataScreenState extends State<SettingsDeleteDataScreen> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<DataBloc>();
    final state = context.watch<DataBloc>().state;
    final counts = state.counts;
    final muted = CashundText.body.copyWith(color: scheme.onSurfaceVariant);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CashundSpace.s6,
                  CashundSpace.s3,
                  CashundSpace.s6,
                  CashundSpace.s6,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: l10n.back,
                      onPressed: () => context.router.maybePop(),
                      icon: const Icon(LucideIcons.chevronLeft),
                    ),
                  ),
                  const SizedBox(height: CashundSpace.s4),
                  Text(
                    l10n.deleteTitle,
                    style: CashundText.pageTitle.copyWith(color: scheme.error),
                  ),
                  const SizedBox(height: CashundSpace.s1),
                  Text(l10n.deleteBody, style: muted.merge(CashundText.bodyLg)),
                  if (counts != null) ...[
                    const SizedBox(height: CashundSpace.s5),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: CashundSpace.s3,
                        children: [
                          for (final line in [
                            l10n.deleteTransactions(counts.transactions),
                            l10n.deleteCategoriesAndLimits(
                              counts.categories,
                              counts.limits,
                            ),
                            l10n.deleteSettings,
                          ])
                            Row(
                              spacing: CashundSpace.s3,
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: CashundText.body.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: CashundSpace.s4),
                  FilledButton.tonalIcon(
                    onPressed: () => bloc.add(const DataEvent.backupPressed()),
                    icon: const Icon(LucideIcons.upload),
                    label: Text(l10n.deleteBackUpFirst),
                  ),
                  const SizedBox(height: CashundSpace.s5),
                  Text(
                    l10n.deleteTypeToConfirm(l10n.deleteWord),
                    style: CashundText.labelSm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: CashundSpace.s2),
                  TextField(
                    controller: _confirmation,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(hintText: l10n.deleteWord),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s6,
                CashundSpace.s3,
                CashundSpace.s6,
                CashundSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: CashundSpace.s3,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _confirmation,
                    builder: (context, value, _) {
                      final confirmed =
                          value.text.trim().toUpperCase() == l10n.deleteWord &&
                          state.delete != DataActionStatus.working;
                      return FilledButton(
                        onPressed: confirmed
                            ? () => bloc.add(const DataEvent.deleteConfirmed())
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        ),
                        child: Text(l10n.deleteEverything),
                      );
                    },
                  ),
                  Text(
                    l10n.deleteAfterwards,
                    textAlign: TextAlign.center,
                    style: CashundText.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
