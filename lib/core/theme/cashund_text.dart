import 'package:flutter/material.dart';

/// Cashund type scale.
///
/// Fredoka is the display face (hero amounts, titles, the buddy's name).
/// Figtree is the UI face. Any amount in a list or next to other numbers
/// uses [amount] or [amountSm], which turn on tabular figures.
abstract final class CashundText {
  static const _tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle _fredoka(
    double size,
    double lineHeight, [
    double tracking = 0,
  ]) {
    return TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.w600,
      letterSpacing: tracking * size,
    );
  }

  static TextStyle _figtree(
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) {
    return TextStyle(
      fontFamily: 'Figtree',
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking * size,
    );
  }

  /// Hero amount and the amount input.
  static final TextStyle displayXl = _fredoka(48, 52, -0.01);
  static final TextStyle display = _fredoka(32, 38, -0.01);
  static final TextStyle title = _fredoka(22, 28);
  static final TextStyle buddyName = _fredoka(13, 16, 0.01);

  /// Buddy messages.
  static final TextStyle bodyLg = _figtree(16, 24, FontWeight.w400);
  static final TextStyle body = _figtree(15, 22, FontWeight.w400);
  static final TextStyle bodySm = _figtree(13, 18, FontWeight.w400);

  /// Buttons.
  static final TextStyle label = _figtree(15, 20, FontWeight.w600, 0.01);

  /// Chips and segmented controls.
  static final TextStyle labelSm = _figtree(13, 16, FontWeight.w600, 0.01);

  static final TextStyle amount = _figtree(
    16,
    22,
    FontWeight.w700,
  ).copyWith(fontFeatures: _tabularFigures);
  static final TextStyle amountSm = _figtree(
    13,
    18,
    FontWeight.w600,
  ).copyWith(fontFeatures: _tabularFigures);

  static TextTheme textTheme(Color ink) {
    return TextTheme(
      displayLarge: displayXl,
      displayMedium: display,
      titleLarge: title,
      titleSmall: buddyName,
      bodyLarge: bodyLg,
      bodyMedium: body,
      bodySmall: bodySm,
      labelLarge: label,
      labelMedium: labelSm,
    ).apply(bodyColor: ink, displayColor: ink);
  }
}
