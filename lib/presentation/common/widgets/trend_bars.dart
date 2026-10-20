import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One bar: a period's total and its label on the axis.
class TrendBar {
  const TrendBar({
    required this.label,
    required this.valueMinor,
    this.isCurrent = false,
    this.isFuture = false,
  });

  final String label;
  final int valueMinor;
  final bool isCurrent;

  /// A period that hasn't started: an empty stub, no value.
  final bool isFuture;
}

/// Spending over periods as bars, the current one highlighted, with an
/// optional dashed limit line that past bars turn warning above. Always has
/// a legend, so nothing relies on color alone.
class TrendBars extends StatelessWidget {
  const TrendBars({
    required this.bars,
    required this.currency,
    required this.currentLabel,
    this.currentColor,
    this.limitMinor,
    this.pastLabel,
    this.selectedIndex,
    this.onSelected,
    super.key,
  });

  final List<TrendBar> bars;
  final Currency currency;

  /// The current period's color; `primary` by default.
  final Color? currentColor;

  /// Draws the limit line when set.
  final int? limitMinor;

  /// Legend labels, e.g. "This week" and "Under".
  final String currentLabel;
  final String? pastLabel;

  /// The tapped bar: it stays bright and the others dim.
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;

  static const _plotHeight = 150.0;
  static const _labelSpace = 22.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;
    final current = currentColor ?? scheme.primary;
    final past = scheme.outline;
    final limit = limitMinor;
    final top = [for (final bar in bars) bar.valueMinor, ?limit].fold(1, max);
    final gap = bars.length > 8 ? 6.0 : 10.0;
    final hasOver =
        limit != null &&
        bars.any((bar) => !bar.isCurrent && bar.valueMinor > limit);

    Color colorOf(TrendBar bar) {
      if (bar.isCurrent) return current;
      if (limit != null && bar.valueMinor > limit) return colors.warningFill;
      return past;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s3,
      children: [
        SizedBox(
          height: _plotHeight + _labelSpace,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (index, bar) in bars.indexed) ...[
                      if (index > 0) SizedBox(width: gap),
                      Expanded(
                        child: _Bar(
                          bar: bar,
                          height: _plotHeight * bar.valueMinor / top,
                          color: colorOf(bar),
                          over:
                              limit != null &&
                              !bar.isCurrent &&
                              bar.valueMinor > limit,
                          dimmed:
                              selectedIndex != null && selectedIndex != index,
                          currency: currency,
                          onTap: onSelected == null
                              ? null
                              : () => onSelected!(index),
                        ),
                      ),
                    ],
                  ],
                ),
                if (limit != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _labelSpace + _plotHeight * (1 - limit / top),
                    child: ExcludeSemantics(
                      child: CustomPaint(
                        size: const Size.fromHeight(1.5),
                        painter: _DashedLine(scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Divider(height: 1, color: scheme.outlineVariant),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            for (final (index, bar) in bars.indexed) ...[
              if (index > 0) SizedBox(width: gap),
              Expanded(
                child: Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: CashundText.labelSm.copyWith(
                    fontWeight: bar.isCurrent
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: bar.isCurrent
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        Wrap(
          spacing: CashundSpace.s4,
          runSpacing: CashundSpace.s1,
          children: [
            _LegendItem(color: current, label: currentLabel),
            if (pastLabel case final label?)
              _LegendItem(color: past, label: label),
            if (hasOver)
              _LegendItem(
                color: colors.warningFill,
                label: l10n.trendLegendOver,
              ),
            if (limit != null)
              _LegendItem(
                label: l10n.trendLegendLimit(formatMoneyShort(limit, currency)),
                dashed: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.bar,
    required this.height,
    required this.color,
    required this.over,
    required this.dimmed,
    required this.currency,
    this.onTap,
  });

  final TrendBar bar;
  final double height;
  final Color color;
  final bool over;
  final bool dimmed;
  final Currency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CashundColors>()!;

    if (bar.isFuture) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 8,
          constraints: const BoxConstraints(maxWidth: 30),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      );
    }

    final labelStyle = CashundText.labelSm.copyWith(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: bar.isCurrent ? FontWeight.w700 : FontWeight.w600,
      color: over
          ? colors.warning
          : bar.isCurrent
          ? scheme.onSurface
          : scheme.onSurfaceVariant,
    );

    return Semantics(
      button: onTap != null,
      label: '${bar.label}, ${formatMoney(bar.valueMinor, currency)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.6 : 1,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (over)
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 11,
                      color: colors.warning,
                    ),
                  Flexible(
                    child: Text(
                      formatMoneyShort(bar.valueMinor, currency),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: labelStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CashundSpace.s1),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: height),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => Container(
                  height: max(animated, 2),
                  constraints: const BoxConstraints(maxWidth: 30),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, this.color, this.dashed = false});

  final String label;
  final Color? color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (dashed)
          SizedBox(
            width: 16,
            child: CustomPaint(
              size: const Size.fromHeight(1.5),
              painter: _DashedLine(scheme.onSurfaceVariant),
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Text(
          label,
          style: CashundText.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 4.0;
    const space = 3.0;
    for (var x = 0.0; x < size.width; x += dash + space) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(min(x + dash, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => oldDelegate.color != color;
}
