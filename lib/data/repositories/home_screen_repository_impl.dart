import 'dart:async';
import 'dart:io';

import 'package:cashund/core/error/failure.dart';
import 'package:cashund/core/error/result.dart';
import 'package:cashund/domain/repositories/home_screen_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:home_widget/home_widget.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_actions/quick_actions.dart';

@LazySingleton(as: HomeScreenRepository)
class HomeScreenRepositoryImpl implements HomeScreenRepository {
  /// Where the widgets read their snapshot from.
  static const snapshotKey = 'snapshot';

  /// The Android widget providers to redraw, by class name.
  static const _androidWidgets = <String>[];

  static const _quickActions = QuickActions();

  @override
  FutureResult<Unit> showOnWidgets(String snapshotJson) => _guard(() async {
    // No iOS widgets yet: sharing data with them takes an App Group.
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<String>(snapshotKey, snapshotJson);
    for (final name in _androidWidgets) {
      await HomeWidget.updateWidget(qualifiedAndroidName: name);
    }
  });

  @override
  FutureResult<Unit> setShortcuts(List<AppShortcut> shortcuts) => _guard(
    () => _quickActions.setShortcutItems([
      for (final shortcut in shortcuts)
        ShortcutItem(
          // The link itself is the shortcut's id, so a tap hands it back.
          type: '${shortcut.link}',
          localizedTitle: shortcut.title,
          icon: shortcut.icon,
        ),
    ]),
  );

  @override
  Stream<Uri> get launches {
    final links = StreamController<Uri>();
    StreamSubscription<Uri?>? clicks;

    void open(Uri? link) {
      // A tap on a widget without a link of its own comes as an empty one.
      if (link != null && link.hasScheme) links.add(link);
    }

    links
      ..onListen = () async {
        await _quickActions.initialize((type) => open(Uri.tryParse(type)));
        clicks = HomeWidget.widgetClicked.listen(open);
        open(await HomeWidget.initiallyLaunchedFromHomeWidget());
      }
      ..onCancel = () => clicks?.cancel();
    return links.stream;
  }

  /// Runs a platform [action], returning a failure instead of throwing.
  FutureResult<Unit> _guard(Future<void> Function() action) =>
      TaskEither.tryCatch(() async {
        await action();
        return unit;
      }, (error, _) => Failure.unexpected('$error')).run();
}
