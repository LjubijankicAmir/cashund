import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The bottom bar: Home and Activity tabs, with the add button raised above
/// the middle. The add button is the only place to log a transaction.
class CashundNavBar extends StatelessWidget {
  const CashundNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  static const _barHeight = 64.0;
  static const _addButtonSize = 56.0;

  /// How far the add button rises above the bar.
  static const _addButtonRaise = 22.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _Tab(
                      icon: LucideIcons.house,
                      label: l10n.navHome,
                      selected: currentIndex == 0,
                      onTap: () => onTabSelected(0),
                    ),
                  ),
                  const SizedBox(width: _addButtonSize + CashundSpace.s8),
                  Expanded(
                    child: _Tab(
                      icon: LucideIcons.list,
                      label: l10n.navActivity,
                      selected: currentIndex == 1,
                      onTap: () => onTabSelected(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -_addButtonRaise,
          child: _AddButton(
            size: _addButtonSize,
            tooltip: l10n.navAdd,
            onPressed: onAddPressed,
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: CashundSpace.s1,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 30,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: selected
                    ? scheme.primaryContainer
                    : scheme.primaryContainer.withValues(alpha: 0),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            Text(label, style: CashundText.labelSm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  final double size;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const CircleBorder(),
        shadows: CashundShadow.primary(theme.brightness),
      ),
      child: SizedBox.square(
        dimension: size,
        child: FloatingActionButton(
          heroTag: null,
          tooltip: tooltip,
          shape: const CircleBorder(),
          onPressed: onPressed,
          child: const Icon(LucideIcons.plus, size: 26),
        ),
      ),
    );
  }
}
