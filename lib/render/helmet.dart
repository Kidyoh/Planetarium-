import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'planet.dart';

/// Proportions of the helmet artwork, in units of the helmet width.
abstract final class HelmetGeo {
  static const aspect = 1.32;
  static const shellCenter = Offset(0.5, 0.5);
  static const shellRadius = 0.45;
  static const visor = Rect.fromLTRB(0.165, 0.255, 0.835, 0.815);

  static Rect visorRect(double s) =>
      Rect.fromLTRB(visor.left * s, visor.top * s, visor.right * s, visor.bottom * s);
}

/// Astronaut helmet and shoulders, with an arbitrary widget seen through the
/// visor (normally the selected planet's reflection).
class Helmet extends StatelessWidget {
  const Helmet({super.key, required this.width, required this.visor, this.visorKey});

  final double width;
  final Widget visor;
  final Key? visorKey;

  @override
  Widget build(BuildContext context) {
    final s = width;
    final v = HelmetGeo.visorRect(s);
    return SizedBox(
      width: s,
      height: s * HelmetGeo.aspect,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _HelmetPainter())),
          Positioned.fromRect(
            rect: v,
            child: ClipOval(key: visorKey, child: visor),
          ),
          Positioned.fromRect(
            rect: v,
            child: IgnorePointer(child: CustomPaint(painter: _GlassPainter())),
          ),
        ],
      ),
    );
  }
}

class _HelmetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    _suit(canvas, s, p);

    // Contact shadow under the helmet.
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.92), width: s * 0.78, height: s * 0.14),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.035),
    );

    // Neck ring.
    final neck = Rect.fromCenter(center: p(0.5, 0.905), width: s * 0.64, height: s * 0.13);
    canvas.drawOval(
      neck,
      Paint()
        ..shader = ui.Gradient.linear(neck.topLeft, neck.bottomRight, const [
          Color(0xFFE9E9E9),
          Color(0xFF9C9C9C),
          Color(0xFFF2F2F2),
          Color(0xFF8A8A8A),
        ], [0, 0.35, 0.6, 1]),
    );

    // Ear pieces.
    for (final x in [0.035, 0.965]) {
      final ear = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(x, 0.53), width: s * 0.075, height: s * 0.2),
        Radius.circular(s * 0.035),
      );
      canvas.drawRRect(
        ear,
        Paint()
          ..shader = ui.Gradient.linear(ear.outerRect.topLeft, ear.outerRect.bottomRight, const [
            Color(0xFFF6F6F6),
            Color(0xFFA9A9A9),
          ]),
      );
    }

    // Shell.
    final c = p(HelmetGeo.shellCenter.dx, HelmetGeo.shellCenter.dy);
    final r = s * HelmetGeo.shellRadius;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(p(0.36, 0.26), s * 0.68, const [
          Color(0xFFFFFFFF),
          Color(0xFFF7F7F7),
          Color(0xFFDCDCDC),
          Color(0xFFA8A8A8),
        ], [0, 0.42, 0.78, 1]),
    );
    // Seam lines on the shell.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.004
      ..color = const Color(0x22000000);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.93), math.pi * 1.12, math.pi * 0.76, false, seam);
    canvas.drawLine(p(0.5, 0.055), p(0.5, 0.2), seam);

    // Headlamp.
    final lamp = Rect.fromCenter(center: p(0.27, 0.16), width: s * 0.11, height: s * 0.065);
    canvas.save();
    canvas.translate(lamp.center.dx, lamp.center.dy);
    canvas.rotate(-0.55);
    canvas.translate(-lamp.center.dx, -lamp.center.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lamp, Radius.circular(s * 0.02)),
      Paint()..color = const Color(0xFFD5D5D5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lamp.deflate(s * 0.012), Radius.circular(s * 0.012)),
      Paint()
        ..shader = ui.Gradient.linear(lamp.topLeft, lamp.bottomRight, const [Color(0xFF3A3A3A), Color(0xFF111111)]),
    );
    canvas.restore();

    // Visor rim: soft outer shadow then a brushed-metal ring.
    final v = HelmetGeo.visorRect(s);
    canvas.drawOval(
      v.inflate(s * 0.03),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
    );
    canvas.drawOval(
      v.inflate(s * 0.028),
      Paint()
        ..shader = ui.Gradient.sweep(v.center, const [
          Color(0xFFF5F5F5),
          Color(0xFF8E8E8E),
          Color(0xFFE6E6E6),
          Color(0xFF6E6E6E),
          Color(0xFFF5F5F5),
        ], [0, 0.3, 0.55, 0.8, 1]),
    );
    canvas.drawOval(v.inflate(s * 0.006), Paint()..color = const Color(0xFF1B1B1B));
  }

  void _suit(Canvas canvas, double s, Offset Function(double, double) p) {
    final h = s * HelmetGeo.aspect;
    final body = Path()
      ..moveTo(-0.32 * s, h + s * 1.5)
      ..cubicTo(-0.3 * s, 1.08 * s, -0.05 * s, 0.98 * s, 0.2 * s, 0.9 * s)
      ..lineTo(0.8 * s, 0.9 * s)
      ..cubicTo(1.05 * s, 0.98 * s, 1.3 * s, 1.08 * s, 1.32 * s, h + s * 1.5)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(p(0.42, 0.95), s * 0.95, const [
          Color(0xFFFFFFFF),
          Color(0xFFF1F1F1),
          Color(0xFFD6D6D6),
        ], [0, 0.55, 1]),
    );
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.006
      ..color = const Color(0x1F000000);
    final folds = [
      [p(0.08, 1.04), p(0.16, 1.12), p(0.12, 1.24)],
      [p(0.2, 1.0), p(0.3, 1.1), p(0.26, 1.28)],
      [p(0.8, 1.0), p(0.7, 1.1), p(0.74, 1.28)],
      [p(0.92, 1.04), p(0.84, 1.12), p(0.88, 1.24)],
    ];
    for (final f in folds) {
      canvas.drawPath(Path()..moveTo(f[0].dx, f[0].dy)..quadraticBezierTo(f[1].dx, f[1].dy, f[2].dx, f[2].dy), fold);
    }
    // Chest control patch.
    final patch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: p(0.5, 1.2), width: s * 0.22, height: s * 0.09),
      Radius.circular(s * 0.015),
    );
    canvas.drawRRect(patch, Paint()..color = const Color(0xFFE4E4E4));
    final leds = [const Color(0xFFF26B3A), const Color(0xFF3B82F6), const Color(0xFFBDBDBD)];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(p(0.44 + i * 0.06, 1.2), s * 0.009, Paint()..color = leds[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassPainter extends CustomPainter {
  _GlassPainter() : super(repaint: spaceClock);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipPath(Path()..addOval(rect));

    // Inner vignette so the reflection sinks into the curved glass.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(rect.center, size.width * 0.56, const [
          Color(0x00000000),
          Color(0x00000000),
          Color(0xCC000000),
        ], [0, 0.72, 1]),
    );

    // Curved highlight band, upper left.
    final band = Path()
      ..addOval(Rect.fromLTWH(size.width * 0.04, size.height * 0.03, size.width * 0.9, size.height * 0.92))
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromLTWH(size.width * 0.1, size.height * 0.09, size.width * 0.9, size.height * 0.92));
    canvas.drawPath(
      band,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.center, const [
          Color(0x55FFFFFF),
          Color(0x00FFFFFF),
        ]),
    );

    // Specular glint.
    final g = Offset(size.width * 0.78, size.height * 0.2);
    canvas.drawCircle(
      g,
      size.width * 0.06,
      Paint()
        ..shader = ui.Gradient.radial(g, size.width * 0.06, const [Color(0x88FFFFFF), Color(0x00FFFFFF)]),
    );

    // Slow sheen sweep across the glass every few seconds.
    final t = spaceClock.value;
    const period = 6.5;
    final k = (t % period) / 1.6;
    if (k < 1) {
      final x = ui.lerpDouble(-size.width * 0.6, size.width * 1.6, Curves.easeInOut.transform(k))!;
      canvas.save();
      canvas.translate(x, 0);
      canvas.skew(-0.5, 0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * 0.18, size.height),
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width * 0.18, 0), const [
            Color(0x00FFFFFF),
            Color(0x22FFFFFF),
            Color(0x00FFFFFF),
          ]),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
