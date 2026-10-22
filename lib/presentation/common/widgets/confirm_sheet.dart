import 'package:cashund/core/theme/cashund_colors.dart';
import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// A note in a confirm sheet: a 20pt icon and one line of body text, which
/// can be rich to bold a word.
typedef ConfirmNote = ({IconData icon, InlineSpan text});

/// What the icon disc says: a question, a success or a real error.
enum ConfirmTone { neutral, success, error }

/// Asks before a consequential change that isn't a delete (deletes are
/// undoable instead). Resolves to `true` when the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  List<ConfirmNote> notes = const [],
}) async {
  final choice = await showChoiceSheet(
    context,
    icon: icon,
    title: title,
    body: body,
    notes: notes,
    confirmLabel: confirmLabel,
    secondaryLabel: cancelLabel,
  );
  return choice ?? false;
}

/// The confirm sheet's layout for any short decision or result: `true` for
/// the main button, `false` for the [secondaryLabel] one, `null` when
/// closed without either.
Future<bool?> showChoiceSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String confirmLabel,
  String? body,
  Widget? content,
  List<ConfirmNote> notes = const [],
  String? secondaryLabel,
  ConfirmTone tone = ConfirmTone.neutral,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _ConfirmSheet(
      icon: icon,
      tone: tone,
      title: title,
      body: body,
      content: content,
      notes: notes,
      confirmLabel: confirmLabel,
      secondaryLabel: secondaryLabel,
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    required this.content,
    required this.notes,
    required this.confirmLabel,
    required this.secondaryLabel,
  });

  final IconData icon;
  final ConfirmTone tone;
  final String title;
  final String? body;
  final Widget? content;
  final List<ConfirmNote> notes;
  final String confirmLabel;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = CashundText.body.copyWith(color: scheme.onSurface);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CashundSpace.s6,
          CashundSpace.s5,
          CashundSpace.s6,
          CashundSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tone == ConfirmTone.error
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: switch (tone) {
                    ConfirmTone.neutral => scheme.primary,
                    ConfirmTone.success => Theme.of(
                      context,
                    ).extension<CashundColors>()!.positive,
                    ConfirmTone.error => scheme.error,
                  },
                ),
              ),
            ),
            const SizedBox(height: CashundSpace.s5),
            Text(
              title,
              style: CashundText.title.copyWith(
                fontSize: 20,
                height: 26 / 20,
                color: scheme.onSurface,
              ),
            ),
            if (body case final body?) ...[
              const SizedBox(height: CashundSpace.s2),
              Text(
                body,
                style: CashundText.body.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (content case final content?) ...[
              const SizedBox(height: CashundSpace.s4),
              content,
            ],
            for (final note in notes) ...[
              const SizedBox(height: CashundSpace.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CashundSpace.s3,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      note.icon,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(style: ink, children: [note.text]),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: CashundSpace.s6),
            PrimaryButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            if (secondaryLabel case final label?) ...[
              const SizedBox(height: CashundSpace.s2),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
