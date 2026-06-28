import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// A cute sad cat drawn with Canvas, with animated tears and swaying tail.
class SadCat extends PositionComponent {
  SadCat({required Vector2 position, double scale = 1.0})
    : _scale = scale,
      super(position: position, anchor: Anchor.center, priority: 200);

  final double _scale;
  double _elapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.scale(_scale);

    _drawTail(canvas);
    _drawBody(canvas);
    _drawHead(canvas);
    _drawEars(canvas);
    _drawFace(canvas);
    _drawTears(canvas);

    canvas.restore();
  }

  void _drawTail(Canvas canvas) {
    final tailPaint =
        Paint()
          ..color = const Color(0xFFAABBCC)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // Swaying tail
    final sway = sin(_elapsed * 2.5) * 12.0;
    final path =
        Path()
          ..moveTo(-30, 30)
          ..cubicTo(-50, 10, -55 + sway, -20, -45 + sway, -35);

    canvas.drawPath(path, tailPaint);
  }

  void _drawBody(Canvas canvas) {
    final bodyPaint =
        Paint()
          ..color = const Color(0xFFCCDDEE)
          ..style = PaintingStyle.fill;

    // Rounded body
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 30), width: 60, height: 45),
      bodyPaint,
    );
  }

  void _drawHead(Canvas canvas) {
    final headPaint =
        Paint()
          ..color = const Color(0xFFDDEEFF)
          ..style = PaintingStyle.fill;

    // Round head
    canvas.drawCircle(const Offset(0, -5), 28, headPaint);
  }

  void _drawEars(Canvas canvas) {
    final earPaint =
        Paint()
          ..color = const Color(0xFFCCDDEE)
          ..style = PaintingStyle.fill;
    final innerEarPaint =
        Paint()
          ..color = const Color(0xFFFFCCDD)
          ..style = PaintingStyle.fill;

    // Left ear
    final leftEar =
        Path()
          ..moveTo(-20, -25)
          ..lineTo(-28, -50)
          ..lineTo(-8, -32)
          ..close();
    canvas.drawPath(leftEar, earPaint);

    final leftInner =
        Path()
          ..moveTo(-18, -28)
          ..lineTo(-24, -44)
          ..lineTo(-11, -31)
          ..close();
    canvas.drawPath(leftInner, innerEarPaint);

    // Right ear
    final rightEar =
        Path()
          ..moveTo(20, -25)
          ..lineTo(28, -50)
          ..lineTo(8, -32)
          ..close();
    canvas.drawPath(rightEar, earPaint);

    final rightInner =
        Path()
          ..moveTo(18, -28)
          ..lineTo(24, -44)
          ..lineTo(11, -31)
          ..close();
    canvas.drawPath(rightInner, innerEarPaint);
  }

  void _drawFace(Canvas canvas) {
    final eyePaint =
        Paint()
          ..color = const Color(0xFF334455)
          ..style = PaintingStyle.fill;

    // Sad eyes (droopy arcs)
    final leftEyePath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(-10, -8), width: 10, height: 8),
          0.2, // start angle tilted
          pi, // half circle
        );
    canvas.drawPath(leftEyePath, eyePaint);

    final rightEyePath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(10, -8), width: 10, height: 8),
          -0.2,
          pi,
        );
    canvas.drawPath(rightEyePath, eyePaint);

    // Eyebrows (angled down in center for sadness)
    final browPaint =
        Paint()
          ..color = const Color(0xFF556677)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(-14, -16), const Offset(-7, -14), browPaint);
    canvas.drawLine(const Offset(14, -16), const Offset(7, -14), browPaint);

    // Small nose
    final nosePaint =
        Paint()
          ..color = const Color(0xFFFFAABB)
          ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -1), width: 5, height: 4),
      nosePaint,
    );

    // Sad mouth (frown)
    final mouthPaint =
        Paint()
          ..color = const Color(0xFF556677)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final mouthPath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 8),
          pi + 0.3, // frown arc
          pi - 0.6,
        );
    canvas.drawPath(mouthPath, mouthPaint);

    // Whiskers
    final whiskerPaint =
        Paint()
          ..color = const Color(0xFF99AABB)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(-12, 0), const Offset(-26, -3), whiskerPaint);
    canvas.drawLine(const Offset(-12, 3), const Offset(-26, 4), whiskerPaint);
    canvas.drawLine(const Offset(12, 0), const Offset(26, -3), whiskerPaint);
    canvas.drawLine(const Offset(12, 3), const Offset(26, 4), whiskerPaint);
  }

  void _drawTears(Canvas canvas) {
    final tearPaint =
        Paint()
          ..color = const Color(0xAA88CCFF)
          ..style = PaintingStyle.fill;

    // Animated tears falling cyclically
    final tearCycle = _elapsed % 1.2; // 1.2 second cycle
    final tearY = tearCycle * 20.0;
    final tearOpacity = (1.0 - tearCycle / 1.2).clamp(0.0, 1.0);

    tearPaint.color = Color.fromRGBO(136, 204, 255, tearOpacity * 0.7);

    // Left tear
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-10, -2 + tearY),
        width: 3,
        height: 4 + tearCycle * 2,
      ),
      tearPaint,
    );

    // Right tear
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(10, -2 + tearY),
        width: 3,
        height: 4 + tearCycle * 2,
      ),
      tearPaint,
    );

    // Second wave of tears (offset)
    final tearCycle2 = (_elapsed + 0.6) % 1.2;
    final tearY2 = tearCycle2 * 20.0;
    final tearOpacity2 = (1.0 - tearCycle2 / 1.2).clamp(0.0, 1.0);

    tearPaint.color = Color.fromRGBO(136, 204, 255, tearOpacity2 * 0.5);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-10, -2 + tearY2),
        width: 2.5,
        height: 3.5 + tearCycle2 * 2,
      ),
      tearPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(10, -2 + tearY2),
        width: 2.5,
        height: 3.5 + tearCycle2 * 2,
      ),
      tearPaint,
    );
  }
}
