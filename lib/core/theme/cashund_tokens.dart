import 'package:flutter/material.dart';

abstract final class CashundRadius {
  /// Tags and badges.
  static const sm = 10.0;

  /// Fields, emoji tiles and small cards.
  static const md = 16.0;

  /// Cards and buddy bubbles.
  static const lg = 22.0;

  /// The bubble corner that points at the buddy's avatar.
  static const tail = 6.0;

  /// The sheet over the brand band and bottom sheets.
  static const xl = 32.0;

  /// Buttons, chips, segmented controls, avatars and the FAB.
  static const full = 999.0;

  static const bubble = BorderRadius.only(
    topLeft: Radius.circular(tail),
    topRight: Radius.circular(lg),
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );
}

/// 4pt spacing scale.
abstract final class CashundSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s12 = 48.0;
}

abstract final class CashundShadow {
  /// Cards on the background.
  static List<BoxShadow> card(Brightness brightness) {
    return brightness == Brightness.dark
        ? const [
            BoxShadow(
              color: Color(0x59000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0D14183A),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color(0x0F14183A),
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ];
  }

  /// The primary button and the FAB only.
  static List<BoxShadow> primary(Brightness brightness) {
    return brightness == Brightness.dark
        ? const [
            BoxShadow(
              color: Color(0x73000000),
              offset: Offset(0, 6),
              blurRadius: 16,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x4D2F4BFF),
              offset: Offset(0, 6),
              blurRadius: 16,
            ),
          ];
  }

  /// Sheets, cast upward.
  static List<BoxShadow> sheet(Brightness brightness) {
    return brightness == Brightness.dark
        ? const [
            BoxShadow(
              color: Color(0x8C000000),
              offset: Offset(0, -8),
              blurRadius: 30,
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x1F14183A),
              offset: Offset(0, -8),
              blurRadius: 30,
            ),
          ];
  }
}
