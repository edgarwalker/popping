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
  bool get isGameOver => _gameOverTriggered;

  // Audio - lazy loaded
  bool _audioReady = false;
  AudioPool? _popPool;
  AudioPool? _crashPool;

  bool _paused = false;
  double _pauseTimer = 0.0;
  static const double _pauseDuration = 2.0;

  // Game-over lightning bolt effect
  bool _gameOverLightningActive = false;
  double _gameOverLightningElapsed = 0.0;
  static const double _gameOverLightningDuration = 2.0; // seconds
  List<List<Offset>> _gameOverBolts = [];

  // Reusable paint objects for trail rendering
  final Paint _trailGlowPaint =
      Paint()
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
  final Paint _trailCorePaint =
      Paint()
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

  // Reusable paint objects for game-over lightning
  final Paint _boltGlowPaint =
      Paint()
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
  final Paint _boltCorePaint =
      Paint()
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

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

    // Draw game-over lightning bolts
    if (_gameOverLightningActive && _gameOverBolts.isNotEmpty) {
      final progress = (_gameOverLightningElapsed / _gameOverLightningDuration)
          .clamp(0.0, 1.0);
      final opacity = 1.0 - progress;

      final glowPaint = _boltGlowPaint;
      final corePaint = _boltCorePaint;

      for (final bolt in _gameOverBolts) {
        if (bolt.length < 2) continue;

        final path = Path()..moveTo(bolt[0].dx, bolt[0].dy);
        for (int i = 1; i < bolt.length; i++) {
          path.lineTo(bolt[i].dx, bolt[i].dy);
        }

        glowPaint.color = Color.fromRGBO(255, 60, 60, opacity * 0.6);
        canvas.drawPath(path, glowPaint);

        corePaint.color = Color.fromRGBO(255, 255, 255, opacity * 0.95);
        canvas.drawPath(path, corePaint);
      }
    }

    // Draw swipe trail as lightning bolt
    if (_trailPoints.length >= 2) {
      final glowPaint = _trailGlowPaint;
      final corePaint = _trailCorePaint;

      for (int i = 1; i < _trailPoints.length; i++) {
        final prev = _trailPoints[i - 1];
        final curr = _trailPoints[i];
        final opacity = (1.0 - curr.age / _trailFadeDuration).clamp(0.0, 1.0);

        final dx = curr.position.x - prev.position.x;
        final dy = curr.position.y - prev.position.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len < 1) continue;

        final invLen = 1.0 / len;
        final nx = -dy * invLen;
        final ny = dx * invLen;
        final jagAmount =
            (i % 2 == 0 ? 1 : -1) * (3.0 + (i * 7 % 5).toDouble());
        final midX = (prev.position.x + curr.position.x) * 0.5 + nx * jagAmount;
        final midY = (prev.position.y + curr.position.y) * 0.5 + ny * jagAmount;

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

    // Update game-over lightning animation
    if (_gameOverLightningActive) {
      _gameOverLightningElapsed += dt;
      if (_gameOverLightningElapsed >= _gameOverLightningDuration) {
        _gameOverLightningActive = false;
        _gameOverBolts = [];
      }
    }

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
    if (_gameOverTriggered) return;

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
      // Count active bubbles without allocating a list
      int activeBubbles = 0;
      for (final child in children) {
        if (child is Bubble && !child.isPopping) activeBubbles++;
      }
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

    // Try to find a valid position (max attempts to avoid infinite loop)
    Vector2? spawnPos;
    for (int attempt = 0; attempt < 50; attempt++) {
      final x = margin + _random.nextDouble() * (size.x - margin * 2);
      final y = margin + _random.nextDouble() * (size.y - margin * 2);
      final candidateX = x;
      final candidateY = y;

      bool tooClose = false;
      for (final child in children) {
        if (child is Bubble && !child.isPopping) {
          // Edge-to-edge distance must be at least minGap
          final minDistance = child.radius + spawnRadius + minGap;
          final dx = candidateX - child.position.x;
          final dy = candidateY - child.position.y;
          if (dx * dx + dy * dy < minDistance * minDistance) {
            tooClose = true;
            break;
          }
        }
      }

      if (!tooClose) {
        spawnPos = Vector2(candidateX, candidateY);
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

        // Trigger lightning bolt effect from edges to center
        _startGameOverLightning();

        // Keep all bubbles frozen in place (don't pop them)
        // They will be cleared when the player starts a new game

        // Notify UI to show Start Game screen after 2 seconds
        Future.delayed(const Duration(milliseconds: 2000), () {
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
    _gameOverLightningActive = false;
    _gameOverBolts = [];
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

  /// Generate jagged lightning bolt points from `start` to `end`.
  List<Offset> _generateBoltPath(Offset start, Offset end, int segments) {
    final points = <Offset>[start];
    final random = _random;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return points;

    final invLen = 1.0 / len;
    // Perpendicular direction
    final nx = -dy * invLen;
    final ny = dx * invLen;

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final baseX = start.dx + dx * t;
      final baseY = start.dy + dy * t;
      // Jag perpendicular to the line, scaled by total length
      final jag = (random.nextDouble() - 0.5) * len * 0.12;
      points.add(Offset(baseX + nx * jag, baseY + ny * jag));
    }
    points.add(end);
    return points;
  }

  /// Start the game-over lightning effect.
  void _startGameOverLightning() {
    _gameOverLightningActive = true;
    _gameOverLightningElapsed = 0.0;

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final center = Offset(centerX, centerY);

    // 4 edge midpoints: top, bottom, left, right
    final edgeMidpoints = [
      Offset(centerX, 0), // top
      Offset(centerX, size.y), // bottom
      Offset(0, centerY), // left
      Offset(size.x, centerY), // right
    ];

    _gameOverBolts = [];
    for (final edgePoint in edgeMidpoints) {
      _gameOverBolts.add(_generateBoltPath(edgePoint, center, 12));
    }
  }

  /// Clear all game state without starting (for waiting screen).
  void clearState() {
    _paused = true;
    _pauseTimer = 0.0;
    _spawnTimer = 0.0;
    elapsedTime = 0.0;
    _adventureComplete = false;
    _gameOverTriggered = false;
    _gameOverLightningActive = false;
    _gameOverBolts = [];
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
    for (final child in children) {
      if (child is Bubble && !child.isPopping) {
        final dx = point.x - child.position.x;
        final dy = point.y - child.position.y;
        final r = child.radius;
        if (dx * dx + dy * dy <= r * r) {
          child.pop();
        }
      }
    }
  }

  void _checkSwipeLine(Vector2 from, Vector2 to) {
    // Pre-compute line segment values once
    final segDx = to.x - from.x;
    final segDy = to.y - from.y;
    final a = segDx * segDx + segDy * segDy;
    if (a < 0.0001) return; // degenerate segment
    final invA2 = 1.0 / (2 * a);

    for (final child in children) {
      if (child is Bubble && !child.isPopping) {
        // Inline line-circle intersection (avoids Vector2 allocations)
        final fx = from.x - child.position.x;
        final fy = from.y - child.position.y;
        final r = child.radius;

        final b = 2 * (fx * segDx + fy * segDy);
        final cVal = fx * fx + fy * fy - r * r;

        final discriminant = b * b - 4 * a * cVal;
        if (discriminant < 0) continue;

        final sqrtDisc = sqrt(discriminant);
        final t1 = (-b - sqrtDisc) * invA2;
        final t2 = (-b + sqrtDisc) * invA2;

        if ((t1 >= 0 && t1 <= 1) || (t2 >= 0 && t2 <= 1)) {
          child.pop();
        }
      }
    }
  }
}

class _TrailPoint {
  final Vector2 position;
  double age = 0.0;

  _TrailPoint({required this.position});
}
