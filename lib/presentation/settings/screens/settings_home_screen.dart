import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/domain/value_objects/theme_preference.dart';
import 'package:cashund/presentation/common/widgets/buddy_avatar.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:cashund/presentation/common/widgets/settings_group.dart';
import 'package:cashund/presentation/common/widgets/week_start_options.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:cashund/presentation/settings/screens/settings_screen.dart';
import 'package:cashund/presentation/settings/widgets/about_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Settings list.
@RoutePage()
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final state = context.watch<SettingsBloc>().state;
    final bloc = context.read<SettingsBloc>();
    final preferences = state.preferences;

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
            PushedPageHeader(title: l10n.settings),
            if (preferences != null) ...[
              const SizedBox(height: CashundSpace.s6),
              SettingsGroup(
                label: l10n.settingsPreferences,
                rows: [
                  SettingsRow(
                    leading: const Icon(LucideIcons.circleDollarSign),
                    title: l10n.settingsCurrency,
                    value: l10n.settingsCurrencyValue(
                      preferences.currencyCode,
                      currencySymbol(preferences.currencyCode),
                    ),
                    onTap: () =>
                        context.router.push(const SettingsCurrencyRoute()),
                  ),
                  SettingsRow(
                    leading: const Icon(LucideIcons.calendar),
                    title: l10n.settingsWeekStart,
                    value: WeekStartOptions.dayName(
                      preferences.weekStart,
                      locale,
                    ),
                    onTap: () =>
                        context.router.push(const SettingsWeekStartRoute()),
                  ),
                  SettingsRow(
                    leading: const Icon(LucideIcons.contrast),
                    title: l10n.settingsTheme,
                    below: SegmentedPills(
                      stretch: true,
                      segments: [
                        (ThemePreference.system, l10n.themeSystem),
                        (ThemePreference.light, l10n.themeLight),
                        (ThemePreference.dark, l10n.themeDark),
                      ],
                      selected: preferences.themePreference,
                      onChanged: (theme) =>
                          bloc.add(SettingsEvent.themeChosen(theme)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CashundSpace.s6),
              SettingsGroup(
                label: l10n.settingsBuddy,
                rows: [
                  SettingsRow(
                    leading: const BuddyAvatar(size: 32),
                    title: l10n.settingsBuddyName,
                    subtitle: l10n.settingsBuddySubtitle,
                    value: preferences.buddyName,
                    onTap: () =>
                        context.router.push(const SettingsBuddyNameRoute()),
                  ),
                  SettingsRow(
                    leading: const Icon(LucideIcons.messageCircle),
                    title: l10n.settingsReactions,
                    subtitle: l10n.settingsReactionsSubtitle,
                    value: switch (preferences.reactionFrequency) {
                      ReactionFrequency.always => l10n.settingsReactionsAlways,
                      ReactionFrequency.sometimes => l10n.reactionEvery(
                        preferences.reactionInterval,
                      ),
                      ReactionFrequency.never => l10n.settingsReactionsOff,
                    },
                    onTap: () =>
                        context.router.push(const SettingsReactionsRoute()),
                  ),
                ],
              ),
              const SizedBox(height: CashundSpace.s6),
              SettingsGroup(
                label: l10n.settingsCategories,
                rows: [
                  SettingsRow(
                    leading: const Icon(LucideIcons.tag),
                    title: l10n.settingsCategories,
                    subtitle: switch (state.categoryCounts) {
                      (:final expense, :final income) =>
                        l10n.settingsCategoryCounts(expense, income),
                      null => null,
                    },
                    onTap: () => context.router.push(const CategoriesRoute()),
                  ),
                  SettingsRow(
                    leading: const Icon(LucideIcons.gauge),
                    title: l10n.settingsLimits,
                    subtitle: switch (state.limitCounts) {
                      (week: 0, month: 0) => l10n.settingsNoLimits,
                      (:final week, :final month) => l10n.settingsLimitCounts(
                        week,
                        month,
                      ),
                      null => null,
                    },
                    // Over Settings, like from Home.
                    onTap: () => context.router.root.push(LimitsRoute()),
                  ),
                ],
              ),
              const SizedBox(height: CashundSpace.s6),
              const AboutGroup(),
              const SizedBox(height: CashundSpace.s8),
              Text(
                l10n.settingsFooter,
                textAlign: TextAlign.center,
                style: CashundText.body.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
