import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../data/bodies.dart';

/// Compiled `planet.frag`, loaded once in `main`.
late final ui.FragmentProgram planetProgram;

Future<void> loadShaders() async {
  planetProgram = await ui.FragmentProgram.fromAsset('assets/shaders/planet.frag');
}

/// App-wide animation clock in seconds. Every animated painter repaints off
/// this single notifier instead of owning its own ticker.
final SpaceClock spaceClock = SpaceClock._();

class SpaceClock extends ChangeNotifier implements ValueListenable<double> {
  SpaceClock._();
  double _t = 0;

  @override
  double get value => _t;

  void _tick(Duration elapsed) {
    _t = elapsed.inMicroseconds / 1e6;
    notifyListeners();
  }
}

/// Drives [spaceClock]. Place once near the root of the app.
class SpaceClockHost extends StatefulWidget {
  const SpaceClockHost({super.key, required this.child});
  final Widget child;

  @override
  State<SpaceClockHost> createState() => _SpaceClockHostState();
}

class _SpaceClockHostState extends State<SpaceClockHost> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(spaceClock._tick)..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Light direction presets (screen space: x right, y up, z toward viewer).
abstract final class Lights {
  static const visor = (0.55, 0.55, 0.65);
  static const horizon = (0.45, 0.8, 0.35);
  static const card = (0.8, 0.35, 0.45);
  static const crescent = (0.9, 0.2, -0.35);
}

/// Paints one body as a sphere of [radius] centred at [center].
void paintBody(
  Canvas canvas,
  Size size,
  ui.FragmentShader shader,
  Body body, {
  required Offset center,
  required double radius,
  required double time,
  (double, double, double) light = Lights.horizon,
  double opacity = 1,
}) {
  if (radius <= 0.5 || opacity <= 0.001) return;
  final halo = body.isStar ? 2.6 : 1.25;
  final reach = radius * math.max(halo, body.hasRing ? body.ringOut + 0.05 : 0);
  final rect = Rect.fromCircle(center: center, radius: reach).intersect(Offset.zero & size);
  if (rect.isEmpty) return;

  var i = 0;
  void f(double v) => shader.setFloat(i++, v);
  void c(Color col) {
    f(col.r);
    f(col.g);
    f(col.b);
  }

  f(center.dx);
  f(center.dy);
  f(radius);
  f(time * body.spin + body.seed * 1.7);
  f(time);
  f(body.type);
  f(light.$1);
  f(light.$2);
  f(light.$3);
  c(body.colA);
  c(body.colB);
  c(body.atmo);
  f(body.atmoStr);
  f(body.ringIn);
  f(body.ringOut);
  f(body.ringTilt);
  f(body.tilt);
  f(body.seed);
  f(opacity.clamp(0.0, 1.0));

  canvas.drawRect(rect, Paint()..shader = shader);
}

/// A body rendered into its own box. Geometry is relative to the box so the
/// same widget works as a full disc, a horizon, or a Hero flying between them.
class PlanetView extends StatefulWidget {
  const PlanetView({
    super.key,
    required this.body,
    this.geometry = const SphereGeometry.disc(),
    this.light = Lights.visor,
    this.opacity = 1,
  });

  final Body body;
  final SphereGeometry geometry;
  final (double, double, double) light;
  final double opacity;

  @override
  State<PlanetView> createState() => _PlanetViewState();
}

class _PlanetViewState extends State<PlanetView> {
  final ui.FragmentShader _shader = planetProgram.fragmentShader();

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PlanetPainter(_shader, widget.body, widget.geometry, widget.light, widget.opacity),
    );
  }
}

/// Where a sphere sits inside a box.
///
/// [radius] is a fraction of the box width; [cx] a fraction of box width;
/// [cy] a fraction of box height for the sphere's *centre*, or when [fromTop]
/// is set, for the sphere's top edge (handy for horizons).
class SphereGeometry {
  const SphereGeometry({required this.cx, required this.cy, required this.radius, this.fromTop = false});
  const SphereGeometry.disc({this.radius = 0.5})
      : cx = 0.5,
        cy = 0.5,
        fromTop = false;
  const SphereGeometry.horizon({required double top, required this.radius})
      : cx = 0.5,
        cy = top,
        fromTop = true;

  final double cx;
  final double cy;
  final double radius;
  final bool fromTop;

  (Offset, double) resolve(Size size) {
    final r = radius * size.width;
    final y = fromTop ? cy * size.height + r : cy * size.height;
    return (Offset(cx * size.width, y), r);
  }

  @override
  bool operator ==(Object other) =>
      other is SphereGeometry &&
      other.cx == cx &&
      other.cy == cy &&
      other.radius == radius &&
      other.fromTop == fromTop;

  @override
  int get hashCode => Object.hash(cx, cy, radius, fromTop);

  static SphereGeometry lerpHorizon(SphereGeometry a, SphereGeometry b, double t) => SphereGeometry(
        cx: ui.lerpDouble(a.cx, b.cx, t)!,
        cy: ui.lerpDouble(a.cy, b.cy, t)!,
        radius: ui.lerpDouble(a.radius, b.radius, t)!,
        fromTop: true,
      );
}

class _PlanetPainter extends CustomPainter {
  _PlanetPainter(this.shader, this.body, this.geometry, this.light, this.opacity) : super(repaint: spaceClock);

  final ui.FragmentShader shader;
  final Body body;
  final SphereGeometry geometry;
  final (double, double, double) light;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final (center, radius) = geometry.resolve(size);
    paintBody(canvas, size, shader, body,
        center: center, radius: radius, time: spaceClock.value, light: light, opacity: opacity);
  }

  @override
  bool shouldRepaint(_PlanetPainter old) =>
      old.body != body || old.geometry != geometry || old.light != light || old.opacity != opacity;
}
