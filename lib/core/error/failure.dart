import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// An expected error returned through `Result` instead of thrown.
@freezed
sealed class Failure with _$Failure {
  /// Reading from or writing to the local database failed.
  const factory Failure.database([String? message]) = DatabaseFailure;

  /// The requested record does not exist.
  const factory Failure.notFound([String? message]) = NotFoundFailure;

  /// Input broke a domain rule, e.g. a negative amount.
  const factory Failure.validation([String? message]) = ValidationFailure;

  /// Anything not covered above.
  const factory Failure.unexpected([String? message]) = UnexpectedFailure;
}
