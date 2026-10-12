import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'spending_breakdown.freezed.dart';

/// One part of the spending chart: a category, or everything else together.
@freezed
abstract class SpendingSlice with _$SpendingSlice {
  const factory SpendingSlice({
    /// `null` for the slice that groups the remaining categories.
    required Category? category,
    required int amountMinor,

    /// Whole percent of the total. All slices add up to exactly 100.
    required int percent,
  }) = _SpendingSlice;
}

/// Turns spending per category into chart slices: the biggest [maxCategories]
/// on their own, the rest grouped into one, largest first.
abstract final class SpendingBreakdown {
  static const maxCategories = 5;

  static List<SpendingSlice> slicesOf(List<CategorySpending> spending) {
    final sorted = [...spending.where((item) => item.amountMinor > 0)]
      ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    final total = sorted.fold(0, (sum, item) => sum + item.amountMinor);
    if (total == 0) return const [];

    final parts = <(Category?, int)>[
      for (final item in sorted.take(maxCategories))
        (item.category, item.amountMinor),
      if (sorted.length > maxCategories)
        (
          null,
          sorted
              .skip(maxCategories)
              .fold(0, (sum, item) => sum + item.amountMinor),
        ),
    ];

    final percents = _percentsSummingTo100([
      for (final (_, amount) in parts) amount,
    ], total);
    return [
      for (final (index, (category, amount)) in parts.indexed)
        SpendingSlice(
          category: category,
          amountMinor: amount,
          percent: percents[index],
        ),
    ];
  }

  /// Rounds each share down, then gives the leftover points to the shares
  /// that lost the most in rounding (the largest remainder method), so the
  /// percentages never add up to 99 or 101.
  static List<int> _percentsSummingTo100(List<int> amounts, int total) {
    final exact = [for (final amount in amounts) amount * 100 / total];
    final percents = [for (final value in exact) value.floor()];
    final byRemainder = List.generate(amounts.length, (index) => index)
      ..sort(
        (a, b) => (exact[b] - percents[b]).compareTo(exact[a] - percents[a]),
      );

    var leftover = 100 - percents.fold(0, (sum, value) => sum + value);
    for (final index in byRemainder) {
      if (leftover == 0) break;
      percents[index]++;
      leftover--;
    }
    return percents;
  }
}
