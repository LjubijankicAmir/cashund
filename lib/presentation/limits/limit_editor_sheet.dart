import 'package:cashund/core/di/injection.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/domain/entities/spending_limit.dart';
import 'package:cashund/domain/value_objects/limit_period.dart';
import 'package:cashund/domain/value_objects/limit_progress.dart';
import 'package:cashund/presentation/common/extensions/category_display.dart';
import 'package:cashund/presentation/limits/bloc/limit_editor_bloc.dart';
import 'package:cashund/presentation/limits/widgets/limit_editor_form.dart';
import 'package:cashund/presentation/limits/widgets/limit_target_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What happened in the limit editor, if anything.
sealed class LimitEditorResult {
  const LimitEditorResult();
}

final class LimitSaved extends LimitEditorResult {
  const LimitSaved();
}

/// The limit was deleted; [snapshot] brings it back for undo.
final class LimitDeleted extends LimitEditorResult {
  const LimitDeleted(this.snapshot, {required this.name});

  final LimitSnapshot snapshot;

  /// "Eating Out", or "All spending".
  final String name;
}

/// Opens the editor for a new [period] limit, or to change [editing].
Future<LimitEditorResult?> showLimitEditor(
  BuildContext context, {
  LimitPeriod period = LimitPeriod.week,
  LimitProgress? editing,
}) {
  return showModalBottomSheet<LimitEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<LimitEditorBloc>()
            ..add(LimitEditorEvent.started(period: period, editing: editing)),
      child: const LimitEditorSheet(),
    ),
  );
}

/// The form, and the picker sliding over it within the same sheet.
class LimitEditorSheet extends StatefulWidget {
  const LimitEditorSheet({super.key});

  @override
  State<LimitEditorSheet> createState() => _LimitEditorSheetState();
}

class _LimitEditorSheetState extends State<LimitEditorSheet> {
  // A new limit starts by choosing what it's on.
  late bool _choosingTarget = !context.read<LimitEditorBloc>().state.isEditing;

  void _showPicker(bool show) {
    FocusScope.of(context).unfocus();
    setState(() => _choosingTarget = show);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<LimitEditorBloc, LimitEditorState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case LimitEditorStatus.saved:
            Navigator.of(context).pop(const LimitSaved());
          case LimitEditorStatus.deleted:
            Navigator.of(context).pop(
              LimitDeleted(
                state.deleted!,
                name: switch (state.target) {
                  CategoryTarget(:final category) => category.name(
                    context.l10n,
                  ),
                  _ => context.l10n.limitAllSpending,
                },
              ),
            );
          case LimitEditorStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.limitEditorSaveFailed)),
            );
          case LimitEditorStatus.editing || LimitEditorStatus.saving:
            break;
        }
      },
      child: PopScope(
        // In the picker, back returns to the form, unless nothing's chosen.
        canPop:
            !_choosingTarget ||
            context.select<LimitEditorBloc, bool>(
              (bloc) => bloc.state.target == null,
            ),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showPicker(false);
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final fromRight = child.key == const ValueKey('picker');
                return SlideTransition(
                  position: Tween(
                    begin: Offset(fromRight ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: _choosingTarget
                  ? LimitTargetPicker(
                      key: const ValueKey('picker'),
                      onPicked: () => _showPicker(false),
                    )
                  : LimitEditorForm(
                      key: const ValueKey('form'),
                      onChooseTarget: () => _showPicker(true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
