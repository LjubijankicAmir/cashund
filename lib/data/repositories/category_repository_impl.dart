import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/categories_dao.dart';
import 'package:cashund/data/mappers/category_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/category_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
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
  StreamResult<List<Category>> watchByType(TransactionType type) {
    return guardStream(
      _dao
          .watchByType(type)
          .map((rows) => [for (final row in rows) row.toEntity()]),
    );
  }

  @override
  FutureResult<Category> create({
    required TransactionType type,
    required String name,
    required String emoji,
    required CategoryColor color,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        left(const Failure.validation('A category needs a name.')),
      );
    }

    return guardFuture(() async {
      final row = await _dao.insertLast(
        CategoriesTableCompanion.insert(
          type: type,
          customName: Value(trimmed),
          emoji: emoji,
          color: color,
          // Replaced by the DAO with the next free position.
          sortOrder: 0,
        ),
      );
      return row.toEntity();
    });
  }

  @override
  FutureResult<Unit> update({
    required int id,
    required String? customName,
    required String emoji,
    required CategoryColor color,
  }) async {
    final name = customName?.trim();
    if (name != null && name.isEmpty) {
      return left(const Failure.validation('A category needs a name.'));
    }

    final CategoryRow? row;
    switch (await guardFuture(() => _dao.findById(id))) {
      case Left(:final value):
        return left(value);
      case Right(:final value):
        row = value;
    }
    if (row == null) return left(const Failure.notFound());
    final builtIn = row.predefinedKey != null;
    if (!builtIn && name == null) {
      return left(const Failure.validation('A category needs a name.'));
    }
    if (builtIn && row.emoji != emoji) {
      return left(
        const Failure.validation("A built-in category's emoji is fixed."),
      );
    }

    return await guardFuture(() async {
      await _dao.updateById(
        id,
        CategoriesTableCompanion(
          customName: Value(name),
          emoji: Value(emoji),
          color: Value(color),
        ),
      );
      return unit;
    });
  }

  @override
  FutureResult<Unit> reorder(TransactionType type, List<int> orderedIds) {
    return guardFuture(() async {
      await _dao.reorder(type, orderedIds);
      return unit;
    });
  }

  @override
  FutureResult<Unit> setArchived(int id, {required bool archived}) {
    return guardFuture(() async {
      await _dao.updateById(
        id,
        CategoriesTableCompanion(isArchived: Value(archived)),
      );
      return unit;
    });
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
