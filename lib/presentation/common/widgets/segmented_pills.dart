import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:flutter/material.dart';

/// A pill-shaped track with one pill per option; the selected one is raised
/// and slides between them. Used for Day / Week / Month and Expense / Income.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.onBrand = false,
    this.stretch = false,
    super.key,
  });

  /// The options and their labels, in order.
  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Use the translucent version on the brand band.
  final bool onBrand;

  /// Fill the available width with equal options, instead of sizing each
  /// one to its label.
  final bool stretch;

  static const _height = 36.0;
  static const double _horizontalPadding = CashundSpace.s4;
  static const double _trackPadding = CashundSpace.s1;
  static const _slide = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    if (stretch) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth - _trackPadding * 2) / segments.length;
          return _track(context, [for (final _ in segments) width]);
        },
      );
    }

    // Each option is as wide as its label plus padding. Knowing the widths
    // up front lets one pill slide (and resize) between them.
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return _track(context, [
      for (final (_, label) in segments)
        (TextPainter(
              text: TextSpan(text: label, style: CashundText.label),
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
            )..layout()).width +
            _horizontalPadding * 2,
    ]);
  }

  Widget _track(BuildContext context, List<double> widths) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;

    final track = onBrand
        ? colors.onBrand.withValues(alpha: 0.16)
        : scheme.surfaceContainerHighest;
    final selectedPill = onBrand
        ? colors.onBrand
        : scheme.surfaceContainerLowest;
    final selectedText = onBrand ? colors.brand : scheme.onSurface;
    final text = onBrand ? colors.onBrand : scheme.onSurfaceVariant;

    final selectedIndex = segments.indexWhere(
      (segment) => segment.$1 == selected,
    );
    final pillLeft = widths
        .take(selectedIndex)
        .fold<double>(0, (sum, width) => sum + width);

    return DecoratedBox(
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: track),
      child: Padding(
        padding: const EdgeInsets.all(_trackPadding),
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: _slide,
                  curve: Curves.easeOutCubic,
                  left: pillLeft,
                  top: 0,
                  bottom: 0,
                  width: widths[selectedIndex],
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: selectedPill,
                      shadows: onBrand
                          ? null
                          : CashundShadow.card(Theme.of(context).brightness),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, (value, label)) in segments.indexed)
                    Semantics(
                      button: true,
                      selected: value == selected,
                      inMutuallyExclusiveGroup: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(value),
                        child: SizedBox(
                          width: widths[index],
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: _slide,
                              style: CashundText.label.copyWith(
                                color: value == selected ? selectedText : text,
                              ),
                              child: Text(label, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
