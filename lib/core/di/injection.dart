import 'package:cashund/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

/// Registers every class annotated with `@injectable`, `@lazySingleton`,
/// `@singleton` or provided by a `@module`.
@InjectableInit()
void configureDependencies() => getIt.init();
