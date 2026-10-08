import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// A step's content that scrolls, with [footer] pinned below it.
class StepBody extends StatelessWidget {
  const StepBody({
    required this.children,
    required this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      CashundSpace.s6,
      CashundSpace.s6,
      CashundSpace.s6,
      0,
    ),
    super.key,
  });

  final List<Widget> children;
  final Widget footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(padding: padding, children: children),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: CashundSpace.s4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              CashundSpace.s3,
              CashundSpace.s6,
              0,
            ),
            child: footer,
          ),
        ),
      ],
    );
  }
}

/// Padding around every onboarding step's content inside the sheet.
const stepBodyPadding = EdgeInsets.fromLTRB(
  CashundSpace.s6,
  CashundSpace.s8,
  CashundSpace.s6,
  CashundSpace.s4,
);
