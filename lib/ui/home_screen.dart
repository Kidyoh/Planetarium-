import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bodies.dart';
import '../render/helmet.dart';
import '../render/planet.dart';
import '../render/space_fx.dart';
import 'arc_selector.dart';
import 'catalog.dart';
import 'common.dart';
import 'dive_route.dart';
import 'space_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _startIndex = 3; // Mars, as in the original concept.

  late final AnimationController _arc = AnimationController.unbounded(vsync: this, value: _startIndex.toDouble());
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..forward();
  final GlobalKey _visorKey = GlobalKey();

  Animation<double>? _dive;
  Rect? _diveVisor;
  int _lastIndex = _startIndex;
  double _dragTilt = 0;

  int get _index => _arc.value.round().clamp(0, planets.length - 1);

  @override
  void initState() {
    super.initState();
    _arc.addListener(() {
      final i = _index;
      if (i != _lastIndex) {
        _lastIndex = i;
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _arc.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    final target = i.clamp(0, planets.length - 1).toDouble();
    _arc.animateTo(target, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    final v = _arc.value - d.delta.dx / (width * 0.42);
    _arc.value = v.clamp(-0.35, planets.length - 0.65);
    setState(() => _dragTilt = (d.delta.dx / 40).clamp(-1.0, 1.0));
  }

  void _onDragEnd(DragEndDetails d, double width) {
    final fling = -d.velocity.pixelsPerSecond.dx / (width * 1.6);
    final target = (_arc.value + fling.clamp(-1.5, 1.5)).round();
    _goTo(target);
    setState(() => _dragTilt = 0);
  }

  Future<void> _openSpace() async {
    if (_dive != null || _intro.value < 0.9) return;
    final box = _visorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final visor = box.localToGlobal(Offset.zero) & box.size;
    final body = planets[_index];
    HapticFeedback.lightImpact();
    final route = DiveRoute(visor: visor, builder: (_) => SpaceScreen(body: body));
    Navigator.of(context).push(route);
    final anim = route.animation!;
    void onStatus(AnimationStatus s) {
      if (s == AnimationStatus.dismissed) {
        anim.removeStatusListener(onStatus);
        if (mounted) setState(() => _dive = null);
      }
    }

    anim.addStatusListener(onStatus);
    setState(() {
      _dive = anim;
      _diveVisor = visor;
    });
  }

  void _openCatalog({bool search = false}) {
    showCatalog(context, autofocus: search, onPlanet: (b) => _goTo(planets.indexOf(b)));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final content = _buildContent(w, h, mq.padding);
        final dive = _dive;
        if (dive == null || _diveVisor == null) return content;
        return AnimatedBuilder(
          animation: dive,
          builder: (context, child) {
            final t = Curves.easeInOutCubic.transform(dive.value);
            final zoom = math.pow(DiveRoute.coverScale(_diveVisor!, Size(w, h)), t).toDouble();
            final cx = _diveVisor!.center;
            return Opacity(
              opacity: (1 - Interval(0.75, 1).transform(dive.value)).clamp(0.0, 1.0),
              child: Transform(
                transform: Matrix4.identity()
                  ..translateByDouble(cx.dx, cx.dy, 0, 1)
                  ..scaleByDouble(zoom, zoom, 1, 1)
                  ..translateByDouble(-cx.dx, -cx.dy, 0, 1),
                child: child,
              ),
            );
          },
          child: content,
        );
      }),
    );
  }

  Widget _buildContent(double w, double h, EdgeInsets pad) {
    final s = math.min(w * 0.64, h * 0.36);
    final helmetTop = h * 0.255;
    final letterSize = s * 0.27;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => _onDragUpdate(d, w),
      onHorizontalDragEnd: (d) => _onDragEnd(d, w),
      onVerticalDragEnd: (d) {
        if (d.velocity.pixelsPerSecond.dy < -300) _openSpace();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_arc, _intro]),
        builder: (context, _) {
          final pos = _arc.value;
          final intro = _intro.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Giant vertical name.
              Positioned(
                top: pad.top + 64,
                left: 0,
                right: 0,
                child: VerticalName(pos: pos, size: letterSize, intro: intro),
              ),
              // Helmet with the planet in its visor.
              Positioned(
                top: helmetTop,
                left: (w - s) / 2,
                child: _helmet(s, h, pos, intro),
              ),
              // Fade the suit into the page.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.42,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                        stops: [0, 0.42],
                      ),
                    ),
                  ),
                ),
              ),
              // Planet selector.
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + 18,
                height: 150,
                child: Reveal(
                  animation: _intro,
                  start: 0.72,
                  end: 1,
                  dy: 30,
                  child: ArcSelector(
                    pos: pos,
                    onSelect: _goTo,
                    onPrev: () => _goTo(_index - 1),
                    onNext: () => _goTo(_index + 1),
                    onOpen: _openSpace,
                  ),
                ),
              ),
              // Top bar.
              Positioned(
                top: pad.top,
                left: 0,
                right: 0,
                child: Reveal(
                  animation: _intro,
                  start: 0.65,
                  end: 0.95,
                  dy: -12,
                  child: TopBar(
                    color: kInk,
                    onLeading: () => _openCatalog(search: true),
                    onMenu: _openCatalog,
                  ),
                ),
              ),
              // Hint.
              Positioned(
                left: 0,
                right: 0,
                top: helmetTop + s * HelmetGeo.aspect - 6,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: Interval(0.85, 1).transform(intro) * 0.9,
                    child: Center(child: Text('TAP THE VISOR', style: mont(8, w: 500, color: kMuted, spacing: 3))),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _helmet(double s, double h, double pos, double intro) {
    final rise = Curves.easeOutCubic.transform(Interval(0.2, 0.75).transform(intro));
    final planetIn = Curves.easeOut.transform(Interval(0.55, 0.9).transform(intro));
    return Opacity(
      opacity: rise,
      child: Transform.translate(
        offset: Offset(0, (1 - rise) * h * 0.45),
        child: AnimatedBuilder(
          animation: spaceClock,
          builder: (context, child) {
            final t = spaceClock.value;
            return Transform.translate(
              offset: Offset(0, math.sin(t * 1.1) * 4),
              child: Transform.rotate(
                angle: math.sin(t * 0.7) * 0.012 + _dragTilt * 0.04,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: _openSpace,
            child: Helmet(
              width: s,
              visorKey: _visorKey,
              visor: VisorScene(pos: pos, opacity: planetIn),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the visor reflects: deep space and the selected planet sliding in.
class VisorScene extends StatelessWidget {
  const VisorScene({super.key, required this.pos, this.opacity = 1});
  final double pos;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.5),
            radius: 1.1,
            colors: [Color(0xFF1C1C1F), Color(0xFF020203)],
          ),
        ),
        child: SizedBox.expand(),
      ),
      StarField(parallax: Offset(-pos * 40, 0), density: 0.35, meteors: false),
    ];
    for (var i = 0; i < planets.length; i++) {
      final d = i - pos;
      if (d.abs() > 1.2) continue;
      final b = planets[i];
      final focus = (1 - d.abs()).clamp(0.0, 1.0);
      children.add(PlanetView(
        body: b,
        light: Lights.visor,
        opacity: opacity * (0.35 + 0.65 * focus),
        geometry: SphereGeometry(
          cx: 0.5 + d * 1.15,
          cy: 0.86 + (1 - focus) * 0.12,
          radius: b.hasRing ? 0.3 : 0.4 + 0.02 * focus,
        ),
      ));
    }
    return Stack(fit: StackFit.expand, children: children);
  }
}

/// Planet name set vertically in huge, light letters that cascade on change.
class VerticalName extends StatelessWidget {
  const VerticalName({super.key, required this.pos, required this.size, required this.intro});
  final double pos;
  final double size;
  final double intro;

  @override
  Widget build(BuildContext context) {
    final p = pos.clamp(0.0, planets.length - 1.0);
    final a = p.floor();
    final b = math.min(a + 1, planets.length - 1);
    final f = p - a;
    final step = size * 1.12;
    final style = mont(size, w: 200, color: const Color(0xFFD5D5D5));

    Widget column(String name, double Function(int i) progress, {required bool incoming}) {
      final letters = name.toUpperCase().split('');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < letters.length; i++)
            SizedBox(
              height: step,
              child: Builder(builder: (context) {
                final k = Curves.easeInOutCubic.transform(progress(i).clamp(0.0, 1.0));
                final o = incoming ? k : 1 - k;
                final dy = incoming ? (1 - k) * step * 0.7 : -k * step * 0.7;
                return Opacity(
                  opacity: o,
                  child: Transform.translate(offset: Offset(0, dy), child: Center(child: Text(letters[i], style: style))),
                );
              }),
            ),
        ],
      );
    }

    // Letters stagger: the first letter leads, the rest follow.
    double stagger(int i) => f * 1.6 - i * 0.1;

    if (intro < 1) {
      return _ScrambleName(name: planets[a].name, size: size, step: step, style: style, intro: intro);
    }
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        if (f < 0.999) column(planets[a].name, stagger, incoming: false),
        if (f > 0.001 && b != a) column(planets[b].name, stagger, incoming: true),
      ],
    );
  }
}

/// Intro: letters spin like a slot machine, blurred, before locking in.
class _ScrambleName extends StatelessWidget {
  const _ScrambleName({required this.name, required this.size, required this.step, required this.style, required this.intro});
  final String name;
  final double size;
  final double step;
  final TextStyle style;
  final double intro;

  static const _glyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  Widget build(BuildContext context) {
    final letters = name.toUpperCase().split('');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letters.length; i++)
          SizedBox(
            height: step,
            child: Builder(builder: (context) {
              final lock = 0.22 + i * 0.07;
              final appear = Interval(0.0, 0.2 + i * 0.03).transform(intro);
              final locked = intro >= lock;
              final speed = locked ? 0.0 : (1 - intro / lock);
              final ch = locked ? letters[i] : _glyphs[((intro * 60 + i * 7) % _glyphs.length).floor()];
              final settle = locked ? Curves.elasticOut.transform(Interval(lock, lock + 0.15).transform(intro)) : 0.0;
              Widget glyph = Text(ch, style: style);
              if (speed > 0.02) {
                glyph = ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 6 * speed),
                  child: glyph,
                );
              }
              return Opacity(
                opacity: appear,
                child: Transform.translate(
                  offset: Offset(0, locked ? (1 - settle) * -step * 0.25 : 0),
                  child: Center(child: glyph),
                ),
              );
            }),
          ),
      ],
    );
  }
}
