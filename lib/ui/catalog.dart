import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/bodies.dart';
import '../render/planet.dart';
import 'common.dart';
import 'detail_screen.dart';

final List<Body> allBodies = [
  sun,
  for (final p in planets) ...[p, if (p.companion != null && !p.companion!.isStar) p.companion!],
];

/// Frosted overlay listing every body, with live search.
/// Planets go to [onPlanet] when given; everything else opens its detail page
/// (or [onBody] when given).
Future<void> showCatalog(
  BuildContext context, {
  bool autofocus = false,
  ValueChanged<Body>? onPlanet,
  ValueChanged<Body>? onBody,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, _) => _Catalog(
      autofocus: autofocus,
      onPick: (b) {
        Navigator.of(context).pop();
        if (onPlanet != null && planets.contains(b)) {
          onPlanet(b);
        } else if (onBody != null) {
          onBody(b);
        } else {
          Navigator.of(context).push(detailRoute(b));
        }
      },
    ),
    transitionBuilder: (context, a, _, child) {
      final t = Curves.easeOutCubic.transform(a.value);
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.25 * t),
          child: Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 40 * (1 - t)), child: child),
          ),
        ),
      );
    },
  );
}

class _Catalog extends StatefulWidget {
  const _Catalog({required this.autofocus, required this.onPick});
  final bool autofocus;
  final ValueChanged<Body> onPick;

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final items = allBodies
        .where((b) => _q.isEmpty || b.name.toLowerCase().contains(_q) || b.kind.toLowerCase().contains(_q))
        .toList();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 34, height: 3, decoration: BoxDecoration(color: kHairline, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Row(
                  children: [
                    Text('Explore', style: mont(20, w: 600)),
                    const Spacer(),
                    Text('${allBodies.length} BODIES', style: mont(7.5, w: 600, color: kMuted, spacing: 2)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
                child: TextField(
                  autofocus: widget.autofocus,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  style: mont(12, w: 500),
                  cursorColor: kInk,
                  decoration: InputDecoration(
                    hintText: 'Search planets and moons',
                    hintStyle: mont(12, w: 400, color: const Color(0xFFB0B0B0)),
                    prefixIcon: const Padding(padding: EdgeInsets.all(14), child: SearchGlyph(color: kMuted)),
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, pad.bottom + 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final b = items[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onPick(b),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(color: kSpace, shape: BoxShape.circle),
                              child: PlanetView(
                                body: b,
                                light: Lights.card,
                                geometry: SphereGeometry.disc(radius: b.hasRing ? 0.2 : (b.isStar ? 0.26 : 0.34)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: mont(13, w: 600)),
                                  const SizedBox(height: 3),
                                  Text(
                                    b.parentName != null ? '${b.kind} · orbits ${b.parentName}' : b.kind,
                                    style: mont(9, w: 400, color: kMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: b.accent, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
