import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks a kind of period (e.g. Week / Month / Year), then steps through
/// them: back, the shown period's name and days, next.
class PeriodStepper<T> extends StatelessWidget {
  const PeriodStepper({
    required this.segments,
    required this.selected,
    required this.onSelected,
    required this.title,
    required this.subtitle,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// E.g. "October 2026", and below it "Oct 1 – 22 · so far".
  final String title;
  final String subtitle;

  /// `null` disables the button, e.g. on the first period with data.
  final VoidCallback? onPrevious;

  /// `null` disables the button, e.g. on the current period.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Widget arrow(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(40),
            disabledBackgroundColor: scheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
          ),
          icon: Icon(icon),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CashundSpace.s4,
      children: [
        SegmentedPills(
          stretch: true,
          segments: segments,
          selected: selected,
          onChanged: onSelected,
        ),
        Row(
          children: [
            arrow(LucideIcons.chevronLeft, l10n.insightsPrevious, onPrevious),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: CashundText.title.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: CashundText.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            arrow(LucideIcons.chevronRight, l10n.insightsNext, onNext),
          ],
        ),
      ],
    );
  }
}
