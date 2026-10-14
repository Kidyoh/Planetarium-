import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bodies.dart';
import '../render/planet.dart';
import '../render/space_fx.dart';
import 'catalog.dart';
import 'common.dart';
import 'diagrams.dart';

const kDetailHorizon = SphereGeometry.horizon(top: 0.56, radius: 1.25);
const _headerBody = 150.0;

Route<void> detailRoute(Body body) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, _, _) => DetailScreen(body: body),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.45, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.body});
  final Body body;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final pad = MediaQuery.of(context).padding;
    final route = ModalRoute.of(context)!.animation!;
    final b = widget.body;
    final headerH = pad.top + _headerBody;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: headerH,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: kSpace)),
                const Positioned.fill(child: StarField(density: 0.5, meteors: false)),
                Positioned.fill(
                  child: Hero(
                    tag: 'body-${b.id}',
                    child: PlanetView(body: b, light: Lights.horizon, geometry: kDetailHorizon),
                  ),
                ),
                Positioned(
                  top: pad.top,
                  left: 0,
                  right: 0,
                  child: TopBar(
                    color: Colors.white,
                    leading: Text('BACK', style: mont(7.5, w: 600, color: Colors.white, spacing: 1.5)),
                    onLeading: () => Navigator.of(context).maybePop(),
                    onMenu: () => showCatalog(context, onBody: (x) {
                      Navigator.of(context).pushReplacement(detailRoute(x));
                    }),
                    title: Text(b.name.toUpperCase(), style: mont(12, w: 600, color: Colors.white, spacing: 6)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: route,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(const Interval(0.25, 1).transform(route.value));
                return Transform.translate(offset: Offset(0, (1 - t) * 120), child: Opacity(opacity: t, child: child));
              },
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F7F7),
                      border: Border(bottom: BorderSide(color: kHairline)),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                      dividerColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: kInk, width: 1.4),
                        insets: EdgeInsets.only(right: 18),
                      ),
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: kInk,
                      unselectedLabelColor: const Color(0xFFAAAAAA),
                      labelStyle: mont(8.5, w: 600, spacing: 2.5),
                      unselectedLabelStyle: mont(8.5, w: 500, spacing: 2.5),
                      tabs: const [
                        Tab(text: 'DISCOVER', height: 46),
                        Tab(text: 'FACTS', height: 46),
                        Tab(text: 'HISTORY', height: 46),
                        Tab(text: 'DIAGRAM', height: 46),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _DiscoverTab(body: b, intro: route),
                        _FactsTab(body: b),
                        _HistoryTab(body: b),
                        _DiagramTab(body: b),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _title(Body b) => (b.id == 'moon' || b.id == 'sun') ? 'The ${b.name}' : b.name;

/// Plays its stagger once, when first built.
class _Staggered extends StatefulWidget {
  const _Staggered({required this.children, this.delay = Duration.zero});
  final List<Widget> children;
  final Duration delay;

  @override
  State<_Staggered> createState() => _StaggeredState();
}

class _StaggeredState extends State<_Staggered> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500 + widget.children.length * 90),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++)
          Reveal(
            animation: _c,
            start: (i / (n + 2)).clamp(0.0, 0.9),
            end: ((i + 3) / (n + 2)).clamp(0.1, 1.0),
            dy: 22,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({required this.body, required this.intro});
  final Body body;
  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    final b = body;
    final para = mont(11, w: 400, color: const Color(0xFF6B6B6B), height: 1.85);
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 26, 0, MediaQuery.of(context).padding.bottom + 40),
      children: [
        _Staggered(
          delay: const Duration(milliseconds: 380),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(_title(b), style: mont(24, w: 600, spacing: -0.3)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
              child: Text(
                b.parentName != null ? '${b.kind.toUpperCase()}  ·  ${b.parentName!.toUpperCase()}' : b.kind.toUpperCase(),
                style: mont(7.5, w: 600, color: kMuted, spacing: 2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
              child: Text(b.discover, style: para),
            ),
            SizedBox(height: 168, child: _Gallery(body: b)),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 10),
              child: Text(b.sectionTitle, style: mont(14, w: 600)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(b.section, style: para),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: _StatGrid(stats: b.stats.take(3).toList()),
            ),
          ],
        ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final b = body;
    final views = [
      ('Horizon', const SphereGeometry.horizon(top: 0.5, radius: 0.95), Lights.horizon),
      ('Full disc', const SphereGeometry(cx: 0.5, cy: 0.5, radius: 0.2), Lights.card),
      ('Terminator', const SphereGeometry(cx: 0.42, cy: 0.62, radius: 0.42), Lights.crescent),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      physics: const BouncingScrollPhysics(),
      itemCount: views.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final (label, geo, light) = views[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 230,
                height: 136,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: kSpace),
                    StarField(density: 0.3, meteors: false, parallax: Offset(i * 97.0, i * 53.0)),
                    PlanetView(body: b, geometry: geo, light: b.isStar ? Lights.visor : light),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(label.toUpperCase(), style: mont(7, w: 600, color: kMuted, spacing: 2.2)),
          ],
        );
      },
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<Stat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 10.0;
      final cell = (c.maxWidth - gap * 2) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in stats)
            Container(
              width: cell,
              padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _CountUp(value: s.value, style: mont(17, w: 300, spacing: -0.2)),
                  ),
                  const SizedBox(height: 2),
                  Text(s.unit.isEmpty ? ' ' : s.unit, style: mont(8, w: 500, color: kMuted)),
                  const SizedBox(height: 8),
                  Text(s.label.toUpperCase(), style: mont(6.5, w: 600, color: kMuted, spacing: 1.6)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// Counts the leading number in [value] up from zero, keeping its format.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final m = RegExp(r'^(-?)([\d,]+(?:\.\d+)?)(.*)$').firstMatch(value);
    if (m == null) return Text(value, style: style);
    final sign = m.group(1)!;
    final digits = m.group(2)!;
    final tail = m.group(3)!;
    final target = double.parse(digits.replaceAll(',', ''));
    final decimals = digits.contains('.') ? digits.split('.').last.length : 0;
    final grouped = digits.contains(',');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutExpo,
      builder: (context, v, _) {
        var s = v.toStringAsFixed(decimals);
        if (grouped) {
          final parts = s.split('.');
          parts[0] = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
          s = parts.join('.');
        }
        return Text('$sign$s$tail', style: style);
      },
    );
  }
}

class _FactsTab extends StatelessWidget {
  const _FactsTab({required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final b = body;
    return ListView(
      padding: EdgeInsets.fromLTRB(26, 26, 26, MediaQuery.of(context).padding.bottom + 40),
      children: [
        _Staggered(children: [
          Text('By the numbers', style: mont(18, w: 600)),
          const SizedBox(height: 18),
          _StatGrid(stats: b.stats),
          const SizedBox(height: 30),
          Text('Size', style: mont(14, w: 600)),
          const SizedBox(height: 4),
          Text(_sizeLine(b), style: mont(10, w: 400, color: kMuted, height: 1.7)),
          const SizedBox(height: 14),
          SizedBox(height: 170, child: SizeComparison(body: b)),
        ]),
      ],
    );
  }

  static String _sizeLine(Body b) {
    final r = b.diameterKm / 12742;
    if (b.id == 'earth') return 'Earth next to its Moon, to scale.';
    if (r >= 1) return '${b.name} is ${r.toStringAsFixed(r > 20 ? 0 : 1)}× as wide as Earth.';
    final pct = r * 100;
    return '${b.name} is ${pct < 1 ? pct.toStringAsFixed(2) : pct.toStringAsFixed(0)}% as wide as Earth.';
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final items = body.history;
    return ListView(
      padding: EdgeInsets.fromLTRB(26, 26, 26, MediaQuery.of(context).padding.bottom + 40),
      children: [
        _Staggered(children: [
          Text('Exploration', style: mont(18, w: 600)),
          const SizedBox(height: 22),
          for (var i = 0; i < items.length; i++) _TimelineRow(item: items[i], first: i == 0, last: i == items.length - 1),
        ]),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.first, required this.last});
  final Milestone item;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(item.year, style: mont(11, w: 600)),
            ),
          ),
          SizedBox(
            width: 22,
            child: CustomPaint(painter: _TimelinePainter(first: first, last: last)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title.toUpperCase(), style: mont(8, w: 600, spacing: 2)),
                  const SizedBox(height: 6),
                  Text(item.text, style: mont(10.5, w: 400, color: const Color(0xFF6B6B6B), height: 1.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({required this.first, required this.last});
  final bool first;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final line = Paint()..color = kHairline;
    if (!last) canvas.drawLine(Offset(x, 8), Offset(x, size.height + 2), line);
    canvas.drawCircle(Offset(x, 7), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(x, 7),
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = kInk,
    );
    if (first) canvas.drawCircle(Offset(x, 7), 1.6, Paint()..color = kInk);
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => old.first != first || old.last != last;
}

class _DiagramTab extends StatelessWidget {
  const _DiagramTab({required this.body});
  final Body body;

  @override
  Widget build(BuildContext context) {
    final b = body;
    return ListView(
      padding: EdgeInsets.fromLTRB(26, 26, 26, MediaQuery.of(context).padding.bottom + 40),
      children: [
        _Staggered(children: [
          Text('Orbit', style: mont(18, w: 600)),
          const SizedBox(height: 4),
          Text(
            b.isStar
                ? 'The eight planets circling the Sun (distances compressed).'
                : b.parentName != null
                    ? '${b.name} circling ${b.parentName}.'
                    : '${b.name}\'s path around the Sun at ${b.orbitAu} AU (distances compressed).',
            style: mont(10, w: 400, color: kMuted, height: 1.7),
          ),
          const SizedBox(height: 10),
          AspectRatio(aspectRatio: 1, child: OrbitDiagram(body: b)),
          const SizedBox(height: 26),
          Text('Inside', style: mont(18, w: 600)),
          const SizedBox(height: 4),
          Text('A cutaway of the interior layers.', style: mont(10, w: 400, color: kMuted, height: 1.7)),
          const SizedBox(height: 16),
          SizedBox(height: math.max(180, b.layers.length * 46.0), child: StructureDiagram(body: b)),
        ]),
      ],
    );
  }
}
