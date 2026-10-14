import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bodies.dart';
import '../render/planet.dart';
import '../render/space_fx.dart';
import 'catalog.dart';
import 'common.dart';
import 'detail_screen.dart';

/// Where a focused body sits in space view; also the Hero start geometry.
const kHorizonTop = 0.6;
const kHorizonRadius = 1.05;
const kHorizon = SphereGeometry.horizon(top: kHorizonTop, radius: kHorizonRadius);

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key, required this.body});
  final Body body;

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  late final AnimationController _lander =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
  int _page = 0;

  Body get _main => widget.body;
  Body get _comp => widget.body.companion!;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      final p = (_pages.page ?? 0).round();
      if (p != _page) {
        _page = p;
        HapticFeedback.selectionClick();
        if (p == 1 && !_comp.isStar) {
          _lander.forward(from: 0);
        } else {
          _lander.value = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _lander.dispose();
    super.dispose();
  }

  void _openDetail(Body b) {
    Navigator.of(context).push(detailRoute(b));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: kSpace,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return AnimatedBuilder(
          animation: Listenable.merge([_pages, _lander]),
          builder: (context, _) {
            final page = _pages.hasClients && _pages.position.haveDimensions ? (_pages.page ?? 0) : 0.0;
            final e = Curves.easeInOut.transform(page.clamp(0.0, 1.0));
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.9, -0.9),
                        radius: 1.4,
                        colors: [Color(0xFF1A130C), kSpace],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: StarField(parallax: Offset(0, -page * 120))),
                if (!_comp.isStar)
                  Positioned.fill(child: SunFlare(anchor: Alignment(1.05, -0.88 - e * 0.1), intensity: 1 - e * 0.25)),
                // Main body sinks away as we scroll.
                Positioned.fill(
                  child: Hero(
                    tag: 'body-${_main.id}',
                    flightShuttleBuilder: _shuttle(_main),
                    child: PlanetView(
                      body: _main,
                      light: Lights.horizon,
                      geometry: SphereGeometry.horizon(top: ui.lerpDouble(kHorizonTop, 1.3, e)!, radius: kHorizonRadius),
                    ),
                  ),
                ),
                // Companion grows into the new horizon.
                Positioned.fill(
                  child: Hero(
                    tag: 'body-${_comp.id}',
                    flightShuttleBuilder: _shuttle(_comp),
                    child: PlanetView(
                      body: _comp,
                      light: _comp.isStar ? Lights.visor : Lights.horizon,
                      geometry: _companionGeometry(e, w, h),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: SatellitePainter(
                        center: Offset(w / 2, h * kHorizonTop + w * kHorizonRadius + e * h * 0.7),
                        radius: w * kHorizonRadius + 26,
                        opacity: 1 - e,
                      ),
                    ),
                  ),
                ),
                if (!_comp.isStar)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: LanderPainter(
                          from: Offset(w * 0.62, h * 0.12),
                          to: Offset(w * 0.5, h * kHorizonTop - 6),
                          progress: _lander.value * (e > 0.98 ? 1 : 0),
                        ),
                      ),
                    ),
                  ),
                // Scroll surface.
                Positioned.fill(
                  child: PageView(
                    controller: _pages,
                    scrollDirection: Axis.vertical,
                    children: const [SizedBox.expand(), SizedBox.expand()],
                  ),
                ),
                ..._labels(w, h, page),
                Positioned(
                  top: pad.top,
                  left: 0,
                  right: 0,
                  child: TopBar(
                    color: Colors.white,
                    leading: const BackGlyph(color: Colors.white),
                    onLeading: () => Navigator.of(context).maybePop(),
                    onMenu: () => showCatalog(context, onBody: _openDetail),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: h * 0.42,
                  child: _PageDots(page: page),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 10,
                  child: Center(child: _ScrollHint(up: page > 0.5)),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  SphereGeometry _companionGeometry(double e, double w, double h) {
    final small = _comp.isStar ? 0.16 : 0.13;
    final r = ui.lerpDouble(small, kHorizonRadius, e)!;
    final startCy = 0.4;
    final endCy = kHorizonTop + kHorizonRadius * w / h;
    return SphereGeometry(cx: 0.5, cy: ui.lerpDouble(startCy, endCy, e)!, radius: r);
  }

  HeroFlightShuttleBuilder _shuttle(Body b) {
    return (context, animation, direction, from, to) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(animation.value);
          return PlanetView(
            body: b,
            light: Lights.horizon,
            geometry: SphereGeometry.lerpHorizon(kHorizon, kDetailHorizon, t),
          );
        },
      );
    };
  }

  List<Widget> _labels(double w, double h, double page) {
    final out = <Widget>[];
    for (var i = 0; i < 2; i++) {
      final b = i == 0 ? _main : _comp;
      final d = page - i; // 0 when this page is focused
      final o = (1 - d.abs() * 2.2).clamp(0.0, 1.0);
      if (o <= 0) continue;
      out.add(Positioned(
        left: 0,
        right: 0,
        top: h * kHorizonTop + 58 - d * h * 0.35,
        child: Opacity(
          opacity: o,
          child: _BodyCaption(body: b, onMore: () => _openDetail(b)),
        ),
      ));
    }
    // Small label above the companion while it is still in the distance.
    final far = (1 - page * 3).clamp(0.0, 1.0);
    if (far > 0) {
      final g = _companionGeometry(0, w, h);
      final top = g.cy * h - g.radius * w - 34;
      out.add(Positioned(
        left: 0,
        right: 0,
        top: top,
        child: IgnorePointer(
          child: Opacity(
            opacity: far * 0.8,
            child: Center(
              child: Text(_comp.name.toUpperCase(), style: mont(8, w: 500, color: Colors.white70, spacing: 4)),
            ),
          ),
        ),
      ));
    }
    return out;
  }
}

class _BodyCaption extends StatelessWidget {
  const _BodyCaption({required this.body, required this.onMore});
  final Body body;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Color(0xCC000000), blurRadius: 14), Shadow(color: Color(0x66000000), blurRadius: 4)];
    return Column(
      children: [
        Text(body.name.toUpperCase(), style: mont(11, w: 600, color: Colors.white, spacing: 6).copyWith(shadows: shadow)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            body.short,
            textAlign: TextAlign.center,
            style: mont(9.5, w: 400, color: Colors.white.withValues(alpha: 0.78), height: 1.7).copyWith(shadows: shadow),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onMore,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Text('Read more', style: mont(9.5, w: 600, color: Colors.white).copyWith(shadows: shadow)),
                const SizedBox(height: 3),
                Container(width: 22, height: 1, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.page});
  final double page;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(
            width: 3,
            height: 3 + 12 * (1 - (page - i).abs()).clamp(0.0, 1.0),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({required this.up});
  final bool up;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 10,
        height: 40,
        child: CustomPaint(painter: _HintPainter(up)),
      ),
    );
  }
}

class _HintPainter extends CustomPainter {
  _HintPainter(this.up) : super(repaint: spaceClock);
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.white24);
    final k = (spaceClock.value * 0.7) % 1;
    final y = up ? size.height * (1 - k) : size.height * k;
    final a = math.sin(k * math.pi);
    canvas.drawCircle(Offset(x, y), 1.8, Paint()..color = Colors.white.withValues(alpha: a));
  }

  @override
  bool shouldRepaint(_HintPainter old) => old.up != up;
}
