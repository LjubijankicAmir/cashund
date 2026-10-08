import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/routing/app_router.gr.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/brand_band_layout.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/typewriter_text.dart';
import 'package:cashund/presentation/common/widgets/wordmark.dart';
import 'package:cashund/presentation/onboarding/bloc/onboarding_bloc.dart';
import 'package:cashund/presentation/onboarding/widgets/step_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The first thing a new user sees. Its parts enter one after another.
@RoutePage()
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // The entrance timeline, in milliseconds.
  static const _sheetSlideMs = 700;
  static const _typingPerCharacterMs = 45;
  static const _itemMs = 350;
  static const _itemGapMs = 120;
  static const _buttonDelayMs = 1000;
  static const _buttonMs = 400;

  static const _buddyWidth = 116.0;

  // Larger than the `display` token (32/38): sizes from the approved render.
  static final TextStyle _bandTitle = CashundText.display.copyWith(
    fontSize: 40,
    height: 44 / 40,
  );
  static final TextStyle _sheetHeading = CashundText.display.copyWith(
    fontSize: 26,
    height: 31 / 26,
  );

  late final AnimationController _entrance = AnimationController(vsync: this);
  late _Timeline _timeline;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final title = context.l10n.onboardingWelcomeTitle(
      context.read<OnboardingBloc>().state.buddyName,
    );
    _timeline = _Timeline(
      _entrance,
      typingMs: title.characters.length * _typingPerCharacterMs,
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final onBrand = Theme.of(context).extension<CashundColors>()!.onBrand;
    final buddyName = context.select<OnboardingBloc, String>(
      (bloc) => bloc.state.buddyName,
    );
    final items = [
      Text(
        l10n.onboardingWelcomeHeading,
        style: _sheetHeading.copyWith(color: scheme.onSurface),
      ),
      _Feature(icon: LucideIcons.plus, text: l10n.onboardingWelcomeLog),
      _Feature(
        icon: LucideIcons.chartColumn,
        text: l10n.onboardingWelcomeOverview,
      ),
      _Feature(icon: LucideIcons.lock, text: l10n.onboardingWelcomePrivacy),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: BrandBandLayout(
          buddy: BuddyExpression.happy,
          buddyWidth: _buddyWidth,
          sheetPosition: _timeline.sheet,
          band: Padding(
            padding: EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s5,
              CashundSpace.s6,
              const Buddy(width: _buddyWidth).height + CashundSpace.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wordmark(),
                const SizedBox(height: 64),
                TypewriterText(
                  l10n.onboardingWelcomeTitle(buddyName),
                  progress: _timeline.typing,
                  style: _bandTitle.copyWith(color: onBrand),
                ),
              ],
            ),
          ),
          sheet: StepBody(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s8,
              CashundSpace.s6,
              0,
            ),
            footer: _Entrance(
              animation: _timeline.button,
              child: PrimaryButton(
                label: l10n.onboardingGetStarted,
                onPressed: () =>
                    context.router.push(const OnboardingStepsRoute()),
              ),
            ),
            children: [
              for (final (index, item) in items.indexed)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == 0 ? CashundSpace.s5 : CashundSpace.s4,
                  ),
                  child: _Entrance(
                    animation: _timeline.item(index),
                    child: item,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splits one controller into the screen's entrance steps:
///
/// 1. The sheet slides up while the title types itself out.
/// 2. Once both are done, the sheet's items come in one by one.
/// 3. A second later, the button.
class _Timeline {
  _Timeline(this._controller, {required int typingMs}) {
    _itemsStartMs = max(typingMs, _WelcomeScreenState._sheetSlideMs);
    final itemsEndMs =
        _itemsStartMs +
        _itemCount * _WelcomeScreenState._itemGapMs +
        _WelcomeScreenState._itemMs;
    _buttonStartMs = itemsEndMs + _WelcomeScreenState._buttonDelayMs;
    _totalMs = _buttonStartMs + _WelcomeScreenState._buttonMs;
    _controller.duration = Duration(milliseconds: _totalMs);

    _typingMs = typingMs;
  }

  static const _itemCount = 4;

  final AnimationController _controller;
  late final int _itemsStartMs;
  late final int _buttonStartMs;
  late final int _totalMs;
  late final int _typingMs;

  Animation<double> _between(
    int startMs,
    int endMs, [
    Curve curve = Curves.linear,
  ]) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(startMs / _totalMs, endMs / _totalMs, curve: curve),
    );
  }

  late final Animation<Offset> sheet =
      Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        _between(0, _WelcomeScreenState._sheetSlideMs, Curves.easeOutCubic),
      );

  late final Animation<double> typing = _between(0, _typingMs);

  Animation<double> item(int index) {
    final start = _itemsStartMs + index * _WelcomeScreenState._itemGapMs;
    return _between(
      start,
      start + _WelcomeScreenState._itemMs,
      Curves.easeOutCubic,
    );
  }

  late final Animation<double> button = _between(
    _buttonStartMs,
    _totalMs,
    Curves.easeOutCubic,
  );
}

/// Fades [child] in while it slides up a little. Can't be tapped until it's
/// fully in.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => IgnorePointer(
        ignoring: animation.value < 1,
        child: Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CashundSpace.s3 + 2,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(CashundRadius.sm),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: CashundText.body.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
