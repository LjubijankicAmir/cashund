import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Where the data lives, at the bottom of Settings.
class PrivacyLine extends StatelessWidget {
  const PrivacyLine({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CashundSpace.s3,
      children: [
        Icon(LucideIcons.lock, size: 16, color: muted),
        Expanded(
          child: Text(
            context.l10n.settingsPrivacy,
            style: CashundText.bodySm.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
