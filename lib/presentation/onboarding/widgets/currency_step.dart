import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/currency_options.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 1: the currency every amount is tracked in.
class CurrencyStep extends StatelessWidget {
  const CurrencyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = context.select<OnboardingBloc, String>(
      (bloc) => bloc.state.currencyCode,
    );

    // Only the list scrolls; the explanation and the search stay in place.
    return Padding(
      padding: stepBodyPadding.copyWith(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.onboardingCurrencySubtitle,
            style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: CashundSpace.s5),
          Expanded(
            child: CurrencyOptions(
              selectedCode: selected,
              // Room to scroll the last currencies up from under the keyboard.
              listPadding: EdgeInsets.only(
                bottom:
                    stepBodyPadding.bottom +
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
              onSelected: (currency) => context.read<OnboardingBloc>().add(
                OnboardingEvent.currencySelected(currency.code),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
