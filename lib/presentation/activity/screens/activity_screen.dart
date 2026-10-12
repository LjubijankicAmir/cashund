import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// The full history with search and filters.
// TODO(activity): build the list, search and filters.
@RoutePage()
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CashundSpace.s6,
            CashundSpace.s5,
            CashundSpace.s6,
            0,
          ),
          child: Text(
            context.l10n.activityTitle,
            style: CashundText.pageTitle.copyWith(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
