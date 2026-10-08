import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/widgets/animated_buddy.dart';
import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/buddy_name_step.dart';
import 'package:cashund/presentation/onboarding/widgets/currency_step.dart';
import 'package:cashund/presentation/onboarding/widgets/onboarding_top_bar.dart';
import 'package:cashund/presentation/onboarding/widgets/week_start_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The three setup steps. The band, the sheet, the buddy, the top bar and the
/// button stay put; only the title and the sheet's content slide.
@RoutePage()
class OnboardingStepsScreen extends StatefulWidget {
  const OnboardingStepsScreen({super.key});

  @override
  State<OnboardingStepsScreen> createState() => _OnboardingStepsScreenState();
}

class _OnboardingStepsScreenState extends State<OnboardingStepsScreen> {
  // Two pagers moved together: titles on the band, content in the sheet.
  final _titles = PageController();
  final _bodies = PageController();
  final _buddy = BuddyController();
  var _shownStep = 0;

  static const _slide = Duration(milliseconds: 350);
  static const _buddyWidth = 104.0;

  @override
  void dispose() {
    _titles.dispose();
    _bodies.dispose();
    _buddy.dispose();
    super.dispose();
  }

  void _showStep(BuildContext context, OnboardingState state) {
    FocusScope.of(context).unfocus();
    // The buddy cheers for progress, not for going back.
    if (state.step > _shownStep) _buddy.cheer();
    _shownStep = state.step;
    for (final pages in [_titles, _bodies]) {
      pages.animateToPage(
        state.step,
        duration: _slide,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onBrand = Theme.of(context).extension<CashundColors>()!.onBrand;
    final step = context.select<OnboardingBloc, int>((bloc) => bloc.state.step);
    final titles = [
      l10n.onboardingCurrencyTitle,
      l10n.onboardingBuddyTitle,
      l10n.onboardingWeekTitle,
    ];

    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: _showStep,
      child: PopScope(
        // Back goes to the previous step, and only leaves from the first one.
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.read<OnboardingBloc>().add(
              const OnboardingEvent.backPressed(),
            );
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            body: BrandBandLayout(
              buddyWidth: _buddyWidth,
              buddyController: _buddy,
              band: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CashundSpace.s5,
                  CashundSpace.s2,
                  CashundSpace.s4,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnboardingTopBar(onBrand: true),
                    const SizedBox(height: CashundSpace.s6),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: CashundSpace.s2,
                      ),
                      child: _TitlePager(
                        controller: _titles,
                        titles: titles,
                        style: CashundText.display.copyWith(color: onBrand),
                      ),
                    ),
                    // Room for the buddy peeking over the sheet below.
                    SizedBox(height: const Buddy(width: _buddyWidth).height),
                  ],
                ),
              ),
              sheet: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PageView(
                      controller: _bodies,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        CurrencyStep(),
                        BuddyNameStep(),
                        WeekStartStep(),
                      ],
                    ),
                  ),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The step titles, sliding with the content. As tall as the tallest title,
/// so the band never changes height.
class _TitlePager extends StatelessWidget {
  const _TitlePager({
    required this.controller,
    required this.titles,
    required this.style,
  });

  final PageController controller;
  final List<String> titles;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final height = titles
            .map(
              (title) => (TextPainter(
                text: TextSpan(text: title, style: style),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout(maxWidth: constraints.maxWidth)).height,
            )
            .reduce((a, b) => a > b ? a : b);

        return SizedBox(
          height: height,
          child: PageView(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final title in titles)
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(title, style: style),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The button, plus the currency preview while choosing a currency.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<OnboardingBloc>();
    final (step, currencyCode, saving) = context
        .select<OnboardingBloc, (int, String, bool)>(
          (bloc) => (
            bloc.state.step,
            bloc.state.currencyCode,
            bloc.state.status == OnboardingStatus.saving,
          ),
        );
    final isLastStep = step == OnboardingState.stepCount - 1;
    final currency = currencyByCode(currencyCode) ?? supportedCurrencies.first;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: CashundSpace.s4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CashundSpace.s6,
          CashundSpace.s3,
          CashundSpace.s6,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: step == 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: CashundSpace.s3),
                      child: Text.rich(
                        TextSpan(
                          text: '${l10n.onboardingCurrencyPreview} ',
                          style: CashundText.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: formatMoney(
                                -minorUnitsOf(_previewAmount, currency),
                                currency,
                              ),
                              style: CashundText.amountSm.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            PrimaryButton(
              label: isLastStep
                  ? l10n.onboardingStartTracking
                  : l10n.continueAction,
              onPressed: saving
                  ? null
                  : () => bloc.add(
                      isLastStep
                          ? const OnboardingEvent.finishPressed()
                          : const OnboardingEvent.nextPressed(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The sample expense shown in the currency preview, in major units.
  static const _previewAmount = 62.10;
}
