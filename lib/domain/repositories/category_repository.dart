import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class CategoryRepository {
  /// The categories of [type] that aren't archived, in their sort order.
  StreamResult<List<Category>> watchActive(TransactionType type);

  /// All categories of [type], archived ones included, in their sort order.
  StreamResult<List<Category>> watchByType(TransactionType type);

  /// Adds a category of [type] after the existing ones. [name] is trimmed and
  /// must not be blank.
  FutureResult<Category> create({
    required TransactionType type,
    required String name,
    required String emoji,
    required CategoryColor color,
  });

  /// Changes a category. [customName] `null` gives a built-in category back
  /// its translated name; a custom category always needs one. A built-in
  /// category's emoji can't change.
  FutureResult<Unit> update({
    required int id,
    required String? customName,
    required String emoji,
    required CategoryColor color,
  });

  /// Saves the order of [type]'s categories: [orderedIds] first to last.
  FutureResult<Unit> reorder(TransactionType type, List<int> orderedIds);

  /// Archived categories keep their transactions but can't be picked for new
  /// ones. Restoring puts a category back where it was.
  FutureResult<Unit> setArchived(int id, {required bool archived});

  /// How many categories of each type aren't archived.
  StreamResult<({int expense, int income})> watchActiveCounts();

  /// Up to [limit] categories of [type], most recently used first.
  StreamResult<List<Category>> watchRecent(
    TransactionType type, {
    required int limit,
  });
}
