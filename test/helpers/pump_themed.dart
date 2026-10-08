import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpThemed on WidgetTester {
  /// Pumps [widget] inside the app's theme and localizations.
  Future<void> pumpThemed(
    Widget widget, {
    Brightness brightness = Brightness.light,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? CashundTheme.light
            : CashundTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: widget),
      ),
    );
  }
}
