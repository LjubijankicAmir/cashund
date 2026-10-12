import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_summary.freezed.dart';

/// What came in and went out over a period, in one currency's minor units.
@freezed
abstract class PeriodSummary with _$PeriodSummary {
  const factory PeriodSummary({
    @Default(0) int incomeMinor,
    @Default(0) int expenseMinor,
    @Default(0) int transactionCount,
  }) = _PeriodSummary;

  const PeriodSummary._();

  /// Income minus expenses; negative when more went out than came in.
  int get balanceMinor => incomeMinor - expenseMinor;

  bool get isEmpty => transactionCount == 0;
}
