import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'limit_progress.freezed.dart';

/// Where spending stands against a limit.
enum LimitStatus {
  under,

  /// At [LimitProgress.nearShare] or more of the limit.
  near,

  /// Past the limit.
  over,
}

/// How much of a limit is used in one of its periods.
@freezed
abstract class LimitProgress with _$LimitProgress {
  const factory LimitProgress({
    required SpendingLimit limit,
    required DateRange range,
    required int amountMinor,
    required int spentMinor,

    /// `null` for the overall limit.
    Category? category,
  }) = _LimitProgress;

  const LimitProgress._();

  /// From this share of the limit on, the buddy gives a heads-up.
  static const nearShare = 0.8;

  /// Spent as a share of the limit; can go past 1.
  double get fraction => amountMinor <= 0 ? 0 : spentMinor / amountMinor;

  /// Spent as a whole percentage of the limit, rounded down so 79.9% never
  /// reads as 80%.
  int get percent => amountMinor <= 0 ? 0 : spentMinor * 100 ~/ amountMinor;

  LimitStatus get status => switch (fraction) {
    > 1 => LimitStatus.over,
    >= nearShare => LimitStatus.near,
    _ => LimitStatus.under,
  };

  /// What's left before the limit; 0 once it's reached.
  int get leftMinor => spentMinor >= amountMinor ? 0 : amountMinor - spentMinor;

  /// How far past the limit; 0 until then.
  int get overByMinor =>
      spentMinor > amountMinor ? spentMinor - amountMinor : 0;

  /// Whole days left in the period, today included.
  int daysLeft(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    if (!range.contains(day)) return 0;
    // Counted in calendar days, so daylight saving doesn't shift it.
    return DateTime.utc(
      range.end.year,
      range.end.month,
      range.end.day,
    ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  }

  /// Most used first; ties go to the bigger amount spent.
  static int byUse(LimitProgress a, LimitProgress b) {
    final byFraction = b.fraction.compareTo(a.fraction);
    return byFraction != 0 ? byFraction : b.spentMinor.compareTo(a.spentMinor);
  }
}
