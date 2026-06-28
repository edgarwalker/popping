import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Renders text where each letter is drawn using small bubble fragments
/// placed along the actual letter outlines.
class BubbleText extends PositionComponent {
  final String text;
  final double fontSize;
  final Color color;

  BubbleText({
    required this.text,
    required Vector2 position,
    this.fontSize = 48,
    this.color = const Color(0xFFFFDD00),
  }) : super(position: position, anchor: Anchor.center, priority: 100);

  double _elapsed = 0.0;
  static const double _animDuration = 0.8; // seconds to settle
  final List<_BubbleFragment> _fragments = [];
  bool _initialized = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (!_initialized) {
      _initFragments();
      _initialized = true;
    }
  }

  void _initFragments() {
    final random = Random();

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final measuredWidth = textPainter.width;
    final measuredHeight = textPainter.height;

    // For each character, place fragments along its stroke paths
    double xOffset = -measuredWidth / 2;

    for (int c = 0; c < text.length; c++) {
      final char = text[c];

      final charPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final charWidth = charPainter.width;
      final charHeight = charPainter.height;

      if (char == ' ') {
        xOffset += charWidth;
        continue;
      }

      // Sample points along the character strokes using known letter shapes
      final points = _getLetterPoints(char, charWidth, charHeight);

      for (final point in points) {
        final targetX = xOffset + point.dx;
        final targetY = -measuredHeight / 2 + point.dy;

        // Random start position (scattered outward)
        final angle = random.nextDouble() * 2 * pi;
        final dist = 80 + random.nextDouble() * 120;
        final startX = targetX + cos(angle) * dist;
        final startY = targetY + sin(angle) * dist;

        final hue =
            HSLColor.fromColor(color).hue + (random.nextDouble() - 0.5) * 40;

        final fragColor =
            HSLColor.fromAHSL(
              1.0,
              hue % 360,
              0.85 + random.nextDouble() * 0.15,
              0.55 + random.nextDouble() * 0.3,
            ).toColor();

        _fragments.add(
          _BubbleFragment(
            startX: startX,
            startY: startY,
            targetX: targetX,
            targetY: targetY,
            radius: 2.0 + random.nextDouble() * 2.0,
            color: fragColor,
            delay: random.nextDouble() * 0.4,
          ),
        );
      }

      xOffset += charWidth;

      // Custom kerning: adjust spacing for specific pairs
      if (c < text.length - 1) {
        final nextChar = text[c + 1].toUpperCase();
        final currUpper = char.toUpperCase();
        if (currUpper == 'W' && nextChar == 'E') {
          xOffset -= fontSize * 0.1; // tighter W-E
        } else if (currUpper == 'E' && nextChar == 'L') {
          xOffset += fontSize * 0.05; // wider E-L
        } else if (currUpper == 'L' && nextChar == 'L') {
          xOffset += fontSize * 0.05; // wider L-L
        }
      }
    }
  }

  /// Generate sample points along the strokes of a given character.
  List<Offset> _getLetterPoints(String char, double w, double h) {
    final points = <Offset>[];
    final step = 3.0; // density of points

    switch (char.toUpperCase()) {
      case 'W':
        // W: trace a continuous W path (top-left, bottom-left, mid-top, bottom-right, top-right)
        final wPoints = [
          Offset(w * 0.05, h * 0.1),
          Offset(w * 0.22, h * 0.9),
          Offset(w * 0.38, h * 0.45),
          Offset(w * 0.55, h * 0.9),
          Offset(w * 0.72, h * 0.1),
        ];
        for (int i = 0; i < wPoints.length - 1; i++) {
          final from = wPoints[i];
          final to = wPoints[i + 1];
          for (double t = 0; t <= 1; t += 0.05) {
            points.add(
              Offset(
                from.dx + (to.dx - from.dx) * t,
                from.dy + (to.dy - from.dy) * t,
              ),
            );
          }
        }
        break;
      case 'E':
        // E: vertical line + 3 horizontal lines
        for (double t = 0; t <= 1; t += step / h) {
          points.add(Offset(w * 0.2, t * h * 0.9 + h * 0.05));
        }
        for (double t = 0; t <= 1; t += step / w) {
          points.add(Offset(w * 0.2 + t * w * 0.6, h * 0.05));
          points.add(Offset(w * 0.2 + t * w * 0.5, h * 0.47));
          points.add(Offset(w * 0.2 + t * w * 0.6, h * 0.9));
        }
        break;
      case 'L':
        // L: vertical + longer horizontal
        for (double t = 0; t <= 1; t += step / h) {
          points.add(Offset(w * 0.05, t * h * 0.9 + h * 0.05));
        }
        for (double t = 0; t <= 1; t += step / w) {
          points.add(Offset(w * 0.05 + t * w * 0.9, h * 0.9));
        }
        break;
      case 'D':
        // D: vertical + curve
        for (double t = 0; t <= 1; t += step / h) {
          points.add(Offset(w * 0.2, t * h * 0.9 + h * 0.05));
        }
        for (double t = 0; t <= 1; t += 0.05) {
          final angle = -pi / 2 + t * pi;
          points.add(
            Offset(
              w * 0.35 + cos(angle) * w * 0.35,
              h * 0.47 + sin(angle) * h * 0.42,
            ),
          );
        }
        break;
      case 'O':
        // O: ellipse
        for (double t = 0; t <= 1; t += 0.04) {
          final angle = t * 2 * pi;
          points.add(
            Offset(
              w * 0.5 + cos(angle) * w * 0.35,
              h * 0.5 + sin(angle) * h * 0.4,
            ),
          );
        }
        break;
      case 'N':
        // N: two verticals + diagonal
        for (double t = 0; t <= 1; t += step / h) {
          points.add(Offset(w * 0.2, t * h * 0.9 + h * 0.05));
          points.add(Offset(w * 0.8, t * h * 0.9 + h * 0.05));
          points.add(Offset(w * 0.2 + t * w * 0.6, t * h * 0.9 + h * 0.05));
        }
        break;
      default:
        // Generic: outline the bounding box densely
        for (double t = 0; t <= 1; t += step / h) {
          points.add(Offset(w * 0.2, t * h * 0.9 + h * 0.05));
          points.add(Offset(w * 0.8, t * h * 0.9 + h * 0.05));
        }
        for (double t = 0; t <= 1; t += step / w) {
          points.add(Offset(w * 0.2 + t * w * 0.6, h * 0.05));
          points.add(Offset(w * 0.2 + t * w * 0.6, h * 0.9));
        }
        break;
    }
    return points;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..style = PaintingStyle.fill;

    for (final frag in _fragments) {
      final t = ((_elapsed - frag.delay) / _animDuration).clamp(0.0, 1.0);
      // Ease out cubic
      final ease = 1.0 - pow(1.0 - t, 3).toDouble();

      final x = frag.startX + (frag.targetX - frag.startX) * ease;
      final y = frag.startY + (frag.targetY - frag.startY) * ease;

      // Gentle bobbing after settling
      final settled = t >= 1.0;
      final bobY =
          settled ? sin(_elapsed * 2.0 + frag.targetX * 0.08) * 1.2 : 0.0;

      paint.color = frag.color;
      canvas.drawCircle(Offset(x, y + bobY), frag.radius, paint);

      // Highlight dot
      paint.color = const Color(0x33FFFFFF);
      canvas.drawCircle(
        Offset(x - 0.8, y + bobY - 0.8),
        frag.radius * 0.35,
        paint,
      );
    }
  }
}

class _BubbleFragment {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final double radius;
  final Color color;
  final double delay;

  _BubbleFragment({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.radius,
    required this.color,
    required this.delay,
  });
}
