import 'package:cashund/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

@module
abstract class L10nModule {
  /// The app's strings outside the widget tree, e.g. for home-screen
  /// widgets and app shortcuts. English is the only language so far.
  @lazySingleton
  AppLocalizations get l10n => lookupAppLocalizations(const Locale('en'));
}
