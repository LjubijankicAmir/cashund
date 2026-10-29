import 'package:cashund/core/error/result.dart';
import 'package:fpdart/fpdart.dart';

/// A shortcut on the app icon's long-press menu, opening `link`.
typedef AppShortcut = ({Uri link, String title, String icon});

/// The app's presence on the phone's home screen: its widgets and the
/// shortcuts on its icon.
abstract interface class HomeScreenRepository {
  /// Hands the widgets what they show, as JSON, and has them redraw now and
  /// again at each of [redrawAt], even while the app isn't running.
  FutureResult<Unit> showOnWidgets(
    String snapshotJson, {
    List<DateTime> redrawAt = const [],
  });

  /// Puts [shortcuts] on the app icon, in this order.
  FutureResult<Unit> setShortcuts(List<AppShortcut> shortcuts);

  /// Each link the app is opened with from a widget or a shortcut, starting
  /// with the one that launched it, if any.
  Stream<Uri> get launches;
}
