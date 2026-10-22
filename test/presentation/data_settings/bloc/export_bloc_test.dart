import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/entities/transaction.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/domain/repositories/file_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/data_settings/bloc/export_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockData extends Mock implements DataRepository;

class _MockFiles extends Mock implements FileRepository;

class _MockTransactions extends Mock implements TransactionRepository;

class _MockClock extends Mock implements Clock;

void main() {
  final october = DateRange(start: DateTime(2026, 10), end: DateTime(2026, 11));
  final september = DateRange(start: DateTime(2026, 9), end: october.start);

  late _MockData data;
  late _MockFiles files;
  late _MockTransactions transactions;

  setUpAll(() {
    registerFallbackValue(const TransactionFilter());
    registerFallbackValue(october);
  });

  setUp(() {
    data = _MockData();
    files = _MockFiles();
    transactions = _MockTransactions();
    when(() => transactions.watchFiltered(any())).thenAnswer((invocation) {
      final filter = invocation.positionalArguments.first as TransactionFilter;
      final count = switch (filter.range) {
        null => 341,
        _ when filter.range == october => 54,
        _ when filter.range == september => 61,
        _ => 128,
      };
      return Stream.value(
        right(List<TransactionWithCategory>.filled(count, _entry)),
      );
    });
  });

  Future<ExportBloc> opened() async {
    final clock = _MockClock();
    when(clock.now).thenReturn(DateTime(2026, 10, 22, 14));
    final bloc = ExportBloc(data, files, transactions, clock)
      ..add(const ExportEvent.started());
    await pumpEventQueue();
    return bloc;
  }

  test('counts what each option would export', () async {
    final bloc = await opened();

    expect(bloc.state.counts, {
      ExportOption.allTime: 341,
      ExportOption.thisMonth: 54,
      ExportOption.lastMonth: 61,
      ExportOption.custom: 128,
    });
    expect(bloc.state.count, 341);
    await bloc.close();
  });

  test('a custom range includes its last day and picks itself', () async {
    final bloc = await opened();

    bloc.add(
      ExportEvent.customRangeChanged(
        from: DateTime(2026, 9, 30),
        to: DateTime(2026, 8),
      ),
    );
    await pumpEventQueue();

    expect(bloc.state.option, ExportOption.custom);
    expect(
      bloc.state.rangeOf(ExportOption.custom),
      DateRange(start: DateTime(2026, 8), end: DateTime(2026, 10)),
    );
    await bloc.close();
  });

  test('exports the chosen range and shares it as CSV', () async {
    when(
      () => data.exportCsv(
        categoryName: any(named: 'categoryName'),
        range: any(named: 'range'),
      ),
    ).thenAnswer((_) async => right('csv'));
    when(
      () => files.share(
        fileName: any(named: 'fileName'),
        contents: any(named: 'contents'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => right(true));
    final bloc = await opened();

    bloc
      ..add(const ExportEvent.optionSelected(ExportOption.lastMonth))
      ..add(ExportEvent.exportPressed((category) => ''));
    await pumpEventQueue();

    verify(
      () => data.exportCsv(
        categoryName: any(named: 'categoryName'),
        range: september,
      ),
    ).called(1);
    verify(
      () => files.share(
        fileName: 'cashund-transactions-2026-10-22.csv',
        contents: 'csv',
        mimeType: 'text/csv',
      ),
    ).called(1);
    expect(bloc.state.status, ExportStatus.shared);
    await bloc.close();
  });
}

final _entry = TransactionWithCategory(
  transaction: _transaction,
  category: _category,
);
const _category = Category(
  id: 1,
  type: TransactionType.expense,
  emoji: '🛒',
  color: CategoryColor.olive,
  sortOrder: 0,
);
final _transaction = Transaction(
  id: 1,
  type: TransactionType.expense,
  amountMinor: 100,
  currencyCode: 'USD',
  categoryId: 1,
  occurredOn: DateTime(2026, 10, 3),
  createdAt: DateTime(2026, 10, 3),
);
