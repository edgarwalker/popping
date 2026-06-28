import 'dart:math';

import 'package:flutter/widgets.dart';

/// Flutter widget that renders 7 small colorful bubbles dancing up and down.
class DancingBubblesWidget extends StatefulWidget {
  final double width;
  final double height;

  const DancingBubblesWidget({super.key, this.width = 200, this.height = 40});

  @override
  State<DancingBubblesWidget> createState() => _DancingBubblesWidgetState();
}

class _DancingBubblesWidgetState extends State<DancingBubblesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;
  double _elapsed = 0.0;
  double _lastTime = 0.0;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _colors = List.generate(7, (_) {
      return HSLColor.fromAHSL(
        1.0,
        random.nextDouble() * 360,
        0.9,
        0.7,
      ).toColor();
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_tick);
  }

  void _tick() {
    final now = _controller.value;
    // Calculate dt from 0-1 repeating value
    double dt;
    if (now >= _lastTime) {
      dt = now - _lastTime;
    } else {
      dt = (1.0 - _lastTime) + now;
    }
    _lastTime = now;
    _elapsed += dt;
    // No setState needed — CustomPaint repaints via animation listener
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _DancingBubblesPainter(elapsed: _elapsed, colors: _colors),
          );
        },
      ),
    );
  }
}

class _DancingBubblesPainter extends CustomPainter {
  final double elapsed;
  final List<Color> colors;

  _DancingBubblesPainter({required this.elapsed, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 7;
    const radius = 8.0;
    final spacing = size.width / (count + 1);
    const bounceHeight = 10.0;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final phase = i * 0.4;
      final bounce = sin(elapsed * 4.0 + phase) * bounceHeight;

      final x = spacing * (i + 1);
      final y = size.height / 2 + bounce;

      paint.color = colors[i];
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Highlight
      paint.color = const Color(0x44FFFFFF);
      canvas.drawCircle(Offset(x - 2, y - 2), radius * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(_DancingBubblesPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}
