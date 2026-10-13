import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// How pushed pages come and go, on both platforms. The new page slides in
/// from the right, casting a shadow over the old one, which drifts left and
/// dims. Popping plays it backwards.
///
/// Switching tabs doesn't use it; the tabs have their own transition.
final RouteType slideOverRouteType = RouteType.custom(
  duration: const Duration(milliseconds: 400),
  reverseDuration: const Duration(milliseconds: 400),
  transitionsBuilder: _slideOver,
);

/// [animation] drives this page coming in or leaving; [secondaryAnimation]
/// drives it moving aside while another page is pushed over it.
Widget _slideOver(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final incoming = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutCubic,
  );
  final covered = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeInOutCubic,
  );
  final dimmer = ColorTween(
    begin: Colors.transparent,
    end: Colors.black.withValues(alpha: 0.3),
  ).animate(covered);

  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(covered),
    child: AnimatedBuilder(
      animation: dimmer,
      builder: (context, child) => ColorFiltered(
        colorFilter: ColorFilter.mode(
          dimmer.value ?? Colors.transparent,
          BlendMode.srcOver,
        ),
        child: child,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(incoming),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    ),
  );
}
