import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_messages.freezed.dart';

/// Which recap line fits how a finished week or month went.
enum RecapLine {
  weekLess,
  weekMore,
  weekTopCategory,
  weekLimitsKept,
  monthLess,
  monthMore,
  monthKept,
  monthSummary;

  /// Lines about a period that went better than the one before.
  bool get isGood =>
      const {weekLess, weekLimitsKept, monthLess, monthKept}.contains(this);
}

/// How a finished week or month went, for the buddy's recap.
@freezed
abstract class PeriodRecap with _$PeriodRecap {
  const factory PeriodRecap({
    required LimitPeriod period,

    /// The finished period.
    required DateRange range,
    required int spentMinor,
    required int incomeMinor,

    /// Spent in the period before it; 0 when nothing was logged then.
    @Default(0) int previousSpentMinor,

    /// The category spent on most; `null` when nothing was spent.
    CategorySpending? top,

    /// How many of the period's limits it stayed within; `null` without
    /// limits.
    ({int kept, int of})? limitsKept,
  }) = _PeriodRecap;

  const PeriodRecap._();

  /// Worth a recap: something was spent.
  bool get hasNews => spentMinor > 0;

  /// What it came to against the period before, as a positive amount.
  int get differenceMinor => (spentMinor - previousSpentMinor).abs();

  /// Of what came in, the share not spent; can be negative.
  int get keptPercent =>
      incomeMinor == 0 ? 0 : (incomeMinor - spentMinor) * 100 ~/ incomeMinor;

  RecapLine get line {
    final compared = previousSpentMinor > 0;
    final less = compared && spentMinor < previousSpentMinor;
    final more = compared && spentMinor > previousSpentMinor;
    final allKept = switch (limitsKept) {
      (:final kept, :final of) => of > 0 && kept == of,
      null => false,
    };

    return switch (period) {
      LimitPeriod.week when less => RecapLine.weekLess,
      LimitPeriod.week when allKept => RecapLine.weekLimitsKept,
      LimitPeriod.week when more => RecapLine.weekMore,
      LimitPeriod.week => RecapLine.weekTopCategory,
      LimitPeriod.month when less => RecapLine.monthLess,
      LimitPeriod.month when more => RecapLine.monthMore,
      LimitPeriod.month when incomeMinor > spentMinor => RecapLine.monthKept,
      LimitPeriod.month => RecapLine.monthSummary,
    };
  }
}

/// What the buddy says on Home, beyond the everyday messages.
@freezed
sealed class HomeMessage with _$HomeMessage {
  /// A limit at 80% or more, or over.
  const factory HomeMessage.limit(LimitProgress progress) = LimitMessage;

  /// How the last week or month went, once.
  const factory HomeMessage.recap(PeriodRecap recap) = RecapMessage;
}

/// Picks Home's message: a limit over, then a limit close to it, then a
/// recap. Messages the user closed stay closed, see [keyOf].
abstract final class HomeMessages {
  static HomeMessage? pick({
    required List<LimitProgress> limits,

    /// Month first: when a week and a month end together, the month wins.
    required List<PeriodRecap> recaps,
    required Map<String, DateTime> dismissed,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);

    final warnings =
        [
          for (final limit in limits)
            if (limit.status != LimitStatus.under &&
                // Closed today at this level; tomorrow, or over, it's back.
                dismissed[limitKey(limit)] != day)
              limit,
        ]..sort((a, b) {
          final byStatus = b.status.index.compareTo(a.status.index);
          return byStatus != 0 ? byStatus : b.fraction.compareTo(a.fraction);
        });
    if (warnings.isNotEmpty) return HomeMessage.limit(warnings.first);

    for (final recap in recaps) {
      if (recap.hasNews && !dismissed.containsKey(recapKey(recap))) {
        return HomeMessage.recap(recap);
      }
    }
    return null;
  }

  /// Identifies [message] for remembering that it was closed.
  static String keyOf(HomeMessage message) => switch (message) {
    LimitMessage(:final progress) => limitKey(progress),
    RecapMessage(:final recap) => recapKey(recap),
  };

  /// One limit at one level, so going from close to over shows again.
  static String limitKey(LimitProgress progress) =>
      'limit:${progress.limit.id}:${progress.status.name}';

  /// One recap per finished period.
  static String recapKey(PeriodRecap recap) {
    final start = recap.range.start;
    final day =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
    return 'recap:${recap.period.name}:$day';
  }
}
