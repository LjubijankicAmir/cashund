import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:cashund/data/mappers/preferences_mapper.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/entities/user_preferences.dart';
import 'package:cashund/domain/repositories/preferences_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PreferencesRepository)
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._dao);

  final PreferencesDao _dao;

  @override
  FutureResult<UserPreferences?> get() =>
      guardFuture(() async => (await _dao.getRow())?.toEntity());

  @override
  StreamResult<UserPreferences?> watch() =>
      guardStream(_dao.watchRow().map((row) => row?.toEntity()));

  @override
  FutureResult<Unit> save(UserPreferences preferences) {
    return guardFuture(() async {
      await _dao.upsert(preferences.toCompanion());
      return unit;
    });
  }
}
