import 'package:cashund/core/theme/cashund_text.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// A note in a confirm sheet: a 20pt icon and one line of body text, which
/// can be rich to bold a word.
typedef ConfirmNote = ({IconData icon, InlineSpan text});

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
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (context) => _ConfirmSheet(
      icon: icon,
      title: title,
      body: body,
      notes: notes,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.notes,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<ConfirmNote> notes;
  final String confirmLabel;
  final String cancelLabel;

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
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: scheme.primary),
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
            const SizedBox(height: CashundSpace.s2),
            Text(
              body,
              style: CashundText.body.copyWith(color: scheme.onSurfaceVariant),
            ),
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
            const SizedBox(height: CashundSpace.s2),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}
