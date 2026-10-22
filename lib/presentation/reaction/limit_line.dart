import 'dart:math';

import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/extensions/limit_display.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/reaction/buddy_line.dart';
import 'package:flutter/foundation.dart';

/// The buddy on a limit at 80% or more, or over: always worried, never
/// alarmed. One of a dozen lines per level.
@immutable
class LimitLine implements BuddyLine {
  const LimitLine(this.progress, this.index, {required this.currency});

  /// The same line all day for the same limit, so Home doesn't flicker
  /// between lines as it rebuilds.
  LimitLine.forDay(this.progress, DateTime day, {required this.currency})
    : index = (progress.limit.id * 7 + day.day) % lineCount;

  /// A random line, other than [previous] when it's for the same level.
  LimitLine.random(
    this.progress, {
    required this.currency,
    required Random random,
    LimitLine? previous,
  }) : index = _randomIndex(progress, random, previous);

  final LimitProgress progress;
  final int index;

  /// Amounts are written in it.
  final Currency currency;

  static const lineCount = 12;

  static int _randomIndex(
    LimitProgress progress,
    Random random,
    LimitLine? previous,
  ) {
    final repeat =
        previous != null && previous.progress.status == progress.status;
    final index = random.nextInt(repeat ? lineCount - 1 : lineCount);
    return repeat && index >= previous.index ? index + 1 : index;
  }

  @override
  BuddyExpression get expression => BuddyExpression.worried;

  @override
  String text(AppLocalizations l10n) {
    final over = progress.status == LimitStatus.over;
    final period = progress.limit.period.name;
    final amount = formatMoney(
      over ? progress.overByMinor : progress.leftMinor,
      currency,
    );
    final line = over ? l10n.limitLineOver : l10n.limitLineNear;
    return line(
      '$index',
      progress.name(l10n),
      '${progress.percent}%',
      amount,
      l10n.limitPeriodThis(period),
      l10n.limitPeriodThisPossessive(period),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LimitLine && other.progress == progress && other.index == index;

  @override
  int get hashCode => Object.hash(progress, index);
}
