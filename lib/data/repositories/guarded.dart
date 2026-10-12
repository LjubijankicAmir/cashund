import 'dart:async';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:fpdart/fpdart.dart';

/// Runs a database [action], returning a database failure instead of throwing.
FutureResult<T> guardFuture<T>(Future<T> Function() action) {
  return TaskEither.tryCatch(
    action,
    (error, _) => Failure.database('$error'),
  ).run();
}

/// Wraps each value of a database [stream] in a result, and turns errors
/// into database failures instead of stream errors.
StreamResult<T> guardStream<T>(Stream<T> stream) {
  return stream.transform(
    StreamTransformer.fromHandlers(
      handleData: (value, sink) => sink.add(right(value)),
      handleError: (error, _, sink) =>
          sink.add(left(Failure.database('$error'))),
    ),
  );
}
