import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A file's name and a line about it, e.g. what a backup holds.
class FileCard extends StatelessWidget {
  const FileCard({required this.name, this.meta, super.key});

  final String name;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CashundSpace.s4,
        vertical: CashundSpace.s3,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CashundRadius.md),
      ),
      child: Row(
        spacing: CashundSpace.s3,
        children: [
          Icon(LucideIcons.file, color: scheme.onSurface),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Breaks anywhere: file names are long and have no spaces.
                  name.split('').join('​'),
                  style: CashundText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (meta case final meta?)
                  Text(
                    meta,
                    style: CashundText.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
