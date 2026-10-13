import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';

/// The [entries] whose title or category name contains [query], ignoring
/// case. Category names come from [nameOf], since built-in ones are
/// translations rather than stored text.
List<TransactionWithCategory> searchEntries(
  List<TransactionWithCategory> entries,
  String query,
  String Function(Category category) nameOf,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return entries;

  return [
    for (final entry in entries)
      if ((entry.transaction.title ?? '').toLowerCase().contains(needle) ||
          nameOf(entry.category).toLowerCase().contains(needle))
        entry,
  ];
}
