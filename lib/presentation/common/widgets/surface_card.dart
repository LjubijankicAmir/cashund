import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// A white card on the page, with an edge in dark mode where a shadow
/// wouldn't show.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(CashundSpace.s4),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CashundRadius.lg),
        side: dark ? BorderSide(color: scheme.outlineVariant) : BorderSide.none,
      ),
      elevation: dark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
