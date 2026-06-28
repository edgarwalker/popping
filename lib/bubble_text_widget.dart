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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.fontSize * widget.text.length * 0.6, widget.fontSize * 1.2),
          painter: _BubbleTextPainter(
            text: widget.text,
            fontSize: widget.fontSize,
            color: widget.color,
            elapsed: _controller.value * 20.0,
          ),
        );
      },
    );
  }
}

class _BubbleTextPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final Color color;
  final double elapsed;

  _BubbleTextPainter({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.elapsed,
  });

  static const double _animDuration = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(text.hashCode); // deterministic random
    final paint = Paint()..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final measuredWidth = textPainter.width;
    final measuredHeight = textPainter.height;

    final offsetX = (size.width - measuredWidth) / 2;
    final offsetY = (size.height - measuredHeight) / 2;

    double xPos = offsetX;

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

        final delay = random.nextDouble() * 0.4;
        final t = ((elapsed - delay) / _animDuration).clamp(0.0, 1.0);
        final ease = 1.0 - pow(1.0 - t, 3).toDouble();

        final x = startX + (targetX - startX) * ease;
        final y = startY + (targetY - startY) * ease;

        final settled = t >= 1.0;
        final bobY = settled ? sin(elapsed * 2.0 + targetX * 0.08) * 1.2 : 0.0;

        final hue = HSLColor.fromColor(color).hue + (random.nextDouble() - 0.5) * 40;
        final fragColor = HSLColor.fromAHSL(
          1.0,
          hue % 360,
          0.85 + random.nextDouble() * 0.15,
          0.55 + random.nextDouble() * 0.3,
        ).toColor();

        final radius = 2.0 + random.nextDouble() * 2.0;

        paint.color = fragColor;
        canvas.drawCircle(Offset(x, y + bobY), radius, paint);

        paint.color = const Color(0x33FFFFFF);
        canvas.drawCircle(Offset(x - 0.8, y + bobY - 0.8), radius * 0.35, paint);
      }

      xPos += charWidth;

      // Kerning
      if (c < text.length - 1) {
        final nextChar = text[c + 1].toUpperCase();
        final currUpper = char.toUpperCase();
        if (currUpper == 'W' && nextChar == 'E') {
          xPos -= fontSize * 0.1;
        } else if (currUpper == 'E' && nextChar == 'L') {
          xPos += fontSize * 0.05;
        } else if (currUpper == 'L' && nextChar == 'L') {
          xPos += fontSize * 0.05;
        }
      }
    }
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
            points.add(Offset(
              from.dx + (to.dx - from.dx) * t,
              from.dy + (to.dy - from.dy) * t,
            ));
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
          points.add(Offset(
            w * 0.35 + cos(angle) * w * 0.35,
            h * 0.47 + sin(angle) * h * 0.42,
          ));
        }
        break;
      case 'O':
        for (double t = 0; t <= 1; t += 0.04) {
          final angle = t * 2 * pi;
          points.add(Offset(
            w * 0.5 + cos(angle) * w * 0.35,
            h * 0.5 + sin(angle) * h * 0.4,
          ));
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

  @override
  bool shouldRepaint(_BubbleTextPainter oldDelegate) => true;
}
