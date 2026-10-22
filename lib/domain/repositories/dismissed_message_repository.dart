import 'package:cashund/core/error/result.dart';
import 'package:fpdart/fpdart.dart';

/// Buddy messages the user closed.
abstract interface class DismissedMessageRepository {
  /// The day each closed message was closed, by its key.
  StreamResult<Map<String, DateTime>> watchAll();

  /// Remembers that the message with [key] was closed on [day].
  FutureResult<Unit> dismiss(String key, DateTime day);
}
