import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/bodies.dart';
import '../render/planet.dart';
import 'common.dart';

/// Planets threaded on a semicircular track. The selected planet sits at the
/// apex; dragging or tapping spins the whole track.
class ArcSelector extends StatelessWidget {
  const ArcSelector({
    super.key,
    required this.pos,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onOpen,
  });

  final double pos;
  final ValueChanged<int> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onOpen;

  static const step = 0.52; // radians between neighbours

  static (Offset, double) geometry(Size size) {
    final r = math.min(size.width * 0.42, 190.0);
    return (Offset(size.width / 2, 34 + r), r);
  }

  @override
  Widget build(BuildContext context) {
    final index = pos.round().clamp(0, planets.length - 1);
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final (center, r) = geometry(size);
      final apex = center - Offset(0, r);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) {
          var best = -1;
          var bestDist = 30.0;
          for (var i = 0; i < planets.length; i++) {
            final a = -math.pi / 2 + (i - pos) * step;
            final p = center + Offset(math.cos(a), math.sin(a)) * r;
            final dist = (p - d.localPosition).distance;
            if (dist < bestDist) {
              bestDist = dist;
              best = i;
            }
          }
          if (best == index) {
            onOpen();
          } else if (best >= 0) {
            onSelect(best);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _ArcPainter(pos))),
            Positioned(
              left: apex.dx - r * 0.62 - 20,
              top: apex.dy - 20,
              child: _Arrow(left: true, onTap: onPrev, enabled: pos > 0.5),
            ),
            Positioned(
              left: apex.dx + r * 0.62 - 20,
              top: apex.dy - 20,
              child: _Arrow(left: false, onTap: onNext, enabled: pos < planets.length - 1.5),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: apex.dy + 30,
              child: _NameLabel(pos: pos),
            ),
          ],
        ),
      );
    });
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.left, required this.onTap, required this.enabled});
  final bool left;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: enabled ? 1 : 0.25,
            child: Chevron(left: left, color: const Color(0xFF6F6F6F)),
          ),
        ),
      ),
    );
  }
}

class _NameLabel extends StatelessWidget {
  const _NameLabel({required this.pos});
  final double pos;

  @override
  Widget build(BuildContext context) {
    final p = pos.clamp(0.0, planets.length - 1.0);
    final i = p.round();
    final d = p - i; // -0.5 .. 0.5
    final k = 1 - (d.abs() * 2).clamp(0.0, 1.0);
    final b = planets[i];
    return IgnorePointer(
      child: Column(
        children: [
          Opacity(
            opacity: k,
            child: Transform.translate(
              offset: Offset(-d * 40, 0),
              child: Text(b.name.toUpperCase(), style: mont(10, w: 600, color: kInk, spacing: 4.5)),
            ),
          ),
          const SizedBox(height: 7),
          Container(width: 18 + 10 * k, height: 1.2, color: kInk.withValues(alpha: 0.6 + 0.4 * k)),
          const SizedBox(height: 7),
          Opacity(
            opacity: k * 0.8,
            child: Text(b.kind.toUpperCase(), style: mont(7, w: 500, color: kMuted, spacing: 2.5)),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.pos) : super(repaint: spaceClock);
  final double pos;

  @override
  void paint(Canvas canvas, Size size) {
    final (center, r) = ArcSelector.geometry(size);
    final t = spaceClock.value;

    // Track: hairline semicircle, fading at the ends.
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: math.pi,
          endAngle: math.pi * 2,
          colors: const [Color(0x00CCCCCC), Color(0xFFD0D0D0), Color(0xFFD0D0D0), Color(0x00CCCCCC)],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(rect),
    );

    // Minor ticks between planets.
    final tick = Paint()..color = const Color(0xFFC9C9C9);
    for (var i = -1; i < planets.length; i++) {
      for (var j = 1; j < 4; j++) {
        final a = -math.pi / 2 + (i + j / 4 - pos) * ArcSelector.step;
        if (a < -math.pi + 0.15 || a > -0.15) continue;
        canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * r, 0.7, tick);
      }
    }

    // Apex marker.
    final apex = center - Offset(0, r);
    canvas.drawCircle(apex - const Offset(0, 16), 1.2, Paint()..color = const Color(0xFF9E9E9E));

    for (var i = 0; i < planets.length; i++) {
      final d = i - pos;
      final a = -math.pi / 2 + d * ArcSelector.step;
      if (a < -math.pi - 0.05 || a > 0.05) continue;
      final edge = math.min(a + math.pi, -a).clamp(0.0, 0.5) / 0.5;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      final focus = (1 - d.abs()).clamp(0.0, 1.0);
      final b = planets[i];
      final radius = 3.2 + 4.8 * Curves.easeOut.transform(focus);
      final alpha = edge;
      if (focus > 0.01) {
        final pulse = 1 + 0.12 * math.sin(t * 2.4);
        canvas.drawCircle(
          p,
          radius * 2.6 * pulse,
          Paint()
            ..shader = RadialGradient(colors: [
              b.accent.withValues(alpha: 0.35 * focus),
              b.accent.withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: p, radius: radius * 2.6 * pulse)),
        );
      }
      canvas.drawCircle(p, radius, Paint()..color = b.accent.withValues(alpha: alpha));
      if (b.hasRing && focus > 0.3) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(-0.35);
        canvas.scale(1, 0.32);
        canvas.drawCircle(
          Offset.zero,
          radius * 1.8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = b.accent.withValues(alpha: alpha * focus * 0.8),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.pos != pos;
}
