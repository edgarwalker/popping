import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import 'bubble.dart';
import 'level_config.dart';

class PoppingGame extends FlameGame with HasCollisionDetection, PanDetector {
  final Random _random = Random();

  double _spawnTimer = 0.0;
  int _score = 0;
  int _currentLevel = 0; // index into levels list (0–6)
  int _mode = 0; // 0: Level, 1: Score, 2: Adventure

  bool _paused = false;
  double _pauseTimer = 0.0;
  static const double _pauseDuration = 2.0;

  /// Callback to notify Flutter UI of score changes.
  void Function(int score)? onScoreUpdate;

  void setMode(int mode) {
    _mode = mode;
    _score = 0;
    onScoreUpdate?.call(_score);
  }

  LevelConfig get currentLevelConfig => levels[_currentLevel];

  void setLevel(int levelIndex) {
    _currentLevel = levelIndex.clamp(0, levels.length - 1);

    // Clear bubbles and pause 1 second before starting the new level
    _score = 0;
    onScoreUpdate?.call(_score);
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
    _paused = true;
    _pauseTimer = 0.0;
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw swipe trail
    if (_trailPoints.length >= 2) {
      for (int i = 1; i < _trailPoints.length; i++) {
        final prev = _trailPoints[i - 1];
        final curr = _trailPoints[i];
        final opacity = (1.0 - curr.age / _trailFadeDuration).clamp(0.0, 1.0);
        final paint =
            Paint()
              ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.8)
              ..strokeWidth = 3.0
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(prev.position.x, prev.position.y),
          Offset(curr.position.x, curr.position.y),
          paint,
        );
      }
    }
  }

  @override
  Future<void> onLoad() async {
    // Add screen boundary so bubbles can collide with edges
    add(ScreenHitbox());

    // Spawn first bubble
    _spawnBubble();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update trail points
    for (final point in _trailPoints) {
      point.age += dt;
    }
    _trailPoints.removeWhere((p) => p.age >= _trailFadeDuration);

    if (_paused) {
      _pauseTimer += dt;
      if (_pauseTimer >= _pauseDuration) {
        _paused = false;
        _pauseTimer = 0.0;
        _restartGame();
      }
      return;
    }

    _spawnTimer += dt;
    if (_spawnTimer >= currentLevelConfig.spawnInterval) {
      _spawnTimer = 0.0;
      // Spawn one bubble per tick
      final activeBubbles =
          children.whereType<Bubble>().where((b) => !b.isPopping).length;
      if (activeBubbles < currentLevelConfig.maxBubbles) {
        _spawnBubble();
      }
    }
  }

  void _spawnBubble() {
    // Small margin so bubble center stays on screen
    final margin = Bubble.initialRadius + 5.0;
    // Minimum distance between new bubble center and existing bubble edges
    const spawnRadius = Bubble.initialRadius;
    final minGap = currentLevelConfig.minSpacing;

    // Get all active (non-popping) bubbles
    final existingBubbles =
        children.whereType<Bubble>().where((b) => !b.isPopping).toList();

    // Try to find a valid position (max attempts to avoid infinite loop)
    Vector2? spawnPos;
    for (int attempt = 0; attempt < 50; attempt++) {
      final x = margin + _random.nextDouble() * (size.x - margin * 2);
      final y = margin + _random.nextDouble() * (size.y - margin * 2);
      final candidate = Vector2(x, y);

      bool tooClose = false;
      for (final bubble in existingBubbles) {
        // Edge-to-edge distance must be at least minGap
        final minDistance = bubble.radius + spawnRadius + minGap;
        if (candidate.distanceTo(bubble.position) < minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        spawnPos = candidate;
        break;
      }
    }

    // Only spawn if minimum distance is satisfied
    if (spawnPos != null) {
      final baseSpeed = currentLevelConfig.growthSpeed;
      // Add slight randomness (±15%) around the level's growth speed
      final growthDuration = baseSpeed * (0.85 + _random.nextDouble() * 0.30);
      add(Bubble(position: spawnPos, growthDuration: growthDuration));
    }
  }

  void onBubblePopped() {
    _score++;
    onScoreUpdate?.call(_score);
  }

  void onBubblePoppedByCollision() {
    if (_mode == 1) {
      // Score mode: -1 per bubble popped by collision, no game reset
      _score -= 1;
      onScoreUpdate?.call(_score);
    } else {
      // Level/Adventure mode: game over on first collision call
      if (!_paused) {
        _paused = true;
        _pauseTimer = 0.0;
        _score = 0;
        onScoreUpdate?.call(_score);

        // Pop all remaining active bubbles so user sees the animation
        for (final bubble in children.whereType<Bubble>().toList()) {
          if (!bubble.isPopping) {
            bubble.pop();
          }
        }
      }
    }
  }

  void _restartGame() {
    _spawnTimer = 0.0;
    _spawnBubble();
  }

  // --- Swipe detection ---

  Vector2? _lastDragPoint;
  final List<_TrailPoint> _trailPoints = [];
  static const double _trailFadeDuration = 0.3; // seconds to fade out

  @override
  void onPanStart(DragStartInfo info) {
    _lastDragPoint = info.eventPosition.global;
    _trailPoints.add(_TrailPoint(position: _lastDragPoint!.clone()));
    _checkSwipeHit(_lastDragPoint!);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final currentPoint = info.eventPosition.global;
    _trailPoints.add(_TrailPoint(position: currentPoint.clone()));
    if (_lastDragPoint != null) {
      _checkSwipeLine(_lastDragPoint!, currentPoint);
    }
    _lastDragPoint = currentPoint;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _lastDragPoint = null;
  }

  void _checkSwipeHit(Vector2 point) {
    final bubbles =
        children.whereType<Bubble>().where((b) => !b.isPopping).toList();
    for (final bubble in bubbles) {
      if (point.distanceTo(bubble.position) <= bubble.radius) {
        bubble.pop();
      }
    }
  }

  void _checkSwipeLine(Vector2 from, Vector2 to) {
    final bubbles =
        children.whereType<Bubble>().where((b) => !b.isPopping).toList();
    for (final bubble in bubbles) {
      if (_lineIntersectsCircle(from, to, bubble.position, bubble.radius)) {
        bubble.pop();
      }
    }
  }

  /// Returns true if line segment (p1→p2) intersects circle at center c with radius r.
  bool _lineIntersectsCircle(Vector2 p1, Vector2 p2, Vector2 c, double r) {
    final d = p2 - p1;
    final f = p1 - c;

    final a = d.dot(d);
    final b = 2 * f.dot(d);
    final cVal = f.dot(f) - r * r;

    var discriminant = b * b - 4 * a * cVal;
    if (discriminant < 0) return false;

    discriminant = sqrt(discriminant);

    final t1 = (-b - discriminant) / (2 * a);
    final t2 = (-b + discriminant) / (2 * a);

    // Check if either intersection point is within the segment [0, 1]
    if (t1 >= 0 && t1 <= 1) return true;
    if (t2 >= 0 && t2 <= 1) return true;

    return false;
  }
}

class _TrailPoint {
  final Vector2 position;
  double age = 0.0;

  _TrailPoint({required this.position});
}
