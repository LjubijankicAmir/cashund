import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/services/spending_breakdown.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/category_spending.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

CategorySpending _spent(int id, int amount) => CategorySpending(
  category: Category(
    id: id,
    type: TransactionType.expense,
    emoji: '🛒',
    color: CategoryColor.olive,
    sortOrder: id,
  ),
  amountMinor: amount,
);

void main() {
  test('nothing spent gives no slices', () {
    expect(SpendingBreakdown.slicesOf([]), isEmpty);
  });

  test('orders categories from largest to smallest', () {
    final slices = SpendingBreakdown.slicesOf([_spent(1, 100), _spent(2, 300)]);

    expect(slices.map((slice) => slice.category?.id), [2, 1]);
    expect(slices.map((slice) => slice.percent), [75, 25]);
  });

  test('groups everything past the top five into one slice', () {
    final slices = SpendingBreakdown.slicesOf([
      for (var id = 1; id <= 7; id++) _spent(id, id * 100),
    ]);

    expect(slices, hasLength(6));
    expect(slices.last.category, isNull);
    expect(slices.last.amountMinor, 100 + 200);
  });

  test('percentages always add up to exactly 100', () {
    final thirds = SpendingBreakdown.slicesOf([
      _spent(1, 100),
      _spent(2, 100),
      _spent(3, 100),
    ]);
    final uneven = SpendingBreakdown.slicesOf([
      _spent(1, 1),
      _spent(2, 1),
      _spent(3, 998),
    ]);

    expect(thirds.fold(0, (sum, slice) => sum + slice.percent), 100);
    expect(uneven.fold(0, (sum, slice) => sum + slice.percent), 100);
  });
}
