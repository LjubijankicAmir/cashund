import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cashund/core/utils/clock.dart';
import 'package:cashund/domain/entities/category.dart';
import 'package:cashund/domain/repositories/data_repository.dart';
import 'package:cashund/domain/repositories/file_repository.dart';
import 'package:cashund/domain/repositories/transaction_repository.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'export_bloc.freezed.dart';
part 'export_event.dart';
part 'export_state.dart';

/// The CSV export sheet: which transactions, and sharing the file.
@injectable
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  ExportBloc(this._data, this._files, this._transactions, Clock clock)
    : super(ExportState.initial(clock.now())) {
    on<_Started>((event, emit) async {
      add(const ExportEvent.customCounted());
      await Future.wait([
        for (final option in [
          ExportOption.allTime,
          ExportOption.thisMonth,
          ExportOption.lastMonth,
        ])
          _count(emit, option),
      ]);
    });
    on<_OptionSelected>(
      (event, emit) => emit(state.copyWith(option: event.option)),
    );
    on<_CustomRangeChanged>((event, emit) {
      final (from, to) = event.from.isAfter(event.to)
          ? (event.to, event.from)
          : (event.from, event.to);
      emit(
        state.copyWith(
          customFrom: from,
          customTo: to,
          option: ExportOption.custom,
        ),
      );
      add(const ExportEvent.customCounted());
    });
    // A new range replaces the old count.
    on<_CustomCounted>(
      (event, emit) => _count(emit, ExportOption.custom),
      transformer: restartable(),
    );
    on<_ExportPressed>(_onExportPressed, transformer: droppable());
  }

  final DataRepository _data;
  final FileRepository _files;
  final TransactionRepository _transactions;

  /// "cashund-transactions-2026-10-22.csv"
  static String fileName(DateTime day) =>
      'cashund-transactions-${day.year}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}.csv';

  Future<void> _count(Emitter<ExportState> emit, ExportOption option) {
    return emit.forEach(
      _transactions.watchFiltered(
        TransactionFilter(range: state.rangeOf(option)),
      ),
      onData: (result) => switch (result.getRight().toNullable()) {
        final entries? => state.copyWith(
          counts: {...state.counts, option: entries.length},
        ),
        null => state,
      },
    );
  }

  Future<void> _onExportPressed(
    _ExportPressed event,
    Emitter<ExportState> emit,
  ) async {
    if (!state.canExport) return;
    emit(state.copyWith(status: ExportStatus.working));

    final csv = (await _data.exportCsv(
      categoryName: event.categoryName,
      range: state.rangeOf(state.option),
    )).getRight().toNullable();
    final shared = csv == null
        ? null
        : (await _files.share(
            fileName: fileName(state.today),
            contents: csv,
            mimeType: 'text/csv',
          )).getRight().toNullable();

    emit(
      state.copyWith(
        status: switch (shared) {
          true => ExportStatus.shared,
          false => ExportStatus.editing,
          null => ExportStatus.failed,
        },
      ),
    );
  }
}
