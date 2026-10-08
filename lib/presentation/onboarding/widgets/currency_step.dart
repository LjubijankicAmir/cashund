import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Step 1: the currency every amount is tracked in.
class CurrencyStep extends StatefulWidget {
  const CurrencyStep({super.key});

  @override
  State<CurrencyStep> createState() => _CurrencyStepState();
}

class _CurrencyStepState extends State<CurrencyStep> {
  String _query = '';

  List<Currency> _matching(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return supportedCurrencies;
    return [
      for (final currency in supportedCurrencies)
        if ('${l10n.currencyName(currency.code)} ${currency.code} ${currency.symbol}'
            .toLowerCase()
            .contains(query))
          currency,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<OnboardingBloc>();
    final selected = context.select<OnboardingBloc, String>(
      (bloc) => bloc.state.currencyCode,
    );
    final matching = _matching(l10n);

    // Only the list scrolls; the explanation and the search stay in place.
    return Padding(
      padding: stepBodyPadding.copyWith(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingCurrencySubtitle,
            style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: CashundSpace.s5),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.onboardingCurrencySearchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
            ),
          ),
          const SizedBox(height: CashundSpace.s3),
          Expanded(
            child: matching.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: CashundSpace.s6,
                    ),
                    child: Text(
                      l10n.onboardingCurrencyNoResults(_query.trim()),
                      textAlign: TextAlign.center,
                      style: CashundText.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(bottom: stepBodyPadding.bottom),
                    itemCount: matching.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: CashundSpace.s3),
                    itemBuilder: (context, index) {
                      final currency = matching[index];
                      return OptionCard(
                        title: l10n.currencyName(currency.code),
                        subtitle: currency.code,
                        trailing: Text(
                          currency.symbol,
                          style: CashundText.title.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        selected: currency.code == selected,
                        onTap: () => bloc.add(
                          OnboardingEvent.currencySelected(currency.code),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
