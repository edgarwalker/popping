import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'popping_game.dart';

class Bubble extends CircleComponent
    with HasGameReference<PoppingGame>, CollisionCallbacks, TapCallbacks {
  Bubble({required Vector2 position, double? growthDuration})
    : _growthDuration = growthDuration ?? 3.0,
      super(position: position, radius: _initialRadius, anchor: Anchor.center);

  static const double _initialRadius = 25.0;
  static const double initialRadius = _initialRadius;
  static const double _maxRadius = 80.0;

  final double _growthDuration;
  double _elapsed = 0.0;
  bool _popping = false;
  bool _crashedByCollision = false;
  double _popRadius = 0.0;

  bool get isPopping => _popping;

  // Pop particles
  final List<_PopParticle> _particles = [];
  double _popElapsed = 0.0;
  static const double _popDuration = 1.0;

  late Color _color;
  late Color _colorInner;
  late Color _colorOuter;

  // Reusable paint for particle rendering — avoids allocation per frame
  final Paint _particlePaint = Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = Random();
    _color =
        HSLColor.fromAHSL(
          1.0,
          random.nextDouble() * 360,
          0.9 + random.nextDouble() * 0.1,
          0.7 + random.nextDouble() * 0.15,
        ).toColor();

    _colorInner = _color.withValues(alpha: 1.0);
    _colorOuter = _color.withValues(alpha: 0.7);

    paint =
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xBBFFFFFF), _colorInner, _colorOuter],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: _initialRadius),
          );

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_popping) {
      _popElapsed += dt;
      if (_popElapsed >= _popDuration) {
        removeFromParent();
      }
      return;
    }

    // Stop growth if game is over (but popping animation above still runs)
    if (game.isGameOver) return;

    // Grow the bubble continuously from center
    _elapsed += dt;
    final newRadius =
        _initialRadius +
        (_elapsed / _growthDuration) * (_maxRadius - _initialRadius);

    // Only update shader when radius changes noticeably (every ~2px)
    if ((newRadius - radius).abs() > 2.0) {
      radius = newRadius;
      paint.shader = RadialGradient(
        colors: [const Color(0xBBFFFFFF), _colorInner, _colorOuter],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    } else {
      radius = newRadius;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_popping) {
      _renderParticles(canvas);
    } else {
      super.render(canvas);
    }
  }

  void _renderParticles(Canvas canvas) {
    final duration = _crashedByCollision ? _popDuration * 1.2 : _popDuration;
    final progress = (_popElapsed / duration).clamp(0.0, 1.0);
    final opacity = 1.0 - progress;
    final speed = _crashedByCollision ? 1.5 : 1.0;
    final progressSpeed = progress * speed;
    final sizeScale = 1.0 - progress * 0.5;

    final centerX = _popRadius;
    final centerY = _popRadius;

    final paint = _particlePaint;
    final opacityInt = (opacity * 255).toInt();

    if (_crashedByCollision) {
      for (int i = 0; i < _particles.length; i++) {
        final particle = _particles[i];
        final dx =
            centerX + particle.cosAngle * particle.distance * progressSpeed;
        final dy =
            centerY + particle.sinAngle * particle.distance * progressSpeed;
        final particleSize = particle.size * sizeScale;

        final a = ((particle.alpha * opacityInt) ~/ 1).clamp(0, 255);
        paint.color = Color.fromARGB(a, particle.r, particle.g, particle.b);

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(dx, dy),
            width: particleSize,
            height: particleSize,
          ),
          paint,
        );
      }
    } else {
      for (int i = 0; i < _particles.length; i++) {
        final particle = _particles[i];
        final dx =
            centerX + particle.cosAngle * particle.distance * progressSpeed;
        final dy =
            centerY + particle.sinAngle * particle.distance * progressSpeed;
        final particleSize = particle.size * sizeScale;

        final a = ((particle.alpha * opacityInt) ~/ 1).clamp(0, 255);
        paint.color = Color.fromARGB(a, particle.r, particle.g, particle.b);

        canvas.drawCircle(Offset(dx, dy), particleSize, paint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_popping && !game.isGameOver) {
      _pop();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_popping) return;
    if (game.isGameOver) return;

    if (other is Bubble && !other._popping) {
      // Crash both bubbles first (set animation), then notify game
      _crashPop();
      other._crashPop();
      game.onBubblePoppedByCollision();
    }
    // Screen edge collisions are ignored — bubbles can touch edges freely
  }

  void _pop() {
    if (_popping) return;
    _popping = true;
    _popElapsed = 0.0;
    _popRadius = radius;
    _generateParticles();
    game.onBubblePopped();
  }

  /// Public method to pop this bubble (used by swipe detection).
  void pop() => _pop();

  /// Pop without adding score (used for game-over animation).
  void popSilent() {
    if (_popping) return;
    _popping = true;
    _popElapsed = 0.0;
    _popRadius = radius;
    _generateParticles();
  }

  /// Crash animation only — no game notification.
  void _crashPop() {
    if (_popping) return;
    _popping = true;
    _crashedByCollision = true;
    _popElapsed = 0.0;
    _popRadius = radius;
    _generateCrashParticles();
    // Vibrate on crash
    HapticFeedback.vibrate();
  }

  void _generateParticles() {
    final random = Random();
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi + random.nextDouble() * 0.2;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius + random.nextDouble() * 60.0,
          size: 5.0 + random.nextDouble() * 8.0,
          color: _color,
        ),
      );
    }
  }

  void _generateCrashParticles() {
    final random = Random();
    // Main fragments — fresh and vibrant
    for (int i = 0; i < 70; i++) {
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius * 0.5 + random.nextDouble() * 130.0,
          size: 6.0 + random.nextDouble() * 12.0,
          color:
              Color.lerp(
                _color,
                const Color(0xFFFFCCDD),
                0.25 + random.nextDouble() * 0.3,
              )!,
        ),
      );
    }
    // Bright sparks — fresh mint/cyan/yellow
    for (int i = 0; i < 25; i++) {
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius + random.nextDouble() * 90.0,
          size: 8.0 + random.nextDouble() * 10.0,
          color:
              Color.lerp(
                const Color(0xFF88FFDD),
                const Color(0xFFFFFFAA),
                random.nextDouble(),
              )!,
        ),
      );
    }
  }
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
