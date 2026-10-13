import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The row under the search: Filters, the filters in use, and quick type picks.
class ActivityChips extends StatelessWidget {
  const ActivityChips({
    required this.filter,
    required this.dateLabel,
    required this.onFiltersPressed,
    required this.onFilterChanged,
    super.key,
  });

  final TransactionFilter filter;

  /// How the active date range reads, e.g. "October".
  final String? dateLabel;
  final VoidCallback onFiltersPressed;
  final ValueChanged<TransactionFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    void toggleType(TransactionType type) => onFilterChanged(
      // Switching type drops categories, which may belong to the other one.
      filter.type == type
          ? filter.copyWith(type: null)
          : filter.copyWith(type: type, categoryIds: {}),
    );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s6),
        children: [
          for (final chip in [
            _Pill(
              icon: LucideIcons.slidersHorizontal,
              label: l10n.activityFilters,
              badge: filter.activeCount,
              onTap: onFiltersPressed,
            ),
            if (dateLabel case final label?)
              _Pill(
                label: label,
                active: true,
                onRemove: () => onFilterChanged(filter.copyWith(range: null)),
              ),
            if (filter.categoryIds.isNotEmpty)
              _Pill(
                label: l10n.activityCategoriesChip(filter.categoryIds.length),
                active: true,
                onRemove: () =>
                    onFilterChanged(filter.copyWith(categoryIds: {})),
              ),
            _Pill(
              label: l10n.activityExpenses,
              active: filter.type == TransactionType.expense,
              onTap: () => toggleType(TransactionType.expense),
            ),
            _Pill(
              label: l10n.activityIncomes,
              active: filter.type == TransactionType.income,
              onTap: () => toggleType(TransactionType.income),
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(right: CashundSpace.s2),
              child: chip,
            ),
        ],
      ),
    );
  }
}

/// An outlined pill; active ones get the soft tint and a primary ring.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    this.icon,
    this.badge = 0,
    this.active = false,
    this.onTap,
    this.onRemove,
  });

  final String label;
  final IconData? icon;
  final int badge;
  final bool active;
  final VoidCallback? onTap;

  /// Shows an × that removes this filter.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurface;

    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? scheme.primaryContainer : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? scheme.primary : scheme.outline,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? onRemove,
          child: Padding(
            padding: EdgeInsets.only(
              left: CashundSpace.s4,
              right: onRemove == null ? CashundSpace.s4 : CashundSpace.s3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CashundSpace.s2,
              children: [
                if (icon case final icon?) Icon(icon, size: 18, color: color),
                Text(
                  label,
                  style: CashundText.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (badge > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: scheme.primary,
                    ),
                    child: Text(
                      '$badge',
                      style: CashundText.amountSm.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                if (onRemove != null)
                  Tooltip(
                    message: context.l10n.activityRemoveFilter,
                    child: Icon(LucideIcons.x, size: 16, color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
