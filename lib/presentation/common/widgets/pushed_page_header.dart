import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The top of a pushed page: a back button, then the page title on its own
/// line with an optional [subtitle] below.
class PushedPageHeader extends StatelessWidget {
  const PushedPageHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: context.l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        const SizedBox(height: CashundSpace.s4),
        Text(
          title,
          style: CashundText.pageTitle.copyWith(color: scheme.onSurface),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: CashundSpace.s1),
          Text(
            subtitle,
            style: CashundText.bodyLg.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
