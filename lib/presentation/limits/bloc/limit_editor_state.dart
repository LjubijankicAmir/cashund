part of 'limit_editor_bloc.dart';

/// What a limit is on: all spending, or one category.
@freezed
sealed class LimitTarget with _$LimitTarget {
  const factory LimitTarget.overall() = OverallTarget;
  const factory LimitTarget.category(Category category) = CategoryTarget;

  const LimitTarget._();

  int? get categoryId => switch (this) {
    OverallTarget() => null,
    CategoryTarget(:final category) => category.id,
  };
}

enum LimitEditorStatus { editing, saving, saved, deleted, failure }

@freezed
abstract class LimitEditorState with _$LimitEditorState {
  const factory LimitEditorState({
    required DateTime today,
    @Default(LimitPeriod.week) LimitPeriod period,

    /// The limit being changed, as it was; `null` for a new one.
    LimitProgress? editing,
    LimitTarget? target,
    @Default('') String amountText,

    /// `null` until preferences load.
    UserPreferences? preferences,

    /// Expense categories that can have limits, in the user's order.
    @Default(<Category>[]) List<Category> categories,

    /// Every limit in the current currency, to tell which are taken.
    @Default(<SpendingLimit>[]) List<SpendingLimit> limits,

    /// This period's spending on [target] so far.
    @Default(0) int spentMinor,
    @Default(LimitEditorStatus.editing) LimitEditorStatus status,

    /// The deleted limit, once [status] is `deleted`, for undo.
    LimitSnapshot? deleted,
  }) = _LimitEditorState;

  const LimitEditorState._();

  bool get isEditing => editing != null;

  Currency? get currency => switch (preferences) {
    final preferences? => currencyByCode(preferences.currencyCode),
    null => null,
  };

  DateRange? get range => switch (preferences) {
    final preferences? => period.rangeContaining(
      today,
      weekStart: preferences.weekStart,
    ),
    null => null,
  };

  int? get amountMinor => switch (currency) {
    final currency? => parseAmount(amountText, currency),
    null => null,
  };

  /// Whether [target] already has a limit for [period] (other than the one
  /// being edited).
  bool isTaken(LimitTarget target) => limits.any(
    (limit) =>
        limit.period == period &&
        limit.categoryId == target.categoryId &&
        limit.id != editing?.limit.id,
  );

  /// How the limit would look with this period's spending so far.
  LimitProgress? get preview {
    final (target, range, amount) = (this.target, this.range, amountMinor);
    if (target == null || range == null || amount == null || amount <= 0) {
      return null;
    }
    return LimitProgress(
      limit: SpendingLimit(
        id: editing?.limit.id ?? 0,
        period: period,
        currencyCode: preferences!.currencyCode,
        createdAt: today,
        categoryId: target.categoryId,
      ),
      category: switch (target) {
        CategoryTarget(:final category) => category,
        OverallTarget() => null,
      },
      range: range,
      amountMinor: amount,
      spentMinor: spentMinor,
    );
  }

  bool get canSave =>
      target != null &&
      (amountMinor ?? 0) > 0 &&
      !isTaken(target!) &&
      status != LimitEditorStatus.saving;
}
