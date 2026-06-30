// ignore_for_file: avoid_print
/// Generates an app icon from the broken bubble with a white background.
///
/// Run with:
///   flutter test scripts/generate_app_icon.dart
///
/// Output: assets/app_icon.png (1024x1024 for App Store / Play Store)

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate app icon', () async {
    const int imageSize = 1024;
    const double bubbleRadius = 80.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
      Paint()..color = Colors.white,
    );

    // Generate colorful pop particles — fewer but big
    final random = Random(42);
    final particles = <_PopParticle>[];

    final colors = [
      HSLColor.fromAHSL(1.0, 200, 0.95, 0.55).toColor(), // cyan
      HSLColor.fromAHSL(1.0, 320, 0.95, 0.55).toColor(), // pink
      HSLColor.fromAHSL(1.0, 55, 0.95, 0.50).toColor(), // gold
      HSLColor.fromAHSL(1.0, 140, 0.90, 0.45).toColor(), // green
      HSLColor.fromAHSL(1.0, 270, 0.90, 0.55).toColor(), // purple
      HSLColor.fromAHSL(1.0, 30, 0.95, 0.55).toColor(), // orange
    ];

    // Outer ring — 16 particles
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi + random.nextDouble() * 0.2;
      final baseColor = colors[i % colors.length];
      final particleColor =
          Color.lerp(
            baseColor,
            colors[(i + 2) % colors.length],
            random.nextDouble() * 0.3,
          )!;
      particles.add(
        _PopParticle(
          angle: angle,
          distance: bubbleRadius + random.nextDouble() * 600.0,
          size: 55.0 + random.nextDouble() * 80.0,
          color: particleColor,
        ),
      );
    }

    // Inner ring — 12 particles
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + random.nextDouble() * 0.3;
      final baseColor = colors[(i + 3) % colors.length];
      final particleColor =
          Color.lerp(
            baseColor,
            colors[(i + 1) % colors.length],
            random.nextDouble() * 0.4,
          )!;
      particles.add(
        _PopParticle(
          angle: angle,
          distance: bubbleRadius * 0.3 + random.nextDouble() * 400.0,
          size: 40.0 + random.nextDouble() * 65.0,
          color: particleColor,
        ),
      );
    }

    // Render at 60% progress so particles fill the icon area
    const progress = 0.60;
    const progressSpeed = progress * 1.0;

    final centerX = imageSize / 2.0;
    final centerY = imageSize / 2.0;

    final paint = Paint();

    for (final particle in particles) {
      final dx =
          centerX + particle.cosAngle * particle.distance * progressSpeed;
      final dy =
          centerY + particle.sinAngle * particle.distance * progressSpeed;
      final particleSize = particle.size;

      final a = (particle.alpha * 255).toInt().clamp(0, 255);
      paint.color = Color.fromARGB(a, particle.r, particle.g, particle.b);

      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      fail('Failed to encode image to PNG');
    }

    final outputPath = '${Directory.current.path}/assets/app_icon.png';
    final file = File(outputPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    print('Generated app icon: $outputPath');
    print('Image size: ${imageSize}x$imageSize');
  });
}

class _PopParticle {
  final double cosAngle;
  final double sinAngle;
  final double distance;
  final double size;
  final int r;
  final int g;
  final int b;
  final double alpha;

  _PopParticle({
    required double angle,
    required this.distance,
    required this.size,
    required Color color,
  }) : cosAngle = cos(angle),
       sinAngle = sin(angle),
       r = (color.r * 255.0).round().clamp(0, 255),
       g = (color.g * 255.0).round().clamp(0, 255),
       b = (color.b * 255.0).round().clamp(0, 255),
       alpha = color.a;
}
