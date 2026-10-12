import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';

abstract interface class CategoryRepository {
  /// The categories of [type] that aren't archived, in their sort order.
  StreamResult<List<Category>> watchActive(TransactionType type);

  /// Up to [limit] categories of [type], most recently used first.
  StreamResult<List<Category>> watchRecent(
    TransactionType type, {
    required int limit,
  });
}
