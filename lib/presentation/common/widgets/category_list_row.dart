import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:flutter/material.dart';

/// A category in a management list: its mark and "emoji Name", then
/// [trailing] actions. Archived categories are muted.
class CategoryListRow extends StatelessWidget {
  const CategoryListRow({
    required this.category,
    this.trailing = const [],
    this.onTap,
    super.key,
  });

  final Category category;
  final List<Widget> trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final archived = category.isArchived;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.only(left: CashundSpace.s4),
          child: Row(
            children: [
              Opacity(
                opacity: archived ? 0.45 : 1,
                child: CategoryMark(color: category.color),
              ),
              const SizedBox(width: CashundSpace.s3),
              Expanded(
                child: Text(
                  category.label(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CashundText.bodyLg.copyWith(
                    fontWeight: FontWeight.w500,
                    color: archived
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              ...trailing,
            ],
          ),
        ),
      ),
    );
  }
}
