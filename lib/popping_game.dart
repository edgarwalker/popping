import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'bubble.dart';
import 'level_config.dart';

class PoppingGame extends FlameGame with HasCollisionDetection {
  final Random _random = Random();

  double _spawnTimer = 0.0;
  final double _spawnInterval = 1.5; // seconds between spawns
  int _score = 0;
  int _currentLevel = 0; // index into levels list (0–6)

  late TextComponent _scoreText;

  LevelConfig get currentLevelConfig => levels[_currentLevel];

  void setLevel(int levelIndex) {
    _currentLevel = levelIndex.clamp(0, levels.length - 1);
    _resetGame();
  }

  void _resetGame() {
    // Reset score
    _score = 0;
    _scoreText.text = 'Score: 0';

    // Remove all existing bubbles
    children.whereType<Bubble>().toList().forEach((b) => b.removeFromParent());

    // Reset spawn timer and spawn fresh bubbles
    _spawnTimer = 0.0;
    for (int i = 0; i < currentLevelConfig.maxBubbles; i++) {
      _spawnBubble();
    }
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
          color: Colors.white70,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_scoreText);

    // Spawn initial bubbles based on level
    for (int i = 0; i < currentLevelConfig.maxBubbles; i++) {
      _spawnBubble();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0.0;
      // Spawn multiple bubbles per tick based on level
      final activeBubbles =
          children.whereType<Bubble>().where((b) => !b.isPopping).length;
      final canSpawn = currentLevelConfig.maxBubbles - activeBubbles;
      final toSpawn = currentLevelConfig.spawnCount.clamp(0, canSpawn);
      for (int i = 0; i < toSpawn; i++) {
        _spawnBubble();
      }
    }
  }

  void _spawnBubble() {
    final margin = 100.0;
    // Minimum distance between new bubble center and existing bubble edges
    const spawnRadius = Bubble.initialRadius;
    const minGap = 20.0; // extra spacing between bubbles

    // Get all active (non-popping) bubbles
    final existingBubbles =
        children.whereType<Bubble>().where((b) => !b.isPopping).toList();

    // Try to find a valid position (max attempts to avoid infinite loop)
    Vector2? spawnPos;
    for (int attempt = 0; attempt < 20; attempt++) {
      final x = margin + _random.nextDouble() * (size.x - margin * 2);
      final y = margin + _random.nextDouble() * (size.y - margin * 2);
      final candidate = Vector2(x, y);

      bool tooClose = false;
      for (final bubble in existingBubbles) {
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

    // Only spawn if we found a valid position with enough space
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
    // Collision — reset score
    _score = 0;
    _scoreText.text = 'Score: 0';
  }
}
