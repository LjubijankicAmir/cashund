import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/widgets/confirm_sheet.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings and its detail pages, all sharing one [SettingsBloc]. Its child
/// routes render in [AutoRouter].
@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsBloc>()..add(const SettingsEvent.started()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<SettingsBloc, SettingsState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == SettingsStatus.failure,
            listener: (context, state) => ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(content: Text(context.l10n.settingsSaveFailed)),
                ),
          ),
          BlocListener<SettingsBloc, SettingsState>(
            listenWhen: (previous, current) =>
                previous.pendingCurrencyCode != current.pendingCurrencyCode &&
                current.pendingCurrencyCode != null,
            listener: (context, state) =>
                unawaited(_confirmCurrencySwitch(context, state)),
          ),
        ],
        child: const AutoRouter(),
      ),
    );
  }

  Future<void> _confirmCurrencySwitch(
    BuildContext context,
    SettingsState state,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<SettingsBloc>();
    final next = state.pendingCurrencyCode!;
    final current = state.preferences!.currencyCode;

    final pastNote = l10n.currencySwitchPastNote(
      state.transactionsInCurrency,
      current,
    );
    final confirmed = await showConfirmSheet(
      context,
      icon: LucideIcons.arrowRightLeft,
      title: l10n.currencySwitchTitle(l10n.currencyName(next), next),
      body: l10n.currencySwitchBody(next),
      notes: [
        (icon: LucideIcons.check, text: _bolded(pastNote, current)),
        (
          icon: LucideIcons.info,
          text: TextSpan(text: l10n.currencySwitchTotalsNote),
        ),
      ],
      confirmLabel: l10n.currencySwitchConfirm(next),
      cancelLabel: l10n.currencySwitchCancel(current),
    );

    bloc.add(
      confirmed
          ? const SettingsEvent.currencySwitchConfirmed()
          : const SettingsEvent.currencySwitchCancelled(),
    );
  }

  /// [text] with the first [word] in bold.
  static InlineSpan _bolded(String text, String word) {
    final index = text.indexOf(word);
    if (index < 0) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: word,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: text.substring(index + word.length)),
      ],
    );
  }
}

/// The currency's symbol, or its code for one no longer offered.
String currencySymbol(String code) => currencyByCode(code)?.symbol ?? code;
