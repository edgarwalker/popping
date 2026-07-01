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

  // Cached paints — allocated once, never recreated
  final Paint _tailPaint =
      Paint()
        ..color = const Color(0xFFAABBCC)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

  final Paint _footPaint =
      Paint()
        ..color = const Color(0xFFBBCCDD)
        ..style = PaintingStyle.fill;

  final Paint _padPaint =
      Paint()
        ..color = const Color(0xFFFFCCDD)
        ..style = PaintingStyle.fill;

  final Paint _bodyPaint =
      Paint()
        ..color = const Color(0xFFCCDDEE)
        ..style = PaintingStyle.fill;

  final Paint _armPaint =
      Paint()
        ..color = const Color(0xFFCCDDEE)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

  final Paint _pawPaint =
      Paint()
        ..color = const Color(0xFFBBCCDD)
        ..style = PaintingStyle.fill;

  final Paint _headPaint =
      Paint()
        ..color = const Color(0xFFDDEEFF)
        ..style = PaintingStyle.fill;

  final Paint _earPaint =
      Paint()
        ..color = const Color(0xFFCCDDEE)
        ..style = PaintingStyle.fill;

  final Paint _innerEarPaint =
      Paint()
        ..color = const Color(0xFFFFCCDD)
        ..style = PaintingStyle.fill;

  final Paint _eyePaint =
      Paint()
        ..color = const Color(0xFF334455)
        ..style = PaintingStyle.fill;

  final Paint _browPaint =
      Paint()
        ..color = const Color(0xFF556677)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

  final Paint _nosePaint =
      Paint()
        ..color = const Color(0xFFFFAABB)
        ..style = PaintingStyle.fill;

  final Paint _mouthPaint =
      Paint()
        ..color = const Color(0xFF556677)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

  final Paint _whiskerPaint =
      Paint()
        ..color = const Color(0xFF99AABB)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

  final Paint _tearPaint =
      Paint()
        ..color = const Color(0xAA88CCFF)
        ..style = PaintingStyle.fill;

  // Reusable paths for animated parts (reset each frame)
  final Path _tailPath = Path();
  final Path _arm1Path = Path();
  final Path _arm2Path = Path();
  final Path _leftEarPath = Path();
  final Path _leftInnerPath = Path();
  final Path _rightEarPath = Path();
  final Path _rightInnerPath = Path();

  // Static paths (never change)
  static final Path _leftEyePath =
      Path()..addArc(
        Rect.fromCenter(center: const Offset(-10, -15), width: 10, height: 8),
        0.2,
        pi,
      );
  static final Path _rightEyePath =
      Path()..addArc(
        Rect.fromCenter(center: const Offset(10, -15), width: 10, height: 8),
        -0.2,
        pi,
      );
  static final Path _mouthPath =
      Path()..addArc(
        Rect.fromCenter(center: const Offset(0, 1), width: 14, height: 8),
        pi + 0.3,
        pi - 0.6,
      );

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
    _drawFeet(canvas);
    _drawBody(canvas);
    _drawHead(canvas);
    _drawEars(canvas);
    _drawFace(canvas);
    _drawArms(canvas);
    _drawTears(canvas);

    canvas.restore();
  }

  void _drawTail(Canvas canvas) {
    final sway = sin(_elapsed * 4.0) * 8.0;
    _tailPath.reset();
    _tailPath.moveTo(-24, 40);
    _tailPath.cubicTo(
      -60,
      40 + sway * 0.3,
      -65 + sway * 0.5,
      -15 + sway * 0.5,
      -35 + sway,
      -50,
    );
    canvas.drawPath(_tailPath, _tailPaint);
  }

  void _drawFeet(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, 72), width: 18, height: 13),
      _footPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(20, 72), width: 18, height: 13),
      _footPaint,
    );

    canvas.drawCircle(const Offset(-23, 72), 2.5, _padPaint);
    canvas.drawCircle(const Offset(-20, 70), 2.5, _padPaint);
    canvas.drawCircle(const Offset(-17, 72), 2.5, _padPaint);
    canvas.drawCircle(const Offset(17, 72), 2.5, _padPaint);
    canvas.drawCircle(const Offset(20, 70), 2.5, _padPaint);
    canvas.drawCircle(const Offset(23, 72), 2.5, _padPaint);
  }

  void _drawBody(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 40), width: 84, height: 64),
      _bodyPaint,
    );
  }

  void _drawArms(Canvas canvas) {
    final wipe = sin(_elapsed * 3.0) * 3.5;

    _arm1Path.reset();
    _arm1Path.moveTo(-28, 28);
    _arm1Path.quadraticBezierTo(-30, 2, -10 + wipe, -7);
    canvas.drawPath(_arm1Path, _armPaint);

    _arm2Path.reset();
    _arm2Path.moveTo(28, 28);
    _arm2Path.quadraticBezierTo(30, 2, 10 - wipe, -7);
    canvas.drawPath(_arm2Path, _armPaint);

    canvas.drawCircle(Offset(-10 + wipe, -7), 5, _pawPaint);
    canvas.drawCircle(Offset(10 - wipe, -7), 5, _pawPaint);
  }

  void _drawHead(Canvas canvas) {
    canvas.drawCircle(const Offset(0, -12), 28, _headPaint);
  }

  void _drawEars(Canvas canvas) {
    final earSway = sin(_elapsed * 2.5) * 2.0;

    _leftEarPath.reset();
    _leftEarPath.moveTo(-20, -32);
    _leftEarPath.quadraticBezierTo(-30 + earSway, -55, -18 + earSway, -55);
    _leftEarPath.quadraticBezierTo(-8, -55, -8, -39);
    _leftEarPath.close();
    canvas.drawPath(_leftEarPath, _earPaint);

    _leftInnerPath.reset();
    _leftInnerPath.moveTo(-18, -35);
    _leftInnerPath.quadraticBezierTo(-25 + earSway, -49, -17 + earSway, -49);
    _leftInnerPath.quadraticBezierTo(-10, -49, -11, -38);
    _leftInnerPath.close();
    canvas.drawPath(_leftInnerPath, _innerEarPaint);

    _rightEarPath.reset();
    _rightEarPath.moveTo(20, -32);
    _rightEarPath.quadraticBezierTo(30 + earSway, -55, 18 + earSway, -55);
    _rightEarPath.quadraticBezierTo(8, -55, 8, -39);
    _rightEarPath.close();
    canvas.drawPath(_rightEarPath, _earPaint);

    _rightInnerPath.reset();
    _rightInnerPath.moveTo(18, -35);
    _rightInnerPath.quadraticBezierTo(25 + earSway, -49, 17 + earSway, -49);
    _rightInnerPath.quadraticBezierTo(10, -49, 11, -38);
    _rightInnerPath.close();
    canvas.drawPath(_rightInnerPath, _innerEarPaint);
  }

  void _drawFace(Canvas canvas) {
    canvas.drawPath(_leftEyePath, _eyePaint);
    canvas.drawPath(_rightEyePath, _eyePaint);

    canvas.drawLine(const Offset(-14, -23), const Offset(-7, -21), _browPaint);
    canvas.drawLine(const Offset(14, -23), const Offset(7, -21), _browPaint);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -8), width: 5, height: 4),
      _nosePaint,
    );

    canvas.drawPath(_mouthPath, _mouthPaint);

    canvas.drawLine(
      const Offset(-12, -7),
      const Offset(-26, -10),
      _whiskerPaint,
    );
    canvas.drawLine(
      const Offset(-12, -4),
      const Offset(-26, -3),
      _whiskerPaint,
    );
    canvas.drawLine(const Offset(12, -7), const Offset(26, -10), _whiskerPaint);
    canvas.drawLine(const Offset(12, -4), const Offset(26, -3), _whiskerPaint);
  }

  void _drawTears(Canvas canvas) {
    // Wave 1
    final tearCycle = _elapsed % 1.0;
    final tearY = tearCycle * 22.0;
    final tearOpacity = (1.0 - tearCycle).clamp(0.0, 1.0);

    _tearPaint.color = Color.fromRGBO(136, 204, 255, tearOpacity * 0.7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-10, -2 + tearY),
        width: 3,
        height: 4 + tearCycle * 2,
      ),
      _tearPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(10, -2 + tearY),
        width: 3,
        height: 4 + tearCycle * 2,
      ),
      _tearPaint,
    );

    // Wave 2
    final tc2 = (_elapsed + 0.33) % 1.0;
    final ty2 = tc2 * 22.0;
    final to2 = (1.0 - tc2).clamp(0.0, 1.0);
    _tearPaint.color = Color.fromRGBO(136, 204, 255, to2 * 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-12, -1 + ty2),
        width: 2.5,
        height: 3.5 + tc2 * 2,
      ),
      _tearPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(12, -1 + ty2),
        width: 2.5,
        height: 3.5 + tc2 * 2,
      ),
      _tearPaint,
    );

    // Wave 3
    final tc3 = (_elapsed + 0.66) % 1.0;
    final ty3 = tc3 * 22.0;
    final to3 = (1.0 - tc3).clamp(0.0, 1.0);
    _tearPaint.color = Color.fromRGBO(136, 204, 255, to3 * 0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-8, -2 + ty3),
        width: 2,
        height: 3 + tc3 * 2,
      ),
      _tearPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(8, -2 + ty3),
        width: 2,
        height: 3 + tc3 * 2,
      ),
      _tearPaint,
    );

    // Wave 4
    final tc4 = (_elapsed + 0.5) % 1.0;
    final ty4 = tc4 * 22.0;
    final to4 = (1.0 - tc4).clamp(0.0, 1.0);
    _tearPaint.color = Color.fromRGBO(150, 220, 255, to4 * 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-11, 0 + ty4),
        width: 2,
        height: 3 + tc4 * 1.5,
      ),
      _tearPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(11, 0 + ty4),
        width: 2,
        height: 3 + tc4 * 1.5,
      ),
      _tearPaint,
    );
  }
}
