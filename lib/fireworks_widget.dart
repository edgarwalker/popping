import 'dart:math';

import 'package:flutter/widgets.dart';

/// Full-screen fireworks overlay that plays for a set duration.
class FireworksWidget extends StatefulWidget {
  final Duration duration;

  const FireworksWidget({
    super.key,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FireworksWidget> createState() => _FireworksWidgetState();
}

class _FireworksWidgetState extends State<FireworksWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Firework> _fireworks;
  double _elapsed = 0.0;
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    final durationSec = widget.duration.inMilliseconds / 1000.0;
    _fireworks = _generateFireworks(durationSec);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_tick);
  }

  void _tick() {
    final now = _controller.value;
    double dt;
    if (now >= _lastValue) {
      dt = now - _lastValue;
    } else {
      dt = (1.0 - _lastValue) + now;
    }
    _lastValue = now;
    _elapsed += dt;

    // Loop: regenerate fireworks when cycle completes
    final durationSec = widget.duration.inMilliseconds / 1000.0;
    if (_elapsed > durationSec) {
      _elapsed = 0.0;
      _fireworks = _generateFireworks(durationSec);
    }
  }

  List<_Firework> _generateFireworks(double totalDuration) {
    final random = Random();
    final fireworks = <_Firework>[];
    // Stagger fireworks over the duration
    const count = 32;
    for (int i = 0; i < count; i++) {
      final startTime = (i / count) * totalDuration * 0.7;
      final x = 0.15 + random.nextDouble() * 0.7; // 15%-85% of width
      final y = 0.15 + random.nextDouble() * 0.5; // 15%-65% of height

      final particleCount = 20 + random.nextInt(15);
      final hue = random.nextDouble() * 360;
      final particles = <_Particle>[];

      for (int p = 0; p < particleCount; p++) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = 40 + random.nextDouble() * 80;
        final life = 0.6 + random.nextDouble() * 0.6;
        final size = 2.0 + random.nextDouble() * 3.0;
        final particleHue = (hue + (random.nextDouble() - 0.5) * 40) % 360;
        final color = HSLColor.fromAHSL(1.0, particleHue, 0.9, 0.65).toColor();

        particles.add(
          _Particle(
            angle: angle,
            speed: speed,
            life: life,
            size: size,
            colorR: (color.r * 255).round(),
            colorG: (color.g * 255).round(),
            colorB: (color.b * 255).round(),
          ),
        );
      }

      fireworks.add(
        _Firework(x: x, y: y, startTime: startTime, particles: particles),
      );
    }
    return fireworks;
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
            size: Size.infinite,
            painter: _FireworksPainter(
              fireworks: _fireworks,
              elapsed: _elapsed,
            ),
          );
        },
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;
  final double elapsed;

  _FireworksPainter({required this.fireworks, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final fw in fireworks) {
      final t = elapsed - fw.startTime;
      if (t < 0) continue;

      final cx = fw.x * size.width;
      final cy = fw.y * size.height;

      for (final p in fw.particles) {
        if (t > p.life) continue;

        final progress = t / p.life;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        final dist = p.speed * progress;
        // Gravity effect
        final gravity = 30.0 * progress * progress;

        final x = cx + cos(p.angle) * dist;
        final y = cy + sin(p.angle) * dist + gravity;
        final radius = p.size * (1.0 - progress * 0.5);

        paint.color = Color.fromARGB(
          (opacity * 255).toInt(),
          p.colorR,
          p.colorG,
          p.colorB,
        );
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}

class _Firework {
  final double x; // 0-1 fraction of screen width
  final double y; // 0-1 fraction of screen height
  final double startTime;
  final List<_Particle> particles;

  const _Firework({
    required this.x,
    required this.y,
    required this.startTime,
    required this.particles,
  });
}

class _Particle {
  final double angle;
  final double speed;
  final double life;
  final double size;
  final int colorR;
  final int colorG;
  final int colorB;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.life,
    required this.size,
    required this.colorR,
    required this.colorG,
    required this.colorB,
  });
}
