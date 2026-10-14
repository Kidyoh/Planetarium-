import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/bodies.dart';
import '../render/planet.dart';
import 'common.dart';

typedef Placement = ({Body body, Offset center, double radius, (double, double, double) light});

/// Paints several shader bodies laid out by [layout] in one canvas.
class BodiesCanvas extends StatefulWidget {
  const BodiesCanvas({super.key, required this.layout, this.foreground});
  final List<Placement> Function(Size size) layout;
  final CustomPainter? foreground;

  @override
  State<BodiesCanvas> createState() => _BodiesCanvasState();
}

class _BodiesCanvasState extends State<BodiesCanvas> {
  final List<ui.FragmentShader> _shaders = [];

  ui.FragmentShader _shader(int i) {
    while (_shaders.length <= i) {
      _shaders.add(planetProgram.fragmentShader());
    }
    return _shaders[i];
  }

  @override
  void dispose() {
    for (final s in _shaders) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _BodiesPainter(widget.layout, _shader),
      foregroundPainter: widget.foreground,
    );
  }
}

class _BodiesPainter extends CustomPainter {
  _BodiesPainter(this.layout, this.shader) : super(repaint: spaceClock);
  final List<Placement> Function(Size) layout;
  final ui.FragmentShader Function(int) shader;

  @override
  void paint(Canvas canvas, Size size) {
    final items = layout(size);
    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      paintBody(canvas, size, shader(i), p.body,
          center: p.center, radius: p.radius, time: spaceClock.value, light: p.light);
    }
  }

  @override
  bool shouldRepaint(_BodiesPainter old) => true;
}

Body? _parentOf(Body b) {
  for (final p in planets) {
    if (p.name == b.parentName) return p;
  }
  return null;
}

void _label(Canvas canvas, String text, Offset at, {TextStyle? style, bool center = true}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style ?? mont(7, w: 600, color: kMuted, spacing: 1.8)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
}

/// Animated orbit map: the solar system for planets, or the parent planet
/// with its moon's orbit for moons.
class OrbitDiagram extends StatelessWidget {
  const OrbitDiagram({super.key, required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final parent = _parentOf(body);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: kSpace,
        child: parent != null ? _moonOrbit(parent) : _solarOrbit(),
      ),
    );
  }

  Widget _moonOrbit(Body parent) {
    double angle() => spaceClock.value * 0.35;
    return BodiesCanvas(
      layout: (size) {
        final c = size.center(Offset.zero);
        final orbit = size.width * 0.36;
        final a = angle();
        return [
          (body: parent, center: c, radius: size.width * 0.11, light: Lights.card),
          (
            body: body,
            center: c + Offset(math.cos(a), math.sin(a) * 0.42) * orbit,
            radius: size.width * 0.035,
            light: Lights.card
          ),
        ];
      },
      foreground: _MoonOrbitPainter(body, parent, angle),
    );
  }

  Widget _solarOrbit() {
    return BodiesCanvas(
      layout: (size) => [
        (body: sun, center: size.center(Offset.zero), radius: size.width * 0.035, light: Lights.visor),
      ],
      foreground: _SolarPainter(body),
    );
  }
}

class _MoonOrbitPainter extends CustomPainter {
  _MoonOrbitPainter(this.body, this.parent, this.angle) : super(repaint: spaceClock);
  final Body body;
  final Body parent;
  final double Function() angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final orbit = size.width * 0.36;
    final rect = Rect.fromCenter(center: c, width: orbit * 2, height: orbit * 2 * 0.42);
    final a = angle();
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white24;
    canvas.drawOval(rect, track);
    // Brighter trail behind the moon.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1, 0.42);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: orbit),
      a - 1.2,
      1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          startAngle: a - 1.2,
          endAngle: a,
          colors: [body.accent.withValues(alpha: 0), body.accent.withValues(alpha: 0.9)],
          transform: GradientRotation(0),
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: orbit)),
    );
    canvas.restore();
    final m = c + Offset(math.cos(a), math.sin(a) * 0.42) * orbit;
    _label(canvas, body.name.toUpperCase(), m + Offset(0, size.width * 0.05),
        style: mont(7, w: 600, color: Colors.white, spacing: 2));
    _label(canvas, parent.name.toUpperCase(), c + Offset(0, size.width * 0.14),
        style: mont(7, w: 600, color: Colors.white70, spacing: 2));
  }

  @override
  bool shouldRepaint(_MoonOrbitPainter old) => old.body != body;
}

class _SolarPainter extends CustomPainter {
  _SolarPainter(this.focus) : super(repaint: spaceClock);
  final Body focus;

  static double _ring(double au, double maxR) {
    const lo = 0.39, hi = 30.1;
    final k = (math.sqrt(au) - math.sqrt(lo)) / (math.sqrt(hi) - math.sqrt(lo));
    return maxR * (0.16 + 0.84 * k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width * 0.46;
    final t = spaceClock.value;
    for (var i = 0; i < planets.length; i++) {
      final p = planets[i];
      final r = _ring(p.orbitAu, maxR);
      final isFocus = p.id == focus.id;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isFocus ? 1.3 : 0.7
          ..color = isFocus ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.14),
      );
      final a = i * 1.7 + t * 0.9 / math.pow(p.orbitAu, 0.75);
      final pos = c + Offset(math.cos(a), math.sin(a)) * r;
      final dot = isFocus ? 5.0 : 2.6;
      if (isFocus) {
        canvas.drawCircle(pos, dot * 3, Paint()..color = p.accent.withValues(alpha: 0.25));
      }
      canvas.drawCircle(pos, dot, Paint()..color = p.accent);
      if (isFocus || focus.isStar) {
        _label(canvas, p.name.toUpperCase(), pos + Offset(0, dot + 5),
            style: mont(isFocus ? 7.5 : 5.5, w: 600, color: isFocus ? Colors.white : Colors.white54, spacing: 1.6));
      }
    }
  }

  @override
  bool shouldRepaint(_SolarPainter old) => old.focus != focus;
}

/// Cutaway: the real surface with a quarter wedge removed to show layers.
class StructureDiagram extends StatelessWidget {
  const StructureDiagram({super.key, required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    return BodiesCanvas(
      layout: (size) {
        final r = size.height * 0.46;
        return [(body: body, center: Offset(r + 4, size.height / 2), radius: r, light: Lights.card)];
      },
      foreground: _CutawayPainter(body),
    );
  }
}

class _CutawayPainter extends CustomPainter {
  _CutawayPainter(this.body);
  final Body body;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.46;
    final c = Offset(r + 4, size.height / 2);
    final wedge = Rect.fromCircle(center: c, radius: r);
    canvas.drawShadow(
      Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(wedge, -math.pi / 2, math.pi / 2, false)
        ..close(),
      Colors.black,
      3,
      false,
    );
    for (final l in body.layers) {
      final lr = r * l.radius;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: lr), -math.pi / 2, math.pi / 2, false)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.radial(c, lr, [
            Color.lerp(l.color, Colors.white, 0.25)!,
            l.color,
            Color.lerp(l.color, Colors.black, 0.25)!,
          ], [0, 0.7, 1]),
      );
    }
    // Leader lines and labels, outermost first.
    final n = body.layers.length;
    final textX = c.dx + r + 34;
    for (var i = 0; i < n; i++) {
      final l = body.layers[i];
      final prev = i + 1 < n ? body.layers[i + 1].radius : 0.0;
      final mid = (l.radius + prev) / 2;
      final a = -math.pi / 4 + 0.15 * (i - (n - 1) / 2);
      final anchor = c + Offset(math.cos(a), math.sin(a)) * r * mid;
      final ty = size.height * (0.12 + 0.76 * (n == 1 ? 0.5 : i / (n - 1)));
      final line = Paint()
        ..color = kInk.withValues(alpha: 0.5)
        ..strokeWidth = 0.8;
      canvas.drawCircle(anchor, 2, Paint()..color = Colors.white);
      canvas.drawCircle(anchor, 1.2, Paint()..color = kInk);
      final elbow = Offset(textX - 12, ty + 5);
      canvas.drawLine(anchor, Offset(anchor.dx + 8, elbow.dy), line);
      canvas.drawLine(Offset(anchor.dx + 8, elbow.dy), elbow, line);
      _label(canvas, l.name.toUpperCase(), Offset(textX - 6, ty), style: mont(7.5, w: 600, color: kInk, spacing: 1.6), center: false);
      final share = i == n - 1 ? l.radius : l.radius - prev;
      _label(canvas, '${(share * 100).round()}% of radius', Offset(textX - 6, ty + 12),
          style: mont(7, w: 400, color: kMuted), center: false);
    }
  }

  @override
  bool shouldRepaint(_CutawayPainter old) => old.body != body;
}

/// Two bodies side by side at true relative scale.
class SizeComparison extends StatelessWidget {
  const SizeComparison({super.key, required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final ref = body.id == 'earth' ? moon : planets[2];
    final bigIsBody = body.diameterKm >= ref.diameterKm;
    final big = bigIsBody ? body : ref;
    final small = bigIsBody ? ref : body;
    final ratio = big.diameterKm / small.diameterKm;

    (Offset, double, Offset, double) geo(Size size) {
      var bigR = size.height * 0.42;
      var smallR = bigR / ratio;
      var bigC = Offset(size.width * 0.36, size.height * 0.48);
      if (smallR < 3) {
        smallR = 3;
        bigR = smallR * ratio;
        if (bigR > size.height * 0.42) {
          bigC = Offset(size.width * 0.5 - bigR, size.height * 0.48);
        }
      }
      final smallC = Offset(math.max(bigC.dx + bigR + smallR + 26, size.width * 0.7), size.height * 0.48);
      return (bigC, bigR, smallC, smallR);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: kSpace,
        child: BodiesCanvas(
          layout: (size) {
            final (bc, br, sc, sr) = geo(size);
            return [
              (body: big, center: bc, radius: br, light: Lights.card),
              (body: small, center: sc, radius: sr, light: Lights.card),
            ];
          },
          foreground: _SizeLabels(big.name, small.name, geo),
        ),
      ),
    );
  }
}

class _SizeLabels extends CustomPainter {
  _SizeLabels(this.big, this.small, this.geo);
  final String big;
  final String small;
  final (Offset, double, Offset, double) Function(Size) geo;

  @override
  void paint(Canvas canvas, Size size) {
    final (bc, br, sc, sr) = geo(size);
    final style = mont(7, w: 600, color: Colors.white70, spacing: 2);
    final bx = bc.dx - br < 0 ? size.width * 0.18 : bc.dx;
    _label(canvas, big.toUpperCase(), Offset(bx, size.height - 18), style: style);
    _label(canvas, small.toUpperCase(), Offset(sc.dx, sc.dy + sr + 10), style: style);
  }

  @override
  bool shouldRepaint(_SizeLabels old) => old.big != big || old.small != small;
}
