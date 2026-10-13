import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/domain/value_objects/week_start.dart';
import 'package:cashund/presentation/activity/activity_search.dart';
import 'package:cashund/presentation/activity/date_preset.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionWithCategory _entry(String? title, String categoryName) =>
    TransactionWithCategory(
      transaction: Transaction(
        id: 1,
        type: TransactionType.expense,
        amountMinor: 100,
        currencyCode: 'EUR',
        categoryId: 1,
        title: title,
        occurredOn: DateTime(2026, 10, 8),
        createdAt: DateTime(2026, 10, 8),
      ),
      category: Category(
        id: 1,
        type: TransactionType.expense,
        emoji: '🍔',
        color: CategoryColor.apricot,
        sortOrder: 0,
        customName: categoryName,
      ),
    );

void main() {
  group('searchEntries', () {
    final lunch = _entry('Lunch with Sara', 'Eating Out');
    final bus = _entry(null, 'Transport');
    String nameOf(Category category) => category.customName!;

    test('matches the title or the category name, ignoring case', () {
      expect(searchEntries([lunch, bus], 'SARA', nameOf), [lunch]);
      expect(searchEntries([lunch, bus], 'transp', nameOf), [bus]);
    });

    test('keeps everything for an empty search', () {
      expect(searchEntries([lunch, bus], '   ', nameOf), [lunch, bus]);
    });
  });

  group('DatePreset', () {
    // Thursday.
    final today = DateTime(2026, 10, 8);

    test('covers this week, this month and last month', () {
      expect(
        DatePreset.thisWeek.rangeAround(today, WeekStart.monday)!.start,
        DateTime(2026, 10, 5),
      );
      expect(
        DatePreset.thisMonth.rangeAround(today, WeekStart.monday)!.start,
        DateTime(2026, 10),
      );
      expect(
        DatePreset.lastMonth.rangeAround(today, WeekStart.monday),
        DateRange(start: DateTime(2026, 9), end: DateTime(2026, 10)),
      );
      expect(
        DatePreset.lastMonth
            .rangeAround(DateTime(2026, 1, 15), WeekStart.monday)!
            .start,
        DateTime(2025, 12),
      );
    });

    test('recognizes a preset from its range and anything else as custom', () {
      final september = DateRange(
        start: DateTime(2026, 9),
        end: DateTime(2026, 10),
      );
      final someDays = DateRange(
        start: DateTime(2026, 10, 2),
        end: DateTime(2026, 10, 6),
      );

      expect(
        DatePreset.of(september, today, WeekStart.monday),
        DatePreset.lastMonth,
      );
      expect(
        DatePreset.of(someDays, today, WeekStart.monday),
        DatePreset.custom,
      );
    });
  });
}
