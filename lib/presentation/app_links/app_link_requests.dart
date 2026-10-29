import 'dart:async';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/repositories/home_screen_repository.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/app_links/app_link.dart';
import 'package:injectable/injectable.dart';

/// The links the app is opened with from its home-screen widgets and the
/// shortcuts on its icon. The shell opens them; one that comes in before the
/// shell is up, like the link that launched the app, waits for it.
@lazySingleton
class AppLinkRequests {
  AppLinkRequests(this._homeScreen, this._l10n);

  final HomeScreenRepository _homeScreen;
  final AppLocalizations _l10n;

  final _requests = StreamController<AppLink>.broadcast();
  StreamSubscription<Uri>? _launches;
  AppLink? _pending;

  /// Each new link, as it comes.
  Stream<AppLink> get requests => _requests.stream;

  /// Starts listening for links and puts the shortcuts on the app icon.
  Future<void> start() async {
    _launches ??= _homeScreen.launches.listen((uri) {
      final link = AppLink.parse(uri);
      if (link == null) return;
      _pending = link;
      _requests.add(link);
    });
    await _homeScreen.setShortcuts([
      (
        link: const AppLink.add(TransactionType.expense).toUri(),
        title: _l10n.addExpense,
        icon: 'shortcut_add',
      ),
      (
        link: const AppLink.add(TransactionType.income).toUri(),
        title: _l10n.addIncome,
        icon: 'shortcut_add',
      ),
      (
        link: const AppLink.activity().toUri(),
        title: _l10n.navActivity,
        icon: 'shortcut_activity',
      ),
    ]);
  }

  /// The latest link not opened yet, if any; marks it opened.
  AppLink? take() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  @disposeMethod
  Future<void> dispose() async {
    await _launches?.cancel();
    await _requests.close();
  }
}
