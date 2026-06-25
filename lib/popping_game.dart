import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'bubble.dart';

class PoppingGame extends FlameGame with HasCollisionDetection {
  final Random _random = Random();

  double _spawnTimer = 0.0;
  final double _spawnInterval = 1.5; // seconds between spawns
  int _score = 0;

  late TextComponent _scoreText;

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

    // Spawn a few initial bubbles
    for (int i = 0; i < 3; i++) {
      _spawnBubble();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0.0;
      _spawnBubble();
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
      final growthDuration = 2.5 + _random.nextDouble() * 2.0;
      add(Bubble(position: spawnPos, growthDuration: growthDuration));
    }
  }

  void onBubblePopped() {
    _score++;
    _scoreText.text = 'Score: $_score';
  }
}
