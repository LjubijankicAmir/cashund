import 'package:injectable/injectable.dart';

/// The current time. Ask this instead of calling `DateTime.now()` directly,
/// so tests can fix the date.
@lazySingleton
class Clock {
  DateTime now() => DateTime.now();
}
