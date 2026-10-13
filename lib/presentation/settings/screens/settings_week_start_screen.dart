import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/common/widgets/week_start_options.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Picks the first day of the week. Applies on tap.
@RoutePage()
class SettingsWeekStartScreen extends StatelessWidget {
  const SettingsWeekStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weekStart = context.select<SettingsBloc, WeekStart?>(
      (bloc) => bloc.state.preferences?.weekStart,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s3,
            CashundSpace.s6,
            CashundSpace.s8,
          ),
          children: [
            PushedPageHeader(
              title: l10n.settingsWeekStart,
              subtitle: l10n.settingsWeekStartSubtitle,
            ),
            const SizedBox(height: CashundSpace.s6),
            if (weekStart != null)
              WeekStartOptions(
                selected: weekStart,
                onSelected: (option) => context.read<SettingsBloc>().add(
                  SettingsEvent.weekStartChosen(option),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
