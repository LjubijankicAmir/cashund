import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/domain/value_objects/transaction_filter.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/activity/activity_search.dart';
import 'package:cashund/presentation/activity/bloc/activity_filters_bloc.dart';
import 'package:cashund/presentation/activity/date_preset.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/category_mark.dart';
import 'package:cashund/presentation/common/widgets/form_field_row.dart';
import 'package:cashund/presentation/common/widgets/picker_field.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/quick_chip.dart';
import 'package:cashund/presentation/common/widgets/segmented_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens the filters on [filter]. Returns the filter to apply, or `null`
/// when the sheet is closed without applying.
Future<TransactionFilter?> showActivityFiltersSheet(
  BuildContext context, {
  required TransactionFilter filter,
  required String query,
}) {
  return showModalBottomSheet<TransactionFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<ActivityFiltersBloc>()
            ..add(ActivityFiltersEvent.started(filter)),
      child: _FiltersSheet(query: query),
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.query});

  /// The search in use, so the result count matches what will show.
  final String query;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  /// How many category chips show before "+N more".
  static const _collapsedCategories = 6;

  var _showAllCategories = false;

  Future<void> _pickDay(
    DateTime initial,
    ValueChanged<DateTime> onPicked,
    DateTime today,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ActivityFiltersBloc>();
    final state = context.watch<ActivityFiltersBloc>().state;
    final draft = state.draft;
    final sectionStyle = CashundText.labelSm.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final categories = state.categories;
    final shownCategories = _showAllCategories
        ? categories
        : categories.take(_collapsedCategories).toList();
    final hiddenCount = categories.length - shownCategories.length;
    final resultCount = switch (state.results) {
      final results? => searchEntries(
        results,
        widget.query,
        (category) => category.name(l10n),
      ).length,
      null => null,
    };
    final range = draft.range;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CashundSpace.s6,
              0,
              CashundSpace.s4,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activityFilters,
                    style: CashundText.pageTitle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s6,
                CashundSpace.s5,
                CashundSpace.s6,
                CashundSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.filtersType, style: sectionStyle),
                  const SizedBox(height: CashundSpace.s2),
                  SegmentedPills<TransactionType?>(
                    stretch: true,
                    segments: [
                      (null, l10n.filtersAll),
                      (TransactionType.expense, l10n.activityExpenses),
                      (TransactionType.income, l10n.activityIncomes),
                    ],
                    selected: draft.type,
                    onChanged: (type) =>
                        bloc.add(ActivityFiltersEvent.typeChanged(type)),
                  ),
                  const SizedBox(height: CashundSpace.s6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          draft.categoryIds.isEmpty
                              ? l10n.filtersCategories
                              : l10n.filtersCategoriesSelected(
                                  draft.categoryIds.length,
                                ),
                          style: sectionStyle,
                        ),
                      ),
                      if (draft.categoryIds.isNotEmpty)
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 32),
                          ),
                          onPressed: () => bloc.add(
                            const ActivityFiltersEvent.categoriesCleared(),
                          ),
                          child: Text(l10n.filtersClear),
                        ),
                    ],
                  ),
                  const SizedBox(height: CashundSpace.s2),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Wrap(
                      spacing: CashundSpace.s2,
                      runSpacing: CashundSpace.s2,
                      children: [
                        for (final category in shownCategories)
                          QuickChip(
                            leading: CategoryMark(
                              color: category.color,
                              height: 16,
                            ),
                            label: category.label(l10n),
                            selected: draft.categoryIds.contains(category.id),
                            onTap: () => bloc.add(
                              ActivityFiltersEvent.categoryToggled(category.id),
                            ),
                          ),
                        if (hiddenCount > 0)
                          QuickChip(
                            label: l10n.filtersMore(hiddenCount),
                            onTap: () =>
                                setState(() => _showAllCategories = true),
                          )
                        else if (categories.length > _collapsedCategories)
                          QuickChip(
                            label: l10n.filtersLess,
                            onTap: () =>
                                setState(() => _showAllCategories = false),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CashundSpace.s6),
                  Text(l10n.filtersDate, style: sectionStyle),
                  const SizedBox(height: CashundSpace.s2),
                  Wrap(
                    spacing: CashundSpace.s2,
                    runSpacing: CashundSpace.s2,
                    children: [
                      for (final (preset, label) in [
                        (DatePreset.thisWeek, l10n.filtersThisWeek),
                        (DatePreset.thisMonth, l10n.filtersThisMonth),
                        (DatePreset.lastMonth, l10n.filtersLastMonth),
                        (DatePreset.custom, l10n.filtersCustom),
                      ])
                        QuickChip(
                          label: label,
                          selected: state.preset == preset,
                          onTap: () => bloc.add(
                            ActivityFiltersEvent.presetSelected(preset),
                          ),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: range == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(
                              top: CashundSpace.s4,
                            ),
                            child: Row(
                              spacing: CashundSpace.s3,
                              children: [
                                Expanded(
                                  child: FormFieldRow(
                                    label: l10n.filtersFrom,
                                    child: PickerField(
                                      text: DateFormat.yMMMd(locale)
                                          .format(range.start),
                                      onTap: () => _pickDay(
                                        range.start,
                                        (day) => bloc.add(
                                          ActivityFiltersEvent.customFromChanged(
                                            day,
                                          ),
                                        ),
                                        state.today,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FormFieldRow(
                                    label: l10n.filtersTo,
                                    child: PickerField(
                                      text: DateFormat.yMMMd(locale)
                                          .format(range.lastDay),
                                      onTap: () => _pickDay(
                                        range.lastDay,
                                        (day) => bloc.add(
                                          ActivityFiltersEvent.customToChanged(
                                            day,
                                          ),
                                        ),
                                        state.today,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: CashundSpace.s4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s4,
                CashundSpace.s2,
                CashundSpace.s6,
                0,
              ),
              child: Row(
                spacing: CashundSpace.s2,
                children: [
                  TextButton(
                    onPressed: draft.isEmpty
                        ? null
                        : () => bloc.add(const ActivityFiltersEvent.reset()),
                    child: Text(l10n.filtersReset),
                  ),
                  Expanded(
                    child: PrimaryButton(
                      label: resultCount == null
                          ? l10n.filtersShowResults(0)
                          : l10n.filtersShowResults(resultCount),
                      onPressed: () => Navigator.of(context).pop(draft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
