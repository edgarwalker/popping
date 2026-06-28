import 'dart:math';

import 'package:flutter/widgets.dart';

/// A Flutter widget that renders an animated sad cat using CustomPainter.
class SadCatWidget extends StatefulWidget {
  final double size;

  const SadCatWidget({super.key, this.size = 120});

  @override
  State<SadCatWidget> createState() => _SadCatWidgetState();
}

class _SadCatWidgetState extends State<SadCatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
          size: Size(widget.size, widget.size),
          painter: _SadCatPainter(elapsed: _controller.value * 10.0),
        );
      },
    );
  }
}

class _SadCatPainter extends CustomPainter {
  final double elapsed;

  _SadCatPainter({required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

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
    final tailPaint =
        Paint()
          ..color = const Color(0xFFAABBCC)
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final sway = sin(elapsed * 4.0) * 8.0;
    final path =
        Path()
          ..moveTo(-24, 40)
          ..cubicTo(
            -60,
            40 + sway * 0.3,
            -65 + sway * 0.5,
            -15 + sway * 0.5,
            -35 + sway,
            -50,
          );
    canvas.drawPath(path, tailPaint);
  }

  void _drawFeet(Canvas canvas) {
    final footPaint =
        Paint()
          ..color = const Color(0xFFBBCCDD)
          ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, 72), width: 18, height: 13),
      footPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(20, 72), width: 18, height: 13),
      footPaint,
    );

    final padPaint =
        Paint()
          ..color = const Color(0xFFFFCCDD)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(-23, 72), 2.5, padPaint);
    canvas.drawCircle(const Offset(-20, 70), 2.5, padPaint);
    canvas.drawCircle(const Offset(-17, 72), 2.5, padPaint);
    canvas.drawCircle(const Offset(17, 72), 2.5, padPaint);
    canvas.drawCircle(const Offset(20, 70), 2.5, padPaint);
    canvas.drawCircle(const Offset(23, 72), 2.5, padPaint);
  }

  void _drawBody(Canvas canvas) {
    final bodyPaint =
        Paint()
          ..color = const Color(0xFFCCDDEE)
          ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 40), width: 84, height: 64),
      bodyPaint,
    );
  }

  void _drawHead(Canvas canvas) {
    final headPaint =
        Paint()
          ..color = const Color(0xFFDDEEFF)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(0, -12), 28, headPaint);
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

    final earSway = sin(elapsed * 2.5) * 2.0;

    final leftEar =
        Path()
          ..moveTo(-20, -32)
          ..quadraticBezierTo(-30 + earSway, -55, -18 + earSway, -55)
          ..quadraticBezierTo(-8, -55, -8, -39)
          ..close();
    canvas.drawPath(leftEar, earPaint);

    final leftInner =
        Path()
          ..moveTo(-18, -35)
          ..quadraticBezierTo(-25 + earSway, -49, -17 + earSway, -49)
          ..quadraticBezierTo(-10, -49, -11, -38)
          ..close();
    canvas.drawPath(leftInner, innerEarPaint);

    final rightEar =
        Path()
          ..moveTo(20, -32)
          ..quadraticBezierTo(30 + earSway, -55, 18 + earSway, -55)
          ..quadraticBezierTo(8, -55, 8, -39)
          ..close();
    canvas.drawPath(rightEar, earPaint);

    final rightInner =
        Path()
          ..moveTo(18, -35)
          ..quadraticBezierTo(25 + earSway, -49, 17 + earSway, -49)
          ..quadraticBezierTo(10, -49, 11, -38)
          ..close();
    canvas.drawPath(rightInner, innerEarPaint);
  }

  void _drawFace(Canvas canvas) {
    final eyePaint =
        Paint()
          ..color = const Color(0xFF334455)
          ..style = PaintingStyle.fill;

    final leftEyePath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(-10, -15), width: 10, height: 8),
          0.2,
          pi,
        );
    canvas.drawPath(leftEyePath, eyePaint);

    final rightEyePath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(10, -15), width: 10, height: 8),
          -0.2,
          pi,
        );
    canvas.drawPath(rightEyePath, eyePaint);

    final browPaint =
        Paint()
          ..color = const Color(0xFF556677)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(-14, -23), const Offset(-7, -21), browPaint);
    canvas.drawLine(const Offset(14, -23), const Offset(7, -21), browPaint);

    final nosePaint =
        Paint()
          ..color = const Color(0xFFFFAABB)
          ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -8), width: 5, height: 4),
      nosePaint,
    );

    final mouthPaint =
        Paint()
          ..color = const Color(0xFF556677)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final mouthPath =
        Path()..addArc(
          Rect.fromCenter(center: const Offset(0, 1), width: 14, height: 8),
          pi + 0.3,
          pi - 0.6,
        );
    canvas.drawPath(mouthPath, mouthPaint);

    final whiskerPaint =
        Paint()
          ..color = const Color(0xFF99AABB)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(-12, -7), const Offset(-26, -10), whiskerPaint);
    canvas.drawLine(const Offset(-12, -4), const Offset(-26, -3), whiskerPaint);
    canvas.drawLine(const Offset(12, -7), const Offset(26, -10), whiskerPaint);
    canvas.drawLine(const Offset(12, -4), const Offset(26, -3), whiskerPaint);
  }

  void _drawArms(Canvas canvas) {
    final armPaint =
        Paint()
          ..color = const Color(0xFFCCDDEE)
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final wipe = sin(elapsed * 3.0) * 3.5;

    final path1 =
        Path()
          ..moveTo(-28, 28)
          ..quadraticBezierTo(-30, 2, -10 + wipe, -7);
    canvas.drawPath(path1, armPaint);

    final path2 =
        Path()
          ..moveTo(28, 28)
          ..quadraticBezierTo(30, 2, 10 - wipe, -7);
    canvas.drawPath(path2, armPaint);

    final pawPaint =
        Paint()
          ..color = const Color(0xFFBBCCDD)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-10 + wipe, -7), 5, pawPaint);
    canvas.drawCircle(Offset(10 - wipe, -7), 5, pawPaint);
  }

  void _drawTears(Canvas canvas) {
    final tearPaint = Paint()..style = PaintingStyle.fill;

    // Wave 1
    final tc1 = elapsed % 1.0;
    final ty1 = tc1 * 22.0;
    final to1 = (1.0 - tc1).clamp(0.0, 1.0);
    tearPaint.color = Color.fromRGBO(136, 204, 255, to1 * 0.7);
    canvas.drawOval(Rect.fromCenter(center: Offset(-10, -2 + ty1), width: 3, height: 4 + tc1 * 2), tearPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(10, -2 + ty1), width: 3, height: 4 + tc1 * 2), tearPaint);

    // Wave 2
    final tc2 = (elapsed + 0.33) % 1.0;
    final ty2 = tc2 * 22.0;
    final to2 = (1.0 - tc2).clamp(0.0, 1.0);
    tearPaint.color = Color.fromRGBO(136, 204, 255, to2 * 0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(-12, -1 + ty2), width: 2.5, height: 3.5 + tc2 * 2), tearPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(12, -1 + ty2), width: 2.5, height: 3.5 + tc2 * 2), tearPaint);

    // Wave 3
    final tc3 = (elapsed + 0.66) % 1.0;
    final ty3 = tc3 * 22.0;
    final to3 = (1.0 - tc3).clamp(0.0, 1.0);
    tearPaint.color = Color.fromRGBO(136, 204, 255, to3 * 0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset(-8, -2 + ty3), width: 2, height: 3 + tc3 * 2), tearPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(8, -2 + ty3), width: 2, height: 3 + tc3 * 2), tearPaint);

    // Wave 4
    final tc4 = (elapsed + 0.5) % 1.0;
    final ty4 = tc4 * 22.0;
    final to4 = (1.0 - tc4).clamp(0.0, 1.0);
    tearPaint.color = Color.fromRGBO(150, 220, 255, to4 * 0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(-11, 0 + ty4), width: 2, height: 3 + tc4 * 1.5), tearPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(11, 0 + ty4), width: 2, height: 3 + tc4 * 1.5), tearPaint);
  }

  @override
  bool shouldRepaint(_SadCatPainter oldDelegate) => true;
}
