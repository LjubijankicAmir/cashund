import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A labelled card of [SettingsRow]s with hairlines between them.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.rows, this.label, super.key});

  /// Above the card; a group on its own can go without.
  final String? label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label case final label?)
          Padding(
            padding: const EdgeInsets.only(
              left: CashundSpace.s1,
              bottom: CashundSpace.s3,
            ),
            child: Text(
              label,
              style: CashundText.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CashundRadius.lg),
            // On the dark page the card needs an edge to stand out.
            side: dark
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: CashundSpace.s4,
                    endIndent: CashundSpace.s4,
                    color: scheme.outlineVariant,
                  ),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One setting: a [leading] icon or avatar, a title with an optional
/// sub-line, the current [value], and a chevron when it opens something.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.below,
    this.titleStyle,
    super.key,
  });

  /// Settings icons are 20pt line icons, e.g. `Icon(LucideIcons.calendar)`.
  final Widget leading;
  final String title;

  /// Overrides the title's look, e.g. a quieter one.
  final TextStyle? titleStyle;
  final String? subtitle;
  final String? value;

  /// `null` makes the row read-only, without a chevron.
  final VoidCallback? onTap;

  /// A full-width control stacked under the title, e.g. a segmented control.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    final row = Row(
      children: [
        IconTheme.merge(
          data: IconThemeData(size: 20, color: muted),
          child: leading,
        ),
        const SizedBox(width: CashundSpace.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    titleStyle ??
                    CashundText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: CashundText.bodySm.copyWith(color: muted),
                ),
            ],
          ),
        ),
        if (value case final value?) ...[
          const SizedBox(width: CashundSpace.s3),
          Text(value, style: CashundText.body.copyWith(color: muted)),
        ],
        if (onTap != null) ...[
          const SizedBox(width: CashundSpace.s2),
          Icon(LucideIcons.chevronRight, size: 20, color: muted),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CashundSpace.s4,
            vertical: CashundSpace.s3,
          ),
          child: below == null
              ? row
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CashundSpace.s3,
                  children: [row, below!],
                ),
        ),
      ),
    );
  }
}
