import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Paints a seamless islamic star tessellation (an eight-point *khatam* grid).
///
/// Everything is drawn with strokes at very low opacity, so it reads as texture
/// rather than decoration: it gives every surface of the app a hand-crafted
/// feel without shipping a single image asset.
class HodaPatternPainter extends CustomPainter {
  const HodaPatternPainter({
    required this.color,
    this.tile = 78,
    this.strokeWidth = 1,
    this.drawStars = true,
    this.drawGrid = true,
  });

  final Color color;
  final double tile;
  final double strokeWidth;
  final bool drawStars;
  final bool drawGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double half = tile / 2;
    final double r = tile * 0.40;

    for (double y = -tile; y < size.height + tile; y += tile) {
      for (double x = -tile; x < size.width + tile; x += tile) {
        final Offset c = Offset(x + half, y + half);
        if (drawStars) _octagram(canvas, c, r, stroke);
        if (drawGrid) {
          // Small diamond knots on the lattice intersections.
          _diamond(canvas, Offset(x, y), tile * 0.10, stroke);
        }
      }
    }
  }

  /// Two overlapping squares, rotated 45 degrees against each other — the
  /// classic eight-point star found on tilework and mosque doors.
  void _octagram(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawPath(_polygon(c, r, 4, math.pi / 4), paint);
    canvas.drawPath(_polygon(c, r, 4, 0), paint);
    canvas.drawCircle(c, r * 0.34, paint);
  }

  void _diamond(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawPath(_polygon(c, r, 4, 0), paint);
  }

  Path _polygon(Offset c, double r, int sides, double rotation) {
    final Path path = Path();
    for (int i = 0; i < sides; i++) {
      final double a = rotation + (i * 2 * math.pi / sides);
      final Offset p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(HodaPatternPainter old) =>
      old.color != color ||
      old.tile != tile ||
      old.strokeWidth != strokeWidth ||
      old.drawStars != drawStars ||
      old.drawGrid != drawGrid;
}

/// A non-interactive ornament layer, meant to be dropped into a [Stack].
class PatternLayer extends StatelessWidget {
  const PatternLayer({
    super.key,
    this.color,
    this.tile = 78,
    this.opacity = 1,
    this.drawGrid = true,
  });

  final Color? color;
  final double tile;
  final double opacity;
  final bool drawGrid;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: HodaPatternPainter(
            color: (color ?? palette.pattern).withOpacity(
              ((color ?? palette.pattern).opacity * opacity).clamp(0.0, 1.0),
            ),
            tile: tile,
            drawGrid: drawGrid,
          ),
        ),
      ),
    );
  }
}

/// The ambient app background: vertical paper/night gradient, two soft glow
/// blobs and the star lattice. Every screen wraps its body in this so the whole
/// app shares one atmosphere.
class HodaBackground extends StatelessWidget {
  const HodaBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.showGlow = true,
  });

  final Widget child;
  final bool showPattern;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.pageGradient),
      child: Stack(
        children: <Widget>[
          if (showGlow) ...<Widget>[
            Positioned(
              top: -140,
              right: -110,
              child: _Glow(color: palette.glowA, size: 340),
            ),
            Positioned(
              bottom: -170,
              left: -130,
              child: _Glow(color: palette.glowB, size: 380),
            ),
          ],
          if (showPattern) Positioned.fill(child: const PatternLayer()),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

/// A gold hairline with a small rosette in the middle — used to close sections
/// the way a manuscript page would.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.color, this.width = 180});

  final Color? color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    final Color c = color ?? palette.accent;
    Widget line(bool toCenter) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  toCenter ? c.withOpacity(0) : c.withOpacity(0.6),
                  toCenter ? c.withOpacity(0.6) : c.withOpacity(0),
                ],
              ),
            ),
          ),
        );

    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          line(true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          line(false),
        ],
      ),
    );
  }
}
