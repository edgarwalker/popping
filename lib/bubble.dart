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
  static const double _popDuration = 0.5;

  late Color _color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = Random();
    _color =
        HSLColor.fromAHSL(
          1.0,
          random.nextDouble() * 360,
          0.4 + random.nextDouble() * 0.6,
          0.3 + random.nextDouble() * 0.6,
        ).toColor();

    paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              _color.withValues(alpha: 0.9),
              _color.withValues(alpha: 0.3),
            ],
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

    // Grow the bubble continuously from center
    _elapsed += dt;
    radius =
        _initialRadius +
        (_elapsed / _growthDuration) * (_maxRadius - _initialRadius);

    // Update shader for new size
    paint.shader = RadialGradient(
      colors: [_color.withValues(alpha: 0.9), _color.withValues(alpha: 0.3)],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
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
    final duration = _crashedByCollision ? _popDuration * 0.7 : _popDuration;
    final progress = (_popElapsed / duration).clamp(0.0, 1.0);
    final opacity = 1.0 - progress;

    final centerX = _popRadius;
    final centerY = _popRadius;

    for (final particle in _particles) {
      final speed = _crashedByCollision ? 1.5 : 1.0;
      final dx =
          centerX + cos(particle.angle) * particle.distance * progress * speed;
      final dy =
          centerY + sin(particle.angle) * particle.distance * progress * speed;
      final particleSize = particle.size * (1.0 - progress * 0.5);

      final paint = Paint()..color = particle.color.withValues(alpha: opacity);

      if (_crashedByCollision) {
        // Draw sharp squares for crash
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(dx, dy),
            width: particleSize,
            height: particleSize,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(dx, dy), particleSize, paint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_popping) {
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
    for (int i = 0; i < 10; i++) {
      final angle = (i / 10) * 2 * pi;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius + random.nextDouble() * 40.0,
          size: 4.0 + random.nextDouble() * 6.0,
          color: _color,
        ),
      );
    }
  }

  void _generateCrashParticles() {
    final random = Random();
    // Many small sharp fragments — explosive burst
    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius * 0.5 + random.nextDouble() * 100.0,
          size: 1.0 + random.nextDouble() * 3.5,
          color:
              Color.lerp(
                _color,
                const Color(0xFFFF3333),
                0.5 + random.nextDouble() * 0.3,
              )!,
        ),
      );
    }
    // Add a few bigger orange/yellow spark pieces
    for (int i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * pi;
      _particles.add(
        _PopParticle(
          angle: angle,
          distance: _popRadius + random.nextDouble() * 50.0,
          size: 4.0 + random.nextDouble() * 4.0,
          color:
              Color.lerp(
                const Color(0xFFFF8800),
                const Color(0xFFFFFF00),
                random.nextDouble(),
              )!,
        ),
      );
    }
  }
}

class _PopParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _PopParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}
