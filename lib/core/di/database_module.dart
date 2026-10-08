import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:cashund/data/datasources/local/daos/preferences_dao.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DatabaseModule {
  @LazySingleton(dispose: closeDatabase)
  AppDatabase get database => AppDatabase();

  @lazySingleton
  PreferencesDao preferencesDao(AppDatabase database) =>
      database.preferencesDao;
}

Future<void> closeDatabase(AppDatabase database) => database.close();
