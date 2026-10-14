import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../render/planet.dart';

const kInk = Color(0xFF111111);
const kMuted = Color(0xFF8E8E8E);
const kHairline = Color(0xFFE3E3E3);
const kSpace = Color(0xFF050506);

/// Montserrat (variable font) at an exact weight.
TextStyle mont(double size, {double w = 400, Color color = kInk, double spacing = 0, double? height}) {
  return TextStyle(
    fontFamily: 'Montserrat',
    fontSize: size,
    fontWeight: FontWeight.values[((w / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', w)],
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

/// Wide-tracked capitals used for names and labels.
String spaced(String s) => s.toUpperCase();

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.color,
    this.leading,
    this.onLeading,
    this.onMenu,
    this.title,
  });

  final Color color;
  final Widget? leading;
  final VoidCallback? onLeading;
  final VoidCallback? onMenu;

  /// Replaces the wordmark when set.
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _Tap(onTap: onLeading, child: leading ?? SearchGlyph(color: color)),
          Expanded(child: Center(child: title ?? Wordmark(color: color))),
          _Tap(onTap: onMenu, child: GridGlyph(color: color)),
        ],
      ),
    );
  }
}

class _Tap extends StatelessWidget {
  const _Tap({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 56, height: 56, child: Center(child: child)),
    );
  }
}

/// "XORE" logotype; the O is a ring with a tiny orbiting moon.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, required this.color, this.size = 15});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = mont(size, w: 500, color: color, spacing: size * 0.32);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('X', style: style),
        SizedBox(
          width: size * 1.05,
          height: size * 1.05,
          child: CustomPaint(painter: _OrbitO(color)),
        ),
        SizedBox(width: size * 0.32),
        Text('RE', style: style.copyWith(letterSpacing: size * 0.32)),
      ],
    );
  }
}

class _OrbitO extends CustomPainter {
  _OrbitO(this.color) : super(repaint: spaceClock);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.4;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.1
        ..color = color,
    );
    final a = spaceClock.value * 1.4;
    final m = c + Offset(math.cos(a), math.sin(a) * 0.45) * r * 1.35;
    canvas.drawCircle(m, size.width * 0.09, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OrbitO old) => old.color != color;
}

class SearchGlyph extends StatelessWidget {
  const SearchGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(14, 14), painter: _SearchPainter(color));
}

class _SearchPainter extends CustomPainter {
  _SearchPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.42), size.width * 0.34, p);
    canvas.drawLine(Offset(size.width * 0.68, size.height * 0.68), Offset(size.width * 0.95, size.height * 0.95), p);
  }

  @override
  bool shouldRepaint(_SearchPainter old) => old.color != color;
}

class GridGlyph extends StatelessWidget {
  const GridGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(width: 3, height: 3, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    return SizedBox(
      width: 12,
      height: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
        ],
      ),
    );
  }
}

class BackGlyph extends StatelessWidget {
  const BackGlyph({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(16, 12), painter: _ArrowPainter(color, left: true));
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color, {required this.left});
  final Color color;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final h = size.height / 2;
    if (left) {
      canvas.drawLine(Offset(size.width, h), Offset(0, h), p);
      canvas.drawPath(Path()..moveTo(h, 0)..lineTo(0, h)..lineTo(h, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

class Chevron extends StatelessWidget {
  const Chevron({super.key, required this.left, this.color = kMuted, this.size = 9});
  final bool left;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 0.6, size), painter: _ChevronPainter(left, color));
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.left, this.color);
  final bool left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final path = left
        ? (Path()..moveTo(size.width, 0)..lineTo(0, size.height / 2)..lineTo(size.width, size.height))
        : (Path()..moveTo(0, 0)..lineTo(size.width, size.height / 2)..lineTo(0, size.height));
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.left != left || old.color != color;
}

/// Fades and lifts its child in after [delay] once [animation] runs.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.animation, required this.child, this.start = 0, this.end = 1, this.dy = 18});
  final Animation<double> animation;
  final Widget child;
  final double start;
  final double end;
  final double dy;

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: animation, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(offset: Offset(0, dy * (1 - a.value)), child: child),
      ),
      child: child,
    );
  }
}
