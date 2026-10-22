import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';

/// Something the buddy says, and how they look saying it.
abstract interface class BuddyLine {
  BuddyExpression get expression;

  String text(AppLocalizations l10n);
}
