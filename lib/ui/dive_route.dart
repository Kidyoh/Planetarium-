import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// "Fly into the visor": the new page is revealed through the visor's oval,
/// which grows at the same rate the home page zooms toward it.
class DiveRoute<T> extends PageRouteBuilder<T> {
  DiveRoute({required this.visor, required WidgetBuilder builder})
      : super(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 1250),
          reverseTransitionDuration: const Duration(milliseconds: 950),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) =>
              _DiveTransition(animation: animation, visor: visor, child: child),
        );

  final Rect visor;

  /// Scale at which an oval of [visor] covers the whole [screen].
  static double coverScale(Rect visor, Size screen) {
    final a = visor.width / 2;
    final b = visor.height / 2;
    var k = 0.0;
    for (final corner in [Offset.zero, Offset(screen.width, 0), Offset(0, screen.height), Offset(screen.width, screen.height)]) {
      final d = corner - visor.center;
      k = math.max(k, math.sqrt((d.dx / a) * (d.dx / a) + (d.dy / b) * (d.dy / b)));
    }
    return k * 1.04;
  }
}

class _DiveTransition extends StatelessWidget {
  const _DiveTransition({required this.animation, required this.visor, required this.child});
  final Animation<double> animation;
  final Rect visor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final cover = DiveRoute.coverScale(visor, size);
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(animation.value);
          if (t >= 1) return child!;
          final zoom = math.pow(cover, t).toDouble();
          final oval = Rect.fromCenter(center: visor.center, width: visor.width * zoom, height: visor.height * zoom);
          // Inner content starts zoomed out, as if seen in the reflection.
          final inner = ui.lerpDouble(0.45, 1, Curves.easeOutCubic.transform(t))!;
          final c0 = visor.center;
          return ClipPath(
            clipper: _OvalClipper(oval),
            child: Transform(
              transform: Matrix4.identity()
                ..translateByDouble(c0.dx, c0.dy, 0, 1)
                ..scaleByDouble(inner, inner, 1, 1)
                ..translateByDouble(-c0.dx, -c0.dy, 0, 1),
              child: Opacity(opacity: Interval(0.0, 0.35).transform(animation.value), child: child),
            ),
          );
        },
        child: child,
      );
    });
  }
}

class _OvalClipper extends CustomClipper<Path> {
  _OvalClipper(this.oval);
  final Rect oval;

  @override
  Path getClip(Size size) => Path()..addOval(oval);

  @override
  bool shouldReclip(_OvalClipper old) => old.oval != oval;
}
