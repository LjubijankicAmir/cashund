import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';

extension LimitDisplay on LimitProgress {
  /// "Eating Out", or "All spending" for the overall limit.
  String name(AppLocalizations l10n) =>
      category?.name(l10n) ?? l10n.limitAllSpending;

  /// "🍔 Eating Out", or "All spending" for the overall limit.
  String label(AppLocalizations l10n) =>
      category?.label(l10n) ?? l10n.limitAllSpending;
}
