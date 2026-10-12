import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A field that opens a picker: a sunken row with a chevron.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.text,
    required this.onTap,
    this.leading,
    this.placeholder = false,
    super.key,
  });

  final String text;
  final Widget? leading;

  /// Shows [text] muted, as a prompt rather than a value.
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(CashundRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s4),
            child: Row(
              spacing: CashundSpace.s3,
              children: [
                ?leading,
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CashundText.bodyLg.copyWith(
                      color: placeholder
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
