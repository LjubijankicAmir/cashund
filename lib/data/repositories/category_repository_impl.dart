import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/datasources/local/daos/categories_dao.dart';
import 'package:cashund/data/mappers/category_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao);

  final CategoriesDao _dao;

  @override
  StreamResult<List<Category>> watchActive(TransactionType type) {
    return guardStream(
      _dao
          .watchActive(type)
          .map((rows) => [for (final row in rows) row.toEntity()]),
    );
  }

  @override
  StreamResult<({int expense, int income})> watchActiveCounts() {
    return guardStream(
      _dao.watchActiveCounts().map(
        (counts) => (
          expense: counts[TransactionType.expense] ?? 0,
          income: counts[TransactionType.income] ?? 0,
        ),
      ),
    );
  }

  @override
  StreamResult<List<Category>> watchRecent(
    TransactionType type, {
    required int limit,
  }) {
    return guardStream(
      _dao
          .watchRecent(type, limit)
          .map((rows) => [for (final row in rows) row.toEntity()]),
    );
  }
}
