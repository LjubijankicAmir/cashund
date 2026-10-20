import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'limit_history.freezed.dart';

/// Spending in one of a limit's periods, against the amount it had then.
@freezed
abstract class LimitPeriodResult with _$LimitPeriodResult {
  const factory LimitPeriodResult({
    required DateRange range,
    required int spentMinor,

    /// `null` for a period before the limit existed.
    int? amountMinor,
  }) = _LimitPeriodResult;

  const LimitPeriodResult._();

  bool get isOver => amountMinor != null && spentMinor > amountMinor!;
}

/// How a limit went over its recent periods.
abstract final class LimitHistory {
  /// Spending per period in [ranges], from [spentByDay] (spending per day),
  /// with each period's own amount from [amounts] (oldest first).
  static List<LimitPeriodResult> results({
    required List<DateRange> ranges,
    required List<LimitAmount> amounts,
    required Map<DateTime, int> spentByDay,
  }) {
    return [
      for (final range in ranges)
        LimitPeriodResult(
          range: range,
          amountMinor: LimitAmount.amountFor(amounts, range.start),
          spentMinor: spentByDay.entries
              .where((day) => range.contains(day.key))
              .fold(0, (sum, day) => sum + day.value),
        ),
    ];
  }

  /// How many finished periods stayed within their limit, out of how many
  /// finished periods the limit existed for. The period around [today] is
  /// still running, so it doesn't count either way.
  static ({int kept, int of}) kept(
    List<LimitPeriodResult> results, {
    required DateTime today,
  }) {
    final finished = [
      for (final result in results)
        if (result.amountMinor != null && !result.range.end.isAfter(today))
          result,
    ];
    return (
      kept: finished.where((result) => !result.isOver).length,
      of: finished.length,
    );
  }
}
