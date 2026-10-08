import 'package:flutter/widgets.dart';

/// [text] typed out character by character as [progress] runs from 0 to 1.
///
/// The full text's space is reserved from the start, so nothing around it
/// moves while it types, and screen readers get the whole text right away.
class TypewriterText extends StatelessWidget {
  const TypewriterText(
    this.text, {
    required this.progress,
    this.style,
    super.key,
  });

  final String text;
  final Animation<double> progress;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final characters = text.characters;

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Opacity(opacity: 0, child: Text(text, style: style)),
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) => Text(
                characters
                    .take((progress.value * characters.length).round())
                    .toString(),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
