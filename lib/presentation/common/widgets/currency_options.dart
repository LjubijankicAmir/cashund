import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/presentation/common/widgets/option_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A search field above the supported currencies as option cards. Only the
/// list scrolls, so it needs a bounded height.
class CurrencyOptions extends StatefulWidget {
  const CurrencyOptions({
    required this.selectedCode,
    required this.onSelected,
    this.listPadding = EdgeInsets.zero,
    super.key,
  });

  final String selectedCode;
  final ValueChanged<Currency> onSelected;

  /// Around the list, e.g. to keep the last card clear of a pinned button.
  final EdgeInsets listPadding;

  @override
  State<CurrencyOptions> createState() => _CurrencyOptionsState();
}

class _CurrencyOptionsState extends State<CurrencyOptions> {
  String _query = '';

  List<Currency> _matching(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return supportedCurrencies;
    return [
      for (final currency in supportedCurrencies)
        if ('${l10n.currencyName(currency.code)} ${currency.code} ${currency.symbol}'
            .toLowerCase()
            .contains(query))
          currency,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final matching = _matching(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.currencySearchHint,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
          ),
        ),
        const SizedBox(height: CashundSpace.s3),
        Expanded(
          child: matching.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: CashundSpace.s6,
                  ),
                  child: Text(
                    l10n.currencyNoResults(_query.trim()),
                    textAlign: TextAlign.center,
                    style: CashundText.body.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: widget.listPadding,
                  itemCount: matching.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: CashundSpace.s3),
                  itemBuilder: (context, index) {
                    final currency = matching[index];
                    return OptionCard(
                      title: l10n.currencyName(currency.code),
                      subtitle: currency.code,
                      trailing: Text(
                        currency.symbol,
                        style: CashundText.title.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      selected: currency.code == widget.selectedCode,
                      onTap: () => widget.onSelected(currency),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
