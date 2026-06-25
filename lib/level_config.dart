/// Defines the configuration for each game level.
class LevelConfig {
  /// The level number (1–7).
  final int level;

  /// Display name for the level.
  final String name;

  /// How fast the bubble grows in seconds from initial to max radius.
  /// Lower values mean faster growth (harder).
  final double growthSpeed;

  /// Maximum number of bubbles on screen at once.
  final int maxBubbles;

  /// How many bubbles spawn at once each spawn tick.
  final int spawnCount;

  const LevelConfig({
    required this.level,
    required this.name,
    required this.growthSpeed,
    required this.maxBubbles,
    required this.spawnCount,
  });
}

/// All 7 levels with increasing bubble growth speed (faster = harder).
const List<LevelConfig> levels = [
  LevelConfig(
    level: 1,
    name: 'Beginner',
    growthSpeed: 5.0,
    maxBubbles: 5,
    spawnCount: 1,
  ),
  LevelConfig(
    level: 2,
    name: 'Easy',
    growthSpeed: 4.0,
    maxBubbles: 7,
    spawnCount: 1,
  ),
  LevelConfig(
    level: 3,
    name: 'Medium',
    growthSpeed: 3.0,
    maxBubbles: 9,
    spawnCount: 2,
  ),
  LevelConfig(
    level: 4,
    name: 'Hard',
    growthSpeed: 2.5,
    maxBubbles: 12,
    spawnCount: 2,
  ),
  LevelConfig(
    level: 5,
    name: 'Expert',
    growthSpeed: 1.5,
    maxBubbles: 15,
    spawnCount: 3,
  ),
  LevelConfig(
    level: 6,
    name: 'Master',
    growthSpeed: 1.0,
    maxBubbles: 18,
    spawnCount: 4,
  ),
  LevelConfig(
    level: 7,
    name: 'Insane',
    growthSpeed: 0.5,
    maxBubbles: 22,
    spawnCount: 5,
  ),
];
