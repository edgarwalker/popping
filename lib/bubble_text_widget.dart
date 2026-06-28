import 'dart:math';

import 'package:flutter/widgets.dart';

/// Flutter widget that renders text formed by small bubble fragments
/// that animate in and gently bob once settled.
class BubbleTextWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;

  const BubbleTextWidget({
    super.key,
    required this.text,
    this.fontSize = 48,
    this.color = const Color(0xFFFFDD00),
  });

  @override
  State<BubbleTextWidget> createState() => _BubbleTextWidgetState();
}

class _BubbleTextWidgetState extends State<BubbleTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Fragment> _fragments;
  late Size _paintSize;
  double _elapsed = 0.0;
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    _paintSize = Size(
      widget.fontSize * widget.text.length * 0.6,
      widget.fontSize * 1.2,
    );
    _fragments = _buildFragments();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_tick);
  }

  void _tick() {
    final now = _controller.value;
    double dt;
    if (now >= _lastValue) {
      dt = now - _lastValue;
    } else {
      dt = (1.0 - _lastValue) + now;
    }
    _lastValue = now;
    _elapsed += dt;
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  List<_Fragment> _buildFragments() {
    final random = Random(widget.text.hashCode);
    final fragments = <_Fragment>[];

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final measuredWidth = textPainter.width;
    final measuredHeight = textPainter.height;

    final offsetX = (_paintSize.width - measuredWidth) / 2;
    final offsetY = (_paintSize.height - measuredHeight) / 2;

    final baseHue = HSLColor.fromColor(widget.color).hue;

    double xPos = offsetX;

    for (int c = 0; c < widget.text.length; c++) {
      final char = widget.text[c];

      final charPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final charWidth = charPainter.width;
      final charHeight = charPainter.height;

      if (char == ' ') {
        xPos += charWidth;
        continue;
      }

      final points = _getLetterPoints(char, charWidth, charHeight);

      for (final point in points) {
        final targetX = xPos + point.dx;
        final targetY = offsetY + point.dy;

        final angle = random.nextDouble() * 2 * pi;
        final dist = 80 + random.nextDouble() * 120;
        final startX = targetX + cos(angle) * dist;
        final startY = targetY + sin(angle) * dist;

        final hue = baseHue + (random.nextDouble() - 0.5) * 40;
        final r = random.nextDouble();
        final r2 = random.nextDouble();
        final fragColor =
            HSLColor.fromAHSL(
              1.0,
              hue % 360,
              0.85 + r * 0.15,
              0.55 + r2 * 0.3,
            ).toColor();

        final radius = 2.0 + random.nextDouble() * 2.0;
        final delay = random.nextDouble() * 0.4;

        fragments.add(
          _Fragment(
            startX: startX,
            startY: startY,
            targetX: targetX,
            targetY: targetY,
            radius: radius,
            colorR: (fragColor.r * 255).round(),
            colorG: (fragColor.g * 255).round(),
            colorB: (fragColor.b * 255).round(),
            delay: delay,
          ),
        );
      }

      xPos += charWidth;

      // Kerning
      if (c < widget.text.length - 1) {
        final nextChar = widget.text[c + 1].toUpperCase();
        final currUpper = char.toUpperCase();
        if (currUpper == 'W' && nextChar == 'E') {
          xPos -= widget.fontSize * 0.1;
        } else if (currUpper == 'E' && nextChar == 'L') {
          xPos += widget.fontSize * 0.05;
        } else if (currUpper == 'L' && nextChar == 'L') {
          xPos += widget.fontSize * 0.05;
        }
      }
    }

    return fragments;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: _paintSize,
            painter: _BubbleTextPainter(
              fragments: _fragments,
              elapsed: _elapsed,
            ),
          );
        },
      ),
    );
  }
}

class _BubbleTextPainter extends CustomPainter {
  final List<_Fragment> fragments;
  final double elapsed;

  static const double _animDuration = 0.8;

  _BubbleTextPainter({required this.fragments, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < fragments.length; i++) {
      final frag = fragments[i];
      final t = ((elapsed - frag.delay) / _animDuration).clamp(0.0, 1.0);
      final ease = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t); // cubic ease out

      final x = frag.startX + (frag.targetX - frag.startX) * ease;
      final y = frag.startY + (frag.targetY - frag.startY) * ease;

      final bobY =
          t >= 1.0 ? sin(elapsed * 2.0 + frag.targetX * 0.08) * 1.2 : 0.0;

      paint.color = Color.fromARGB(255, frag.colorR, frag.colorG, frag.colorB);
      canvas.drawCircle(Offset(x, y + bobY), frag.radius, paint);

      paint.color = const Color(0x33FFFFFF);
      canvas.drawCircle(
        Offset(x - 0.8, y + bobY - 0.8),
        frag.radius * 0.35,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BubbleTextPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}

class _Fragment {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final double radius;
  final int colorR;
  final int colorG;
  final int colorB;
  final double delay;

  const _Fragment({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.radius,
    required this.colorR,
    required this.colorG,
    required this.colorB,
    required this.delay,
  });
}

List<Offset> _getLetterPoints(String char, double w, double h) {
  final points = <Offset>[];
  const step = 3.0;

  switch (char.toUpperCase()) {
    case 'W':
      final wPts = [
        Offset(w * 0.05, h * 0.1),
        Offset(w * 0.22, h * 0.9),
        Offset(w * 0.38, h * 0.45),
        Offset(w * 0.55, h * 0.9),
        Offset(w * 0.72, h * 0.1),
      ];
      for (int i = 0; i < wPts.length - 1; i++) {
        final from = wPts[i];
        final to = wPts[i + 1];
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
      for (double t = 0; t <= 1; t += step / h) {
        points.add(Offset(w * 0.05, t * h * 0.9 + h * 0.05));
      }
      for (double t = 0; t <= 1; t += step / w) {
        points.add(Offset(w * 0.05 + t * w * 0.9, h * 0.9));
      }
      break;
    case 'D':
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
      for (double t = 0; t <= 1; t += step / h) {
        points.add(Offset(w * 0.2, t * h * 0.9 + h * 0.05));
        points.add(Offset(w * 0.8, t * h * 0.9 + h * 0.05));
        points.add(Offset(w * 0.2 + t * w * 0.6, t * h * 0.9 + h * 0.05));
      }
      break;
    default:
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
