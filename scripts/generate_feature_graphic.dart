// ignore_for_file: avoid_print
/// Generates a 1024x500 feature graphic for Google Play.
///
/// Run with:
///   flutter test scripts/generate_feature_graphic.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate feature graphic', () async {
    const int width = 1024;
    const int height = 500;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Dark gradient background matching game
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D1B4E), Color(0xFF3D3D6B), Color(0xFF0D0D1A)],
      ).createShader(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    // Scatter colorful bubble circles across the graphic
    final random = Random(42);
    final colors = [
      HSLColor.fromAHSL(1.0, 200, 0.95, 0.70).toColor(),
      HSLColor.fromAHSL(1.0, 320, 0.95, 0.70).toColor(),
      HSLColor.fromAHSL(1.0, 55, 0.95, 0.65).toColor(),
      HSLColor.fromAHSL(1.0, 140, 0.90, 0.60).toColor(),
      HSLColor.fromAHSL(1.0, 270, 0.90, 0.70).toColor(),
      HSLColor.fromAHSL(1.0, 30, 0.95, 0.65).toColor(),
    ];

    final paint = Paint();

    // Draw background bubbles (large, faded)
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final r = 30.0 + random.nextDouble() * 60.0;
      final color = colors[i % colors.length];

      paint.shader = RadialGradient(
        colors: [
          const Color(0x88FFFFFF),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.4),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));

      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Draw pop particles (explosion effect) in the center-right area
    paint.shader = null;
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * pi + random.nextDouble() * 0.3;
      final dist = 40.0 + random.nextDouble() * 80.0;
      final x = 700 + cos(angle) * dist;
      final y = 250 + sin(angle) * dist;
      final size = 8.0 + random.nextDouble() * 12.0;
      final color = colors[i % colors.length];
      paint.color = color;
      canvas.drawCircle(Offset(x, y), size, paint);
    }

    // Draw "Popping" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Popping',
        style: TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      fail('Failed to encode image');
    }

    final outputPath = '${Directory.current.path}/assets/feature_graphic.png';
    final file = File(outputPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    print('Generated feature graphic: $outputPath');
    print('Size: ${width}x$height');
  });
}
