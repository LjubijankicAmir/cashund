import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/category.dart';

extension CategoryDisplay on Category {
  /// The user's name for it, or the translated default of a built-in one.
  String name(AppLocalizations l10n) =>
      customName ?? l10n.categoryName(predefinedKey ?? '');

  /// "🍔 Eating Out": the emoji always sits right before the name.
  String label(AppLocalizations l10n) => '$emoji ${name(l10n)}';
}
