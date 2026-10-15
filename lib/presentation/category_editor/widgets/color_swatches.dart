import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The 12 category colors in picker order, six per row.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CategoryColor selected;
  final ValueChanged<CategoryColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final color in CategoryColor.values)
          Center(
            child: Semantics(
              button: true,
              selected: color == selected,
              inMutuallyExclusiveGroup: true,
              label: context.l10n.categoryColorName(color.name),
              child: GestureDetector(
                onTap: () => onSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  // The selected one gets a gap, then a primary ring.
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == selected
                          ? scheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.categoryColor(color).mark,
                    ),
                    child: color == selected
                        ? Icon(
                            LucideIcons.check,
                            size: 18,
                            color: scheme.surface,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
