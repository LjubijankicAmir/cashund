import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/currency_options.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Picks the app currency. Switching asks first once transactions exist.
@RoutePage()
class SettingsCurrencyScreen extends StatelessWidget {
  const SettingsCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = context.select<SettingsBloc, String?>(
      (bloc) => bloc.state.preferences?.currencyCode,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Only the list scrolls; the header and the search stay in place.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s3,
            CashundSpace.s6,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PushedPageHeader(
                title: l10n.settingsCurrency,
                subtitle: l10n.settingsCurrencySubtitle,
              ),
              const SizedBox(height: CashundSpace.s5),
              if (selected != null)
                Expanded(
                  child: CurrencyOptions(
                    selectedCode: selected,
                    listPadding: EdgeInsets.only(
                      bottom:
                          MediaQuery.paddingOf(context).bottom +
                          CashundSpace.s6,
                    ),
                    onSelected: (currency) => context.read<SettingsBloc>().add(
                      SettingsEvent.currencyChosen(currency.code),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
