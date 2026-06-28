import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// 7 small colorful bubbles that dance up and down.
class DancingBubbles extends PositionComponent {
  DancingBubbles({required Vector2 position})
    : super(position: position, anchor: Anchor.center, priority: 100);

  double _elapsed = 0.0;

  static const int _count = 7;
  static const double _bubbleRadius = 10.0;
  static const double _spacing = 28.0;
  static const double _bounceHeight = 12.0;

  late final List<Color> _colors;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = Random();
    _colors = List.generate(_count, (_) {
      return HSLColor.fromAHSL(
        1.0,
        random.nextDouble() * 360,
        0.9 + random.nextDouble() * 0.1,
        0.7 + random.nextDouble() * 0.15,
      ).toColor();
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final totalWidth = (_count - 1) * _spacing;
    final startX = -totalWidth / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _count; i++) {
      // Each bubble has a phase offset so they dance in a wave
      final phase = i * 0.4;
      final bounce = sin(_elapsed * 4.0 + phase) * _bounceHeight;

      final x = startX + i * _spacing;
      final y = bounce;

      paint.color = _colors[i];

      // Draw with gradient-like effect: brighter center
      canvas.drawCircle(Offset(x, y), _bubbleRadius, paint);

      paint.color = const Color(0x55FFFFFF);
      canvas.drawCircle(
        Offset(x - 2, y - 2),
        _bubbleRadius * 0.4,
        paint,
      );
    }
  }
}
