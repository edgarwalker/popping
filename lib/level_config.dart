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

  /// Seconds between each spawn.
  final double spawnInterval;

  /// Minimum space (in pixels) between bubble edges when spawning.
  final double minSpacing;

  const LevelConfig({
    required this.level,
    required this.name,
    required this.growthSpeed,
    required this.maxBubbles,
    required this.spawnCount,
    required this.spawnInterval,
    required this.minSpacing,
  });
}

/// All 7 levels with increasing difficulty.
const List<LevelConfig> levels = [
  LevelConfig(
    level: 1,
    name: 'Level 1',
    growthSpeed: 7.0,
    maxBubbles: 5,
    spawnCount: 1,
    spawnInterval: 3.0,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 2,
    name: 'Level 2',
    growthSpeed: 6.0,
    maxBubbles: 7,
    spawnCount: 1,
    spawnInterval: 2.5,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 3,
    name: 'Level 3',
    growthSpeed: 5.0,
    maxBubbles: 9,
    spawnCount: 1,
    spawnInterval: 2.0,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 4,
    name: 'Level 4',
    growthSpeed: 4.0,
    maxBubbles: 12,
    spawnCount: 1,
    spawnInterval: 1.5,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 5,
    name: 'Level 5',
    growthSpeed: 2.6,
    maxBubbles: 16,
    spawnCount: 1,
    spawnInterval: 1.0,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 6,
    name: 'Level 6',
    growthSpeed: 1.6,
    maxBubbles: 19,
    spawnCount: 1,
    spawnInterval: 0.5,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 7,
    name: 'Level 7',
    growthSpeed: 0.6,
    maxBubbles: 23,
    spawnCount: 1,
    spawnInterval: 0.3,
    minSpacing: 60.0,
  ),
];
