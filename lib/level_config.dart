/// Defines the configuration for each game level.
class LevelConfig {
  /// The level number (1–7).
  final int level;

  /// How fast the bubble grows in seconds from initial to max radius.
  /// Lower values mean faster growth (harder).
  final double growthSpeed;

  const LevelConfig({
    required this.level,
    required this.growthSpeed,
  });
}

/// All 7 levels with increasing bubble growth speed (faster = harder).
const List<LevelConfig> levels = [
  LevelConfig(level: 1, growthSpeed: 5.0),  // Slowest — easiest
  LevelConfig(level: 2, growthSpeed: 4.2),
  LevelConfig(level: 3, growthSpeed: 3.5),
  LevelConfig(level: 4, growthSpeed: 2.8),
  LevelConfig(level: 5, growthSpeed: 2.2),
  LevelConfig(level: 6, growthSpeed: 1.6),
  LevelConfig(level: 7, growthSpeed: 1.0),  // Fastest — hardest
];
