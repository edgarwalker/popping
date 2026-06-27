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

  /// Seconds between each spawn.
  final double spawnInterval;

  /// Minimum space (in pixels) between bubble edges when spawning.
  final double minSpacing;

  const LevelConfig({
    required this.level,
    required this.name,
    required this.growthSpeed,
    required this.maxBubbles,
    required this.spawnInterval,
    required this.minSpacing,
  });
}

/// All 7 levels with increasing difficulty.
const List<LevelConfig> levels = [
  LevelConfig(
    level: 1,
    name: 'Level 1',
    growthSpeed: 6.6,
    maxBubbles: 6,
    spawnInterval: 2.9,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 2,
    name: 'Level 2',
    growthSpeed: 5.3,
    maxBubbles: 8,
    spawnInterval: 2.4,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 3,
    name: 'Level 3',
    growthSpeed: 4.7,
    maxBubbles: 10,
    spawnInterval: 1.9,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 4,
    name: 'Level 4',
    growthSpeed: 3.5,
    maxBubbles: 14,
    spawnInterval: 1.3,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 5,
    name: 'Level 5',
    growthSpeed: 2.4,
    maxBubbles: 17,
    spawnInterval: 0.8,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 6,
    name: 'Level 6',
    growthSpeed: 1.4,
    maxBubbles: 20,
    spawnInterval: 0.4,
    minSpacing: 60.0,
  ),
  LevelConfig(
    level: 7,
    name: 'Level 7',
    growthSpeed: 0.4,
    maxBubbles: 24,
    spawnInterval: 0.25,
    minSpacing: 60.0,
  ),
];
