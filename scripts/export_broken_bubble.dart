// ignore_for_file: avoid_print
/// Renders the "broken bubble" (normal pop particle explosion) to a PNG file.
///
/// This is the regular bubble pop (circular particles radiating outward),
/// NOT the crash/collision pop (which uses square particles).
///
/// Run with:
///   flutter test scripts/export_broken_bubble.dart
///
/// Output: assets/broken_bubble.png

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Export broken bubble to PNG', () async {
    const int imageSize = 512;
    const double bubbleRadius = 80.0;

    // Create the picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
      Paint()..color = Colors.transparent,
    );

    // Generate normal pop particles (matching _generateParticles logic)
    final random = Random(42); // fixed seed for reproducibility
    final particles = <_PopParticle>[];

    // Multiple vibrant colors for a colorful explosion
    final colors = [
      HSLColor.fromAHSL(1.0, 200, 0.95, 0.70).toColor(), // cyan
      HSLColor.fromAHSL(1.0, 320, 0.95, 0.70).toColor(), // pink
      HSLColor.fromAHSL(1.0, 55, 0.95, 0.65).toColor(), // gold
      HSLColor.fromAHSL(1.0, 140, 0.90, 0.60).toColor(), // green
      HSLColor.fromAHSL(1.0, 270, 0.90, 0.70).toColor(), // purple
      HSLColor.fromAHSL(1.0, 30, 0.95, 0.65).toColor(), // orange
    ];

    // 36 circular particles radiating outward with varied colors
    for (int i = 0; i < 36; i++) {
      final angle = (i / 36) * 2 * pi + random.nextDouble() * 0.2;
      final baseColor = colors[i % colors.length];
      // Slightly vary each particle's hue for organic feel
      final particleColor =
          Color.lerp(
            baseColor,
            colors[(i + 2) % colors.length],
            random.nextDouble() * 0.3,
          )!;
      particles.add(
        _PopParticle(
          angle: angle,
          distance: bubbleRadius + random.nextDouble() * 60.0,
          size: 5.0 + random.nextDouble() * 8.0,
          color: particleColor,
        ),
      );
    }

    // Render particles at ~25% animation progress (nice spread, still vivid)
    const progress = 0.25;
    const opacity = 1.0 - progress;
    const speed = 1.0; // normal speed (no crash multiplier)
    const progressSpeed = progress * speed;
    const sizeScale = 1.0 - progress * 0.5;

    final centerX = imageSize / 2.0;
    final centerY = imageSize / 2.0;

    final paint = Paint();
    final opacityInt = (opacity * 255).toInt();

    for (final particle in particles) {
      final dx =
          centerX + particle.cosAngle * particle.distance * progressSpeed;
      final dy =
          centerY + particle.sinAngle * particle.distance * progressSpeed;
      final particleSize = particle.size * sizeScale;

      final a = ((particle.alpha * opacityInt) ~/ 1).clamp(0, 255);
      paint.color = Color.fromARGB(a, particle.r, particle.g, particle.b);

      // Normal pop particles are circles
      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
    }

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      fail('Failed to encode image to PNG');
    }

    // Write to file
    final outputPath = '${Directory.current.path}/assets/broken_bubble.png';
    final file = File(outputPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    print('Exported broken bubble to: $outputPath');
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
