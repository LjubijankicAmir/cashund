import 'package:cashund/data/datasources/local/app_database.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DatabaseModule {
  @LazySingleton(dispose: closeDatabase)
  AppDatabase get database => AppDatabase();
}

Future<void> closeDatabase(AppDatabase database) => database.close();
