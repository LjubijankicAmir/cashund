import 'package:cashund/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

typedef Result<T> = Either<Failure, T>;
typedef FutureResult<T> = Future<Result<T>>;
typedef StreamResult<T> = Stream<Result<T>>;
