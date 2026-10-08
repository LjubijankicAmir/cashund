import 'package:flutter/material.dart';

/// Cashund type scale.
///
/// Fredoka is used only for the hero balance ([displayXl]) and onboarding
/// titles ([display]). Figtree is everything else. Any amount uses tabular
/// figures so digits line up and totals don't jitter.
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

  /// The hero balance on the brand band. Nothing else.
  static final TextStyle displayXl = _fredoka(
    48,
    52,
    -0.01,
  ).copyWith(fontFeatures: _tabularFigures);

  /// Onboarding titles. Nothing else.
  static final TextStyle display = _fredoka(32, 38, -0.01);

  /// Page titles, e.g. "Activity".
  static final TextStyle pageTitle = _figtree(26, 32, FontWeight.w700);

  /// Card and section titles, e.g. "Limits", "Spending".
  static final TextStyle title = _figtree(18, 24, FontWeight.w700);

  /// The amount being typed in the add transaction form.
  static final TextStyle amountInput = _figtree(
    52,
    58,
    FontWeight.w700,
  ).copyWith(fontFeatures: _tabularFigures);

  /// The "🍔 Eating Out" line in rows, drawn in the category's label color.
  static final TextStyle categoryLabel = _figtree(12, 16, FontWeight.w600);

  /// Transaction titles.
  static final TextStyle rowTitle = _figtree(16, 22, FontWeight.w600);

  static final TextStyle buddyName = _figtree(13, 16, FontWeight.w700);

  /// Buddy messages.
  static final TextStyle bodyLg = _figtree(16, 24, FontWeight.w400);
  static final TextStyle body = _figtree(15, 22, FontWeight.w400);
  static final TextStyle bodySm = _figtree(13, 18, FontWeight.w400);

  /// Buttons.
  static final TextStyle label = _figtree(15, 20, FontWeight.w600, 0.01);

  /// Chips, segments, field labels and tab labels.
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
      headlineSmall: pageTitle,
      titleMedium: title,
      titleSmall: buddyName,
      bodyLarge: bodyLg,
      bodyMedium: body,
      bodySmall: bodySm,
      labelLarge: label,
      labelMedium: labelSm,
      labelSmall: categoryLabel,
    ).apply(bodyColor: ink, displayColor: ink);
  }
}
