import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/utils/amount_input.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:flutter/material.dart';

/// The big amount being typed, with the currency symbol in front.
class AmountInput extends StatelessWidget {
  const AmountInput({
    required this.currency,
    required this.onChanged,
    this.initialText = '',
    super.key,
  });

  final Currency currency;
  final ValueChanged<String> onChanged;

  /// What was typed before, e.g. when coming back from the category picker.
  final String initialText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = CashundText.amountInput.copyWith(color: scheme.onSurface);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 6,
      children: [
        Text(
          currency.symbol,
          style: CashundText.amountInput.copyWith(
            fontSize: 30,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: IntrinsicWidth(
            child: TextFormField(
              initialValue: initialText,
              autofocus: initialText.isEmpty,
              onChanged: onChanged,
              style: style,
              cursorColor: scheme.primary,
              keyboardType: TextInputType.numberWithOptions(
                decimal: currency.decimalDigits > 0,
              ),
              inputFormatters: [
                AmountInputFormatter(decimalDigits: currency.decimalDigits),
              ],
              // Plain text and a caret: no fill and no border in any state,
              // including the theme's focus ring.
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '0',
                hintStyle: style.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
