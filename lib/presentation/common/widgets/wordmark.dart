import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:flutter/material.dart';

/// The "cashund" wordmark for the brand band. Brand text, never translated.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'cashund',
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w600,
        fontSize: 26,
        height: 1,
        color: Theme.of(context).extension<CashundColors>()!.onBrand,
      ),
    );
  }
}
