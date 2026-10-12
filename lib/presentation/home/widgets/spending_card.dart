import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/period.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:flutter/material.dart';

/// Where the period's money went: a donut of the top categories and a legend.
class SpendingCard extends StatelessWidget {
  const SpendingCard({
    required this.period,
    required this.slices,
    required this.totalMinor,
    required this.currency,
    super.key,
  });

  final Period period;
  final List<SpendingSlice> slices;
  final int totalMinor;
  final Currency currency;

  static const _donutSize = 120.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      for (final slice in slices)
        switch (slice.category) {
          final category? => context.categoryColor(category.color).mark,
          null => scheme.outline,
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s4,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeSpendingTitle,
                style: CashundText.title.copyWith(color: scheme.onSurface),
              ),
            ),
            Text(
              l10n.homeSpendingPeriod(period.name),
              style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        Row(
          spacing: CashundSpace.s6,
          children: [
            SizedBox.square(
              dimension: _donutSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The legend says the same in words.
                  ExcludeSemantics(
                    child: TweenAnimationBuilder<double>(
                      // Restarts the sweep whenever the numbers change.
                      key: ValueKey(slices),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) => CustomPaint(
                        size: const Size.square(_donutSize),
                        painter: _DonutPainter(
                          fractions: [
                            for (final slice in slices)
                              slice.amountMinor / totalMinor,
                          ],
                          colors: colors,
                          progress: progress,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMoney(totalMinor, currency),
                        style: CashundText.amountSm.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.homeSpendingSpent,
                        style: CashundText.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                spacing: CashundSpace.s2,
                children: [
                  for (final (index, slice) in slices.indexed)
                    _LegendRow(slice: slice, color: colors[index]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.color});

  final SpendingSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final category = slice.category;

    return Row(
      spacing: CashundSpace.s2,
      children: [
        if (category != null)
          CategoryMark(color: category.color, height: 16)
        else
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Expanded(
          child: Text(
            category?.label(l10n) ?? l10n.homeSpendingOther,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CashundText.body.copyWith(
              color: category == null
                  ? scheme.onSurfaceVariant
                  : context.categoryColor(category.color).label,
            ),
          ),
        ),
        Text(
          '${slice.percent}%',
          style: CashundText.amountSm.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}

/// A ring split into colored arcs, with small gaps between them.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fractions,
    required this.colors,
    required this.progress,
  });

  final List<double> fractions;
  final List<Color> colors;

  /// How much of the ring is drawn, from 0 to 1, for the sweep-in.
  final double progress;

  static const _stroke = 16.0;
  static const _gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    // The gap as an angle: arc length / radius.
    final gapAngle = fractions.length > 1 ? _gap / radius : 0.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    var start = -pi / 2;
    for (final (index, fraction) in fractions.indexed) {
      final sweep = fraction * 2 * pi * progress;
      final visible = sweep - gapAngle;
      if (visible > 0) {
        canvas.drawArc(
          rect,
          start + gapAngle / 2,
          visible,
          false,
          paint..color = colors[index],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.fractions != fractions ||
      old.colors != colors;
}
