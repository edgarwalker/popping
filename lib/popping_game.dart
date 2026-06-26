import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import 'bubble.dart';
import 'level_config.dart';

class PoppingGame extends FlameGame with HasCollisionDetection {
  final Random _random = Random();

  double _spawnTimer = 0.0;
  int _score = 0;
  int _currentLevel = 0; // index into levels list (0–6)

  bool _paused = false;
  double _pauseTimer = 0.0;
  static const double _pauseDuration = 1.0;

  late TextComponent _scoreText;

  LevelConfig get currentLevelConfig => levels[_currentLevel];

  void setLevel(int levelIndex) {
    _currentLevel = levelIndex.clamp(0, levels.length - 1);

    // Clear bubbles and pause 1 second before starting the new level
    _score = 0;
    _scoreText.text = 'Score: 0';
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
    _paused = true;
    _pauseTimer = 0.0;
  }

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    // Add screen boundary so bubbles can collide with edges
    add(ScreenHitbox());

    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_scoreText);

    // Spawn first bubble
    _spawnBubble();
  }

  @override
  void update(double dt) {
    super.update(dt);

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
    _scoreText.text = 'Score: $_score';
  }

  void onBubbleCollision() {
    if (_paused) return;
    // Collision — pause for 2 seconds, then restart
    _paused = true;
    _pauseTimer = 0.0;
    _score = 0;
    _scoreText.text = 'Score: 0';

    // Remove all remaining bubbles
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());
  }

  void _restartGame() {
    _spawnTimer = 0.0;
    _spawnBubble();
  }
}
