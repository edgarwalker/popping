import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'bubble.dart';
import 'level_config.dart';

class PoppingGame extends FlameGame with HasCollisionDetection, PanDetector {
  final Random _random = Random();

  double _spawnTimer = 0.0;
  double elapsedTime = 0.0; // total game time in seconds
  int _score = 0;
  int _currentLevel = 0; // index into levels list (0–6)
  int _mode = 0; // 0: Level, 1: Score, 2: Adventure
  int adventureTarget = 1000; // target score for adventure mode
  double volume = 4.0 / 7.0; // 0.0 to 1.0
  bool _adventureComplete = false;
  bool _gameOverTriggered = false;

  // Audio - lazy loaded
  bool _audioReady = false;
  AudioPool? _popPool;
  AudioPool? _crashPool;

  bool _paused = false;
  double _pauseTimer = 0.0;
  static const double _pauseDuration = 2.0;

  /// Callback to notify Flutter UI of score changes.
  void Function(int score)? onScoreUpdate;

  /// Callback to notify Flutter UI of level changes (adventure mode).
  void Function(int level)? onLevelUpdate;

  /// Callback to notify Flutter UI of game over (level mode).
  void Function()? onGameOver;

  /// Callback to notify Flutter UI of time updates (adventure mode).
  void Function(double elapsed)? onTimeUpdate;

  void setMode(int mode) {
    _mode = mode;
    _score = 0;
    _adventureComplete = false;
    onScoreUpdate?.call(_score);
    // Remove "Well Done !" text if present
    children.whereType<TextComponent>().toList().forEach(
      (t) => t.removeFromParent(),
    );
    if (_mode == 2) {
      // Adventure starts at level 1
      _currentLevel = 0;
      onLevelUpdate?.call(_currentLevel);
    }
  }

  void resetAdventure() {
    _score = 0;
    _adventureComplete = false;
    _paused = false;
    _pauseTimer = 0.0;
    _spawnTimer = 0.0;
    _currentLevel = 0;
    onScoreUpdate?.call(_score);
    onLevelUpdate?.call(_currentLevel);
    // Remove all bubbles and "Well Done !" text
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
    children.whereType<TextComponent>().toList().forEach(
      (t) => t.removeFromParent(),
    );
    _spawnBubble();
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

    // Draw swipe trail as lightning bolt
    if (_trailPoints.length >= 2) {
      final glowPaint =
          Paint()
            ..strokeWidth = 6.0
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
      final corePaint =
          Paint()
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      for (int i = 1; i < _trailPoints.length; i++) {
        final prev = _trailPoints[i - 1];
        final curr = _trailPoints[i];
        final opacity = (1.0 - curr.age / _trailFadeDuration).clamp(0.0, 1.0);

        final dx = curr.position.x - prev.position.x;
        final dy = curr.position.y - prev.position.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len < 1) continue;

        final nx = -dy / len;
        final ny = dx / len;
        final jagAmount =
            (i % 2 == 0 ? 1 : -1) * (3.0 + (i * 7 % 5).toDouble());
        final midX = (prev.position.x + curr.position.x) / 2 + nx * jagAmount;
        final midY = (prev.position.y + curr.position.y) / 2 + ny * jagAmount;

        final path =
            Path()
              ..moveTo(prev.position.x, prev.position.y)
              ..lineTo(midX, midY)
              ..lineTo(curr.position.x, curr.position.y);

        glowPaint.color = Color.fromRGBO(68, 136, 255, opacity * 0.4);
        canvas.drawPath(path, glowPaint);

        corePaint.color = Color.fromRGBO(255, 255, 255, opacity * 0.9);
        canvas.drawPath(path, corePaint);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    // Add screen boundary so bubbles can collide with edges
    add(ScreenHitbox());
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
        if (!_adventureComplete && !_gameOverTriggered) {
          _restartGame();
        }
      }
      return;
    }

    if (_adventureComplete) return;

    // Track elapsed time for adventure mode
    if (_mode == 2) {
      final prevSecond = elapsedTime.toInt();
      elapsedTime += dt;
      if (elapsedTime.toInt() != prevSecond) {
        onTimeUpdate?.call(elapsedTime);
      }
      // Time limit: 24 hours (86400 seconds)
      if (elapsedTime >= 86400 && _score < adventureTarget) {
        _adventureComplete = true;
        onGameOver?.call();
        return;
      }
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
    HapticFeedback.lightImpact();
    _playPop();
    if (_mode == 2) {
      // Adventure mode: +1, check if target reached
      _score++;
      if (_score >= adventureTarget) {
        _score = adventureTarget;
        onScoreUpdate?.call(_score);
        _onAdventureComplete();
        return;
      }
      onScoreUpdate?.call(_score);
      _updateAdventureLevel();
    } else {
      _score++;
      onScoreUpdate?.call(_score);
    }
  }

  void _onAdventureComplete() {
    // Game done — stop spawning, pop all bubbles silently
    _adventureComplete = true;
    _paused = true;
    _pauseTimer = 0.0;
    for (final bubble in children.whereType<Bubble>().toList()) {
      if (!bubble.isPopping) {
        bubble.popSilent();
      }
    }

    // Show "Well Done !" at center
    add(
      TextComponent(
        text: 'Well Done !',
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        priority: 100,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// In adventure mode, divide target into 7 parts.
  /// Score 0..part1 uses level 1 config, part1..part2 uses level 2, etc.
  void _updateAdventureLevel() {
    final partSize = adventureTarget ~/ 7;
    int newLevel;
    if (partSize <= 0) {
      newLevel = 6; // fallback to max level
    } else {
      newLevel = (_score ~/ partSize).clamp(0, 6);
    }
    if (newLevel != _currentLevel) {
      _currentLevel = newLevel;
      onLevelUpdate?.call(_currentLevel);
    }
  }

  void onBubblePoppedByCollision() {
    HapticFeedback.heavyImpact();
    _playCrash();
    if (_mode == 1 || _mode == 2) {
      // Score/Adventure mode: -1 per bubble popped by collision, no game reset
      _score -= 1;
      onScoreUpdate?.call(_score);
      if (_mode == 2) {
        _updateAdventureLevel();
      }
    } else {
      // Level mode: game over on first collision call
      if (!_paused) {
        _paused = true;
        _pauseTimer = 0.0;
        _gameOverTriggered = true;
        _score = 0;
        onScoreUpdate?.call(_score);

        // Pop all remaining active bubbles so user sees the animation
        for (final bubble in children.whereType<Bubble>().toList()) {
          if (!bubble.isPopping) {
            bubble.popSilent();
          }
        }

        // Notify UI to show Start Game screen after animation
        Future.delayed(const Duration(milliseconds: 600), () {
          onGameOver?.call();
        });
      }
    }
  }

  void _restartGame() {
    _spawnTimer = 0.0;
    _spawnBubble();
  }

  /// Start a fresh game immediately (no pause delay).
  void startImmediately() {
    _paused = false;
    _pauseTimer = 0.0;
    _spawnTimer = 0.0;
    elapsedTime = 0.0;
    _adventureComplete = false;
    _gameOverTriggered = false;
    _score = 0;
    onScoreUpdate?.call(_score);
    // Clear swipe state
    _lastDragPoint = null;
    _trailPoints.clear();
    // Remove all existing bubbles and text
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
    children.whereType<TextComponent>().toList().forEach(
      (t) => t.removeFromParent(),
    );
    // Resume Flame engine
    paused = false;
    // Lazy init audio on first start
    if (!_audioReady) _initAudio();
    _spawnBubble();
  }

  Future<void> _initAudio() async {
    _audioReady = true;
    try {
      _popPool = await FlameAudio.createPool('pop.wav', maxPlayers: 3);
      _crashPool = await FlameAudio.createPool('crash.wav', maxPlayers: 2);
    } catch (_) {}
  }

  void _playPop() {
    if (volume <= 0) return;
    try {
      _popPool?.start(volume: volume * 0.5);
    } catch (_) {}
  }

  void _playCrash() {
    if (volume <= 0) return;
    try {
      _crashPool?.start(volume: volume * 0.7);
    } catch (_) {}
  }

  /// Clear all game state without starting (for waiting screen).
  void clearState() {
    _paused = true;
    _pauseTimer = 0.0;
    _spawnTimer = 0.0;
    elapsedTime = 0.0;
    _adventureComplete = false;
    _gameOverTriggered = false;
    _score = 0;
    onScoreUpdate?.call(_score);
    _lastDragPoint = null;
    _trailPoints.clear();
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
    children.whereType<TextComponent>().toList().forEach(
      (t) => t.removeFromParent(),
    );
    paused = true;
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
