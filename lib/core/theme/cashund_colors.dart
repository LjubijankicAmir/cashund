import 'package:flutter/material.dart';

// Token → Material role mapping:
//   background     → surface (scaffold)
//   surface        → surfaceContainerLowest (cards, the sheet)
//   surface-raised → surfaceContainerHigh (bottom sheets, dialogs)
//   surface-sunken → surfaceContainerHighest (inputs, tracks)
//   primary-soft   → primaryContainer
//   ink / ink-muted → onSurface / onSurfaceVariant
//   line / line-strong → outlineVariant / outline

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2F4BFF),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEEF1FF),
  onPrimaryContainer: Color(0xFF1F33C4),
  secondary: Color(0xFF2F4BFF),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFEEF1FF),
  onSecondaryContainer: Color(0xFF1F33C4),
  tertiary: Color(0xFF2F4BFF),
  onTertiary: Color(0xFFFFFFFF),
  error: Color(0xFFC42B3E),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFF4F5FB),
  onSurface: Color(0xFF14183A),
  onSurfaceVariant: Color(0xFF4A5072),
  surfaceDim: Color(0xFFF4F5FB),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFFFFFFF),
  surfaceContainerHighest: Color(0xFFEEF0F8),
  outline: Color(0xFF767DA3),
  outlineVariant: Color(0xFFE3E6F2),
  shadow: Color(0xFF000000),
  scrim: Color(0x7314183A),
  inverseSurface: Color(0xFF151A3A),
  onInverseSurface: Color(0xFFEEF0FF),
  inversePrimary: Color(0xFF8D9CFF),
  surfaceTint: Colors.transparent,
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF8D9CFF),
  onPrimary: Color(0xFF0B1240),
  primaryContainer: Color(0xFF232A66),
  onPrimaryContainer: Color(0xFFC9D0FF),
  secondary: Color(0xFF8D9CFF),
  onSecondary: Color(0xFF0B1240),
  secondaryContainer: Color(0xFF232A66),
  onSecondaryContainer: Color(0xFFC9D0FF),
  tertiary: Color(0xFF8D9CFF),
  onTertiary: Color(0xFF0B1240),
  error: Color(0xFFFF8A99),
  onError: Color(0xFF2A0710),
  surface: Color(0xFF0B0E24),
  onSurface: Color(0xFFEEF0FF),
  onSurfaceVariant: Color(0xFFA9AFD6),
  surfaceDim: Color(0xFF0B0E24),
  surfaceBright: Color(0xFF151A3A),
  surfaceContainerLowest: Color(0xFF151A3A),
  surfaceContainerLow: Color(0xFF151A3A),
  surfaceContainer: Color(0xFF151A3A),
  surfaceContainerHigh: Color(0xFF1E2450),
  surfaceContainerHighest: Color(0xFF0F1330),
  outline: Color(0xFF7880AD),
  outlineVariant: Color(0xFF2B315E),
  shadow: Color(0xFF000000),
  scrim: Color(0xA6000000),
  inverseSurface: Color(0xFFFFFFFF),
  onInverseSurface: Color(0xFF14183A),
  inversePrimary: Color(0xFF2F4BFF),
  surfaceTint: Colors.transparent,
);

/// Cashund roles that Material's [ColorScheme] has no slot for.
///
/// Read with `Theme.of(context).extension<CashundColors>()!`.
@immutable
class CashundColors extends ThemeExtension<CashundColors> {
  const CashundColors({
    required this.brand,
    required this.onBrand,
    required this.onBrandMuted,
    required this.positive,
    required this.warning,
    required this.warningFill,
    required this.track,
  });

  /// Cobalt band at the top of hero screens, the splash and the app icon.
  final Color brand;
  final Color onBrand;
  final Color onBrandMuted;

  /// Income amounts and "money kept" moments.
  final Color positive;

  /// Limit warning text and icons.
  final Color warning;

  /// Progress fill when a limit is close.
  final Color warningFill;

  /// Empty part of progress bars.
  final Color track;

  // The buddy's colors are identical in both themes.
  static const biscuitCoat = Color(0xFFC9772E);
  static const biscuitEar = Color(0xFF9A5420);
  static const biscuitMuzzle = Color(0xFFF3D2A8);
  static const biscuitInk = Color(0xFF3B2418);
  static const biscuitBlush = Color(0xFFF29C86);

  static const light = CashundColors(
    brand: Color(0xFF2F4BFF),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFE6E9FF),
    positive: Color(0xFF17784A),
    warning: Color(0xFF975800),
    warningFill: Color(0xFFAD6400),
    track: Color(0xFFDCE1FA),
  );

  static const dark = CashundColors(
    brand: Color(0xFF2A3FD6),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFCCD3FF),
    positive: Color(0xFF6FD49A),
    warning: Color(0xFFF5B44A),
    warningFill: Color(0xFFF5B44A),
    track: Color(0xFF2E3672),
  );

  @override
  CashundColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? onBrandMuted,
    Color? positive,
    Color? warning,
    Color? warningFill,
    Color? track,
  }) {
    return CashundColors(
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      onBrandMuted: onBrandMuted ?? this.onBrandMuted,
      positive: positive ?? this.positive,
      warning: warning ?? this.warning,
      warningFill: warningFill ?? this.warningFill,
      track: track ?? this.track,
    );
  }

  @override
  CashundColors lerp(ThemeExtension<CashundColors>? other, double t) {
    if (other is! CashundColors) return this;
    return CashundColors(
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onBrandMuted: Color.lerp(onBrandMuted, other.onBrandMuted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      track: Color.lerp(track, other.track, t)!,
    );
  }
}
