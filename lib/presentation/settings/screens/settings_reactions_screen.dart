import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/value_objects/reaction_frequency.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How often the buddy reacts after something is logged. Applies on tap.
@RoutePage()
class SettingsReactionsScreen extends StatelessWidget {
  const SettingsReactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<SettingsBloc>();
    final preferences = context.select<SettingsBloc, UserPreferences?>(
      (bloc) => bloc.state.preferences,
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
              title: l10n.settingsReactions,
              subtitle: preferences == null
                  ? null
                  : l10n.settingsReactionsPageSubtitle(preferences.buddyName),
            ),
            const SizedBox(height: CashundSpace.s6),
            if (preferences != null) ...[
              for (final (frequency, label) in [
                (ReactionFrequency.always, l10n.reactionFrequencyAlways),
                (ReactionFrequency.sometimes, l10n.reactionFrequencySometimes),
                (ReactionFrequency.never, l10n.reactionFrequencyNever),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: CashundSpace.s3),
                  child: OptionCard(
                    title: label,
                    selected: frequency == preferences.reactionFrequency,
                    onTap: () => bloc.add(
                      SettingsEvent.reactionFrequencyChosen(frequency),
                    ),
                  ),
                ),
              if (preferences.reactionFrequency == ReactionFrequency.sometimes)
                _IntervalStepper(
                  interval: preferences.reactionInterval,
                  onChanged: (interval) =>
                      bloc.add(SettingsEvent.reactionIntervalChanged(interval)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Every 3 transactions" with buttons to make it more or less often.
class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({required this.interval, required this.onChanged});

  final int interval;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CashundSpace.s4,
        vertical: CashundSpace.s2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CashundRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.reactionEvery(interval),
              style: CashundText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.reactionIntervalMore,
            onPressed: interval > UserPreferences.minReactionInterval
                ? () => onChanged(interval - 1)
                : null,
            icon: const Icon(LucideIcons.minus),
          ),
          const SizedBox(width: CashundSpace.s2),
          IconButton(
            tooltip: l10n.reactionIntervalFewer,
            onPressed: interval < UserPreferences.maxReactionInterval
                ? () => onChanged(interval + 1)
                : null,
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
    );
  }
}
