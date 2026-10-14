import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'planet.dart';

class _Star {
  _Star(this.x, this.y, this.size, this.depth, this.phase, this.speed, this.warm);
  final double x, y, size, depth, phase, speed;
  final bool warm;
}

final List<_Star> _stars = () {
  final rnd = math.Random(42);
  return List.generate(260, (_) {
    final depth = rnd.nextDouble();
    return _Star(
      rnd.nextDouble(),
      rnd.nextDouble(),
      0.35 + math.pow(rnd.nextDouble(), 3) * 1.6,
      depth,
      rnd.nextDouble() * math.pi * 2,
      0.6 + rnd.nextDouble() * 2.2,
      rnd.nextDouble() < 0.2,
    );
  });
}();

/// Twinkling, parallaxing star field with the occasional shooting star.
class StarField extends StatelessWidget {
  const StarField({super.key, this.parallax = Offset.zero, this.density = 1, this.meteors = true});

  /// Shift in logical px applied to the nearest stars; far stars move less.
  final Offset parallax;
  final double density;
  final bool meteors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _StarPainter(parallax, density, meteors));
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.parallax, this.density, this.meteors) : super(repaint: spaceClock);
  final Offset parallax;
  final double density;
  final bool meteors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = spaceClock.value;
    final count = (_stars.length * density).round().clamp(0, _stars.length);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final s = _stars[i];
      final k = 0.15 + s.depth * 0.85;
      var x = (s.x * size.width + parallax.dx * k) % size.width;
      var y = (s.y * size.height + parallax.dy * k) % size.height;
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;
      final tw = 0.55 + 0.45 * math.sin(t * s.speed + s.phase);
      final a = (0.25 + 0.75 * s.depth) * tw;
      paint.color = (s.warm ? const Color(0xFFFFE2C0) : const Color(0xFFFFFFFF)).withValues(alpha: a.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), s.size, paint);
      if (s.size > 1.7) {
        paint.color = paint.color.withValues(alpha: a * 0.1);
        canvas.drawCircle(Offset(x, y), s.size * 2.4, paint);
      }
    }
    if (meteors) _meteor(canvas, size, t);
  }

  void _meteor(Canvas canvas, Size size, double t) {
    const period = 7.0;
    final n = (t / period).floor();
    final local = t - n * period;
    const dur = 0.9;
    if (local > dur) return;
    final rnd = math.Random(n * 7919);
    final p = local / dur;
    final start = Offset(size.width * (0.2 + rnd.nextDouble() * 0.9), size.height * rnd.nextDouble() * 0.45);
    final dir = Offset(-1, 0.45 + rnd.nextDouble() * 0.4);
    final len = size.width * 0.35;
    final head = start + dir * (len * 1.4 * p);
    final tail = head - dir * (len * 0.5 * math.sin(p * math.pi));
    final fade = math.sin(p * math.pi);
    final paint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(tail, head, [
        const Color(0x00FFFFFF),
        Color.fromRGBO(255, 255, 255, 0.9 * fade),
      ]);
    canvas.drawLine(tail, head, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.parallax != parallax || old.density != density;
}

/// Warm sun glare with an anamorphic streak and lens ghosts.
class SunFlare extends StatelessWidget {
  const SunFlare({super.key, this.anchor = const Alignment(1.05, -0.88), this.intensity = 1, this.color = const Color(0xFFFFA43A)});
  final Alignment anchor;
  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _FlarePainter(anchor, intensity, color)));
  }
}

class _FlarePainter extends CustomPainter {
  _FlarePainter(this.anchor, this.intensity, this.color) : super(repaint: spaceClock);
  final Alignment anchor;
  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.001) return;
    final t = spaceClock.value;
    final c = anchor.alongSize(size);
    final pulse = 1 + 0.05 * math.sin(t * 1.3) + 0.03 * math.sin(t * 3.7);
    final k = intensity * pulse;
    final add = Paint()..blendMode = BlendMode.plus;

    final glowR = size.width * 0.9;
    add.shader = ui.Gradient.radial(c, glowR, [
      color.withValues(alpha: 0.55 * k),
      color.withValues(alpha: 0.18 * k),
      color.withValues(alpha: 0),
    ], [0, 0.25, 1]);
    canvas.drawCircle(c, glowR, add);

    final coreR = size.width * 0.12;
    add.shader = ui.Gradient.radial(c, coreR, [
      Color.fromRGBO(255, 250, 235, 0.95 * intensity),
      const Color(0xFFFFD08A).withValues(alpha: 0.6 * intensity),
      const Color(0x00FFB050),
    ], [0, 0.3, 1]);
    canvas.drawCircle(c, coreR, add);

    // Anamorphic streak.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.08);
    canvas.scale(1, 0.018);
    final streakR = size.width * 1.1;
    add.shader = ui.Gradient.radial(Offset.zero, streakR, [
      const Color(0xFFFFE0B0).withValues(alpha: 0.75 * k),
      color.withValues(alpha: 0.25 * k),
      color.withValues(alpha: 0),
    ], [0, 0.35, 1]);
    canvas.drawCircle(Offset.zero, streakR, add);
    canvas.restore();

    // Ghosts along the axis through the screen centre.
    final centre = size.center(Offset.zero);
    final axis = centre - c;
    const ghosts = [(0.55, 0.05, 0.05), (0.85, 0.022, 0.09), (1.3, 0.09, 0.03), (1.6, 0.03, 0.06)];
    for (final (pos, r, a) in ghosts) {
      final g = c + axis * pos;
      final gr = size.width * r;
      add.shader = ui.Gradient.radial(g, gr, [
        color.withValues(alpha: a * intensity),
        color.withValues(alpha: a * 0.4 * intensity),
        color.withValues(alpha: 0),
      ], [0, 0.7, 1]);
      canvas.drawCircle(g, gr, add);
    }
  }

  @override
  bool shouldRepaint(_FlarePainter old) => old.anchor != anchor || old.intensity != intensity || old.color != color;
}

/// A small lunar lander. [progress] 0→1 is the descent; after touchdown the
/// engine cuts and a dust ring spreads out.
class LanderPainter extends CustomPainter {
  LanderPainter({required this.from, required this.to, required this.progress, this.scale = 1})
      : super(repaint: spaceClock);
  final Offset from;
  final Offset to;
  final double progress;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final t = spaceClock.value;
    final descent = Curves.easeOutCubic.transform((progress / 0.8).clamp(0.0, 1.0));
    final landed = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    final sway = math.sin(descent * math.pi * 2) * 10 * (1 - descent);
    final pos = Offset.lerp(from, to, descent)! + Offset(sway, 0);

    // Trajectory dots.
    final dot = Paint()..color = const Color(0x55FFFFFF);
    for (var i = 1; i <= 14; i++) {
      final f = i / 15 * descent;
      final p = Offset.lerp(from, to, f)! + Offset(math.sin(f * math.pi * 2) * 10 * (1 - f), 0);
      canvas.drawCircle(p, 0.9, dot);
    }

    // Dust ring on touchdown.
    if (landed > 0) {
      final dust = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.fromRGBO(220, 215, 205, 0.6 * (1 - landed));
      canvas.save();
      canvas.translate(to.dx, to.dy);
      canvas.scale(1, 0.25);
      canvas.drawCircle(Offset.zero, 6 + 40 * landed, dust);
      canvas.restore();
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    // Engine plume while descending.
    if (landed == 0) {
      final flick = 0.8 + 0.2 * math.sin(t * 40) + 0.1 * math.sin(t * 23);
      final len = 16.0 * flick * (0.6 + 0.4 * (1 - descent));
      final plume = Path()
        ..moveTo(-3, 2)
        ..quadraticBezierTo(0, 2 + len * 1.1, 3, 2)
        ..close();
      canvas.drawPath(
        plume,
        Paint()
          ..shader = ui.Gradient.linear(const Offset(0, 2), Offset(0, 2 + len), const [
            Color(0xFFFFFFFF),
            Color(0xFFFFC56B),
            Color(0x00FF7A1A),
          ], [0, 0.35, 1])
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        const Offset(0, 4),
        10,
        Paint()
          ..shader = ui.Gradient.radial(const Offset(0, 4), 10, const [Color(0x88FFB347), Color(0x00FFB347)])
          ..blendMode = BlendMode.plus,
      );
    }

    final legs = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-3, -1), const Offset(-7, 4), legs);
    canvas.drawLine(const Offset(3, -1), const Offset(7, 4), legs);
    canvas.drawLine(const Offset(-8.5, 4), const Offset(-5.5, 4), legs);
    canvas.drawLine(const Offset(5.5, 4), const Offset(8.5, 4), legs);
    // Descent stage, gold foil.
    canvas.drawRect(
      const Rect.fromLTRB(-4.5, -3, 4.5, 1.5),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(-4.5, 0), const Offset(4.5, 0), const [
          Color(0xFFFFE08A),
          Color(0xFFC8962E),
          Color(0xFF8A6418),
        ]),
    );
    // Ascent stage.
    final cab = Path()
      ..moveTo(-3.5, -3)
      ..lineTo(-3, -7)
      ..lineTo(1, -8.5)
      ..lineTo(3.5, -6.5)
      ..lineTo(3.5, -3)
      ..close();
    canvas.drawPath(
      cab,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(-3, -8), const Offset(3, -3), const [
          Color(0xFFF5F5F5),
          Color(0xFF9E9E9E),
        ]),
    );
    canvas.drawCircle(const Offset(-0.8, -5.6), 0.9, Paint()..color = const Color(0xFF263238));
    // Blinking beacon.
    if ((t * 1.5) % 1 < 0.25) {
      canvas.drawCircle(const Offset(1, -9.3), 0.8, Paint()..color = const Color(0xFFFF5252));
      canvas.drawCircle(const Offset(1, -9.3), 3, Paint()..color = const Color(0x44FF5252));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LanderPainter old) =>
      old.from != from || old.to != to || old.progress != progress || old.scale != scale;
}

/// A tiny satellite circling above a horizon, blinking as it goes.
class SatellitePainter extends CustomPainter {
  SatellitePainter({required this.center, required this.radius, this.opacity = 1}) : super(repaint: spaceClock);
  final Offset center;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final t = spaceClock.value;
    final a = -math.pi / 2 + math.sin(t * 0.18) * 0.55;
    final p = center + Offset(math.cos(a), math.sin(a)) * radius;
    canvas.drawCircle(p, 1.6, Paint()..color = Color.fromRGBO(255, 255, 255, 0.9 * opacity));
    if ((t * 1.2) % 1 < 0.2) {
      canvas.drawCircle(p, 4, Paint()..color = Color.fromRGBO(255, 255, 255, 0.25 * opacity));
    }
    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Color.fromRGBO(255, 255, 255, 0.12 * opacity);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), a - 0.25, 0.25, false, trail);
  }

  @override
  bool shouldRepaint(SatellitePainter old) => old.center != center || old.radius != radius || old.opacity != opacity;
}
