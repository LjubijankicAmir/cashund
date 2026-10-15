import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/core/utils/date_format.dart';
import 'package:cashund/core/utils/money_format.dart';
import 'package:cashund/domain/entities/transaction_with_category.dart';
import 'package:cashund/domain/value_objects/currency.dart';
import 'package:cashund/domain/value_objects/date_range.dart';
import 'package:cashund/domain/value_objects/transaction_type.dart';
import 'package:cashund/presentation/activity/activity_search.dart';
import 'package:cashund/presentation/activity/bloc/activity_bloc.dart';
import 'package:cashund/presentation/activity/widgets/activity_chips.dart';
import 'package:cashund/presentation/activity/widgets/activity_filters_sheet.dart';
import 'package:cashund/presentation/activity/widgets/activity_no_results.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/common/widgets/buddy.dart';
import 'package:cashund/presentation/common/widgets/day_header.dart';
import 'package:cashund/presentation/common/widgets/transaction_row.dart';
import 'package:cashund/presentation/reaction/transaction_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The full history, with search and filters.
@RoutePage()
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ActivityBloc>()..add(const ActivityEvent.started()),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatefulWidget {
  const _ActivityView();

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setSearch(String query) {
    if (_search.text != query) _search.text = query;
    context.read<ActivityBloc>().add(ActivityEvent.searchChanged(query));
  }

  Future<void> _openFilters(ActivityState state) async {
    final bloc = context.read<ActivityBloc>();
    final filter = await showActivityFiltersSheet(
      context,
      filter: state.filter,
      query: state.query,
    );
    if (filter != null) bloc.add(ActivityEvent.filterChanged(filter));
  }

  /// Opens [entry] to change it; after a delete, offers to undo it.
  Future<void> _edit(TransactionWithCategory entry) {
    final bloc = context.read<ActivityBloc>();
    return editTransaction(
      context,
      entry.transaction,
      onUndo: (deleted) => bloc.add(ActivityEvent.deletionUndone(deleted)),
    );
  }

  void _swipeAway(TransactionWithCategory entry) {
    unawaited(HapticFeedback.mediumImpact());
    final bloc = context.read<ActivityBloc>()
      ..add(ActivityEvent.swipedAway(entry.transaction));
    offerUndo(
      context,
      entry.transaction,
      category: entry.category,
      onUndo: (deleted) => bloc.add(ActivityEvent.deletionUndone(deleted)),
    );
  }

  /// "October" for a whole month (with the year if it isn't this one),
  /// otherwise the span of days.
  String _dateLabel(DateRange range, DateTime today, String locale) {
    final wholeMonth =
        range.start.day == 1 &&
        range.end == DateTime(range.start.year, range.start.month + 1);
    if (!wholeMonth) return formatDateRange(range, locale);
    return range.start.year == today.year
        ? DateFormat.MMMM(locale).format(range.start)
        : DateFormat.yMMMM(locale).format(range.start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ActivityBloc>();
    final state = context.watch<ActivityBloc>().state;
    final currency =
        currencyByCode(state.preferences?.currencyCode ?? '') ??
        supportedCurrencies.first;
    final entries = state.shownEntries;
    final visible = entries == null
        ? null
        : searchEntries(
            entries,
            state.query,
            (category) => category.name(l10n),
          );
    final dateLabel = switch (state.filter.range) {
      final range? => _dateLabel(range, state.today, locale),
      null => null,
    };

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CashundSpace.s6,
                CashundSpace.s5,
                CashundSpace.s6,
                CashundSpace.s4,
              ),
              child: Text(
                l10n.activityTitle,
                style: CashundText.pageTitle.copyWith(color: scheme.onSurface),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CashundSpace.s6),
              child: ValueListenableBuilder(
                valueListenable: _search,
                builder: (context, value, _) => TextField(
                  controller: _search,
                  onChanged: _setSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    // White on the grey page, like a card.
                    fillColor: scheme.surfaceContainerLowest,
                    hintText: l10n.activitySearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(
                              right: CashundSpace.s2,
                            ),
                            // Small to look at; the touch area stays 48pt.
                            child: IconButton(
                              tooltip: l10n.activityClearSearch,
                              onPressed: () => _setSearch(''),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(28),
                                fixedSize: const Size.square(28),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              icon: const Icon(LucideIcons.x, size: 16),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CashundSpace.s3),
            ActivityChips(
              filter: state.filter,
              dateLabel: dateLabel,
              onFiltersPressed: () => _openFilters(state),
              onFilterChanged: (filter) =>
                  bloc.add(ActivityEvent.filterChanged(filter)),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (visible) {
                  null => const SizedBox.shrink(key: ValueKey('loading')),
                  [] => _Empty(
                    key: ValueKey(('empty', state.query, state.filter)),
                    state: state,
                    dateLabel: dateLabel,
                    onClearSearch: () => _setSearch(''),
                  ),
                  final visible => _History(
                    key: const ValueKey('history'),
                    entries: visible,
                    today: state.today,
                    currency: currency,
                    onEdit: _edit,
                    onDelete: _swipeAway,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The summary line and the transactions grouped by day.
class _History extends StatelessWidget {
  const _History({
    required this.entries,
    required this.today,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<TransactionWithCategory> entries;
  final DateTime today;
  final ValueChanged<TransactionWithCategory> onEdit;
  final ValueChanged<TransactionWithCategory> onDelete;

  /// Totals only count this currency; amounts in others can't be added up.
  final Currency currency;

  /// Signed amount in [currency], or 0 for other currencies.
  int _signedMinor(TransactionWithCategory entry) {
    final transaction = entry.transaction;
    if (transaction.currencyCode != currency.code) return 0;
    return transaction.type == TransactionType.income
        ? transaction.amountMinor
        : -transaction.amountMinor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // Entries come newest first, so each day's entries are together.
    final days = <(DateTime, List<TransactionWithCategory>)>[];
    for (final entry in entries) {
      final day = entry.transaction.occurredOn;
      if (days.isEmpty || days.last.$1 != day) days.add((day, []));
      days.last.$2.add(entry);
    }

    var income = 0;
    var expense = 0;
    for (final entry in entries) {
      final signed = _signedMinor(entry);
      if (signed > 0) income += signed;
      if (signed < 0) expense -= signed;
    }

    return ListView.builder(
      // Leaves room for the add button over the bottom bar.
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s3,
        CashundSpace.s6,
        CashundSpace.s12,
      ),
      itemCount: days.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            l10n.activitySummary(
              entries.length,
              formatMoney(income, currency, signed: true),
              formatMoney(-expense, currency),
            ),
            style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
          );
        }

        final (day, dayEntries) = days[index - 1];
        final net = dayEntries.fold(
          0,
          (sum, entry) => sum + _signedMinor(entry),
        );
        return Padding(
          padding: const EdgeInsets.only(top: CashundSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CashundSpace.s2,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CashundSpace.s1,
                ),
                child: DayHeader(
                  day: day,
                  today: today,
                  net: formatMoney(net, currency, signed: true),
                ),
              ),
              // Material, so the rows' tap ripple stays inside the corners.
              Material(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(CashundRadius.lg),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, entry) in dayEntries.indexed) ...[
                      if (index > 0)
                        const Divider(
                          indent: CashundSpace.s4,
                          endIndent: CashundSpace.s4,
                        ),
                      _SwipeToDelete(
                        entry: entry,
                        onDelete: () => onDelete(entry),
                        child: TransactionRow(
                          entry: entry,
                          onTap: () => onEdit(entry),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// No transactions to show: nothing logged yet, or nothing matching.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.state,
    required this.dateLabel,
    required this.onClearSearch,
    super.key,
  });

  final ActivityState state;
  final String? dateLabel;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ActivityBloc>();
    final buddyName = state.preferences?.buddyName ?? '';
    final query = state.query.trim();
    final nothingLogged = state.filter.isEmpty && query.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CashundSpace.s6,
        CashundSpace.s8,
        CashundSpace.s6,
        CashundSpace.s12,
      ),
      child: nothingLogged
          ? ActivityNoResults(
              expression: BuddyExpression.listening,
              title: l10n.activityEmptyTitle,
              message: l10n.activityEmptyBody,
              actions: [
                FilledButton.tonal(
                  onPressed: () => logTransaction(context),
                  child: Text(l10n.addExpense),
                ),
              ],
            )
          : ActivityNoResults(
              title: query.isEmpty
                  ? l10n.activityNoMatchesFilters
                  : l10n.activityNoMatchesSearch(query),
              message: switch (dateLabel) {
                final range? => l10n.activityNoMatchesBodyIn(buddyName, range),
                null => l10n.activityNoMatchesBody(buddyName),
              },
              actions: [
                if (query.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: onClearSearch,
                    child: Text(l10n.activityClearSearch),
                  ),
                if (state.filter.range != null)
                  OutlinedButton(
                    onPressed: () => bloc.add(
                      ActivityEvent.filterChanged(
                        state.filter.copyWith(range: null),
                      ),
                    ),
                    child: Text(l10n.activityAllDates),
                  ),
              ],
            ),
    );
  }
}

/// Swiping a row to the left deletes it. Screen readers get a Delete action
/// instead, since they can't swipe.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    required this.entry,
    required this.onDelete,
    required this.child,
  });

  final TransactionWithCategory entry;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.editTransactionDelete;

    return Semantics(
      customSemanticsActions: {CustomSemanticsAction(label: label): onDelete},
      child: Dismissible(
        key: ValueKey(entry.transaction.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: ColoredBox(
          color: scheme.error,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: CashundSpace.s6),
              child: Icon(LucideIcons.trash2, color: scheme.onError),
            ),
          ),
        ),
        child: ColoredBox(color: scheme.surfaceContainerLowest, child: child),
      ),
    );
  }
}
