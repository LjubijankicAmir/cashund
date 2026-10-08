import 'dart:async';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:cashund/data/mappers/preferences_mapper.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PreferencesRepository)
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._dao);

  final PreferencesDao _dao;

  @override
  FutureResult<UserPreferences?> get() {
    return _guard(() async => (await _dao.getRow())?.toEntity());
  }

  @override
  StreamResult<UserPreferences?> watch() {
    return _dao.watchRow().transform(
      StreamTransformer.fromHandlers(
        handleData: (row, sink) => sink.add(right(row?.toEntity())),
        handleError: (error, _, sink) =>
            sink.add(left(Failure.database('$error'))),
      ),
    );
  }

  @override
  FutureResult<Unit> save(UserPreferences preferences) {
    return _guard(() async {
      await _dao.upsert(preferences.toCompanion());
      return unit;
    });
  }

  /// Runs [action] and returns a database failure instead of throwing.
  FutureResult<T> _guard<T>(Future<T> Function() action) {
    return TaskEither.tryCatch(
      action,
      (error, _) => Failure.database('$error'),
    ).run();
  }
}
