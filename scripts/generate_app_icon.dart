// ignore_for_file: avoid_print
/// Generates an app icon from the broken_bubble.png with a solid background.
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
    const double bubbleRadius = 160.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Solid dark gradient background (matches game feel)
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2D1B4E), Color(0xFF0D0D1A)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
      bgPaint,
    );

    // Generate colorful pop particles (same as broken_bubble.png but larger)
    final random = Random(42);
    final particles = <_PopParticle>[];

    final colors = [
      HSLColor.fromAHSL(1.0, 200, 0.95, 0.70).toColor(), // cyan
      HSLColor.fromAHSL(1.0, 320, 0.95, 0.70).toColor(), // pink
      HSLColor.fromAHSL(1.0, 55, 0.95, 0.65).toColor(),  // gold
      HSLColor.fromAHSL(1.0, 140, 0.90, 0.60).toColor(), // green
      HSLColor.fromAHSL(1.0, 270, 0.90, 0.70).toColor(), // purple
      HSLColor.fromAHSL(1.0, 30, 0.95, 0.65).toColor(),  // orange
    ];

    // 36 circular particles radiating outward
    for (int i = 0; i < 36; i++) {
      final angle = (i / 36) * 2 * pi + random.nextDouble() * 0.2;
      final baseColor = colors[i % colors.length];
      final particleColor = Color.lerp(
        baseColor,
        colors[(i + 2) % colors.length],
        random.nextDouble() * 0.3,
      )!;
      particles.add(
        _PopParticle(
          angle: angle,
          distance: bubbleRadius + random.nextDouble() * 120.0,
          size: 10.0 + random.nextDouble() * 16.0,
          color: particleColor,
        ),
      );
    }

    // Add extra smaller sparkle particles for richness
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final baseColor = colors[random.nextInt(colors.length)];
      particles.add(
        _PopParticle(
          angle: angle,
          distance: bubbleRadius * 0.6 + random.nextDouble() * 80.0,
          size: 6.0 + random.nextDouble() * 10.0,
          color: baseColor.withValues(alpha: 0.8),
        ),
      );
    }

    // Render at 25% progress
    const progress = 0.25;
    const opacity = 1.0 - progress;
    const progressSpeed = progress * 1.0;
    const sizeScale = 1.0 - progress * 0.5;

    final centerX = imageSize / 2.0;
    final centerY = imageSize / 2.0;

    final paint = Paint();
    final opacityInt = (opacity * 255).toInt();

    for (final particle in particles) {
      final dx = centerX + particle.cosAngle * particle.distance * progressSpeed;
      final dy = centerY + particle.sinAngle * particle.distance * progressSpeed;
      final particleSize = particle.size * sizeScale;

      final a = ((particle.alpha * opacityInt) ~/ 1).clamp(0, 255);
      paint.color = Color.fromARGB(a, particle.r, particle.g, particle.b);

      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
    }

    // Add a subtle glow in the center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: 80));
    canvas.drawCircle(Offset(centerX, centerY), 80, glowPaint);

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
  })  : cosAngle = cos(angle),
        sinAngle = sin(angle),
        r = (color.r * 255.0).round().clamp(0, 255),
        g = (color.g * 255.0).round().clamp(0, 255),
        b = (color.b * 255.0).round().clamp(0, 255),
        alpha = color.a;
}
