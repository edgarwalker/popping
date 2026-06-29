import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import 'bubble_text_widget.dart';
import 'fireworks_widget.dart';

import 'popping_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Popping',
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final PoppingGame _game = PoppingGame();
  int _selectedLevel = 0;
  int _selectedMode = 0; // 0: Level, 1: Score, 2: Adventure
  int _score = 0;
  bool _settingsOpen = false;
  bool _waitingToStart = true;
  bool _isGameOver = false;
  int _adventureTarget = 10;
  int _volume = 4; // 0-7, app volume level
  int _volumeBeforeMute = 4; // remember volume before mute
  final GlobalKey _volumeKey = GlobalKey();
  final GlobalKey _volumeBarsKey = GlobalKey();
  Timer? _holdTimer;
  Timer? _timeDisplayTimer;
  late TextEditingController _targetController;

  void _setAdventureTarget(int value) {
    _adventureTarget = value.clamp(10, 10000000000);
    _game.adventureTarget = _adventureTarget;
    _targetController.text = _adventureTarget.toString();
    if (_selectedMode == 2) {
      _score = 0;
      _waitingToStart = true;
      _isGameOver = false;
      _game.clearState();
      _game.paused = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.paused = true;
      });
    }
  }

  static const List<String> _modes = ['Level', 'Score', 'Adventure'];

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: _adventureTarget.toString(),
    );
    _game.onScoreUpdate = (score) {
      setState(() {
        _score = score;
      });
    };
    _game.onLevelUpdate = (level) {
      setState(() {
        _selectedLevel = level;
      });
    };
    _game.onGameOver = () {
      _timeDisplayTimer?.cancel();
      setState(() {
        _waitingToStart = true;
        _isGameOver = true;
        if (_selectedMode != 2) {
          _score = 0;
        }
      });
      // Don't pause the engine — let animations keep running
      // Game logic is already stopped via _gameOverTriggered
    };
    _game.adventureTarget = _adventureTarget;
    _game.paused = true; // Start paused, waiting for "Start Game"
  }

  void _showSettingsPanel() {
    setState(() {
      _settingsOpen = !_settingsOpen;
      if (_settingsOpen) {
        _game.paused = true;
        _timeDisplayTimer?.cancel();
      } else {
        if (_waitingToStart && !_isGameOver) {
          _game.paused = true;
        } else {
          _game.paused = false;
          _timeDisplayTimer?.cancel();
          _timeDisplayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          });
        }
      }
    });
  }

  void _startGame() {
    setState(() {
      _waitingToStart = false;
      _isGameOver = false;
      _settingsOpen = false;
    });
    _game.startImmediately();
    // Start periodic timer to update time display
    _timeDisplayTimer?.cancel();
    _timeDisplayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: _waitingToStart,
            child: GameWidget(game: _game),
          ),
          // Top row: score left, gear right
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 7),
                // Left side content
                if (_selectedMode == 0)
                  Text(
                    'Level ${_selectedLevel + 1}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                if (_selectedMode == 1)
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                if (_selectedMode == 2)
                  Text(
                    'Score: $_score / $_adventureTarget',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                const Spacer(),
                // Center: time for adventure mode
                if (_selectedMode == 2)
                  Builder(
                    builder: (context) {
                      final total = _game.elapsedTime.toInt();
                      final h = total ~/ 3600;
                      final m = (total % 3600) ~/ 60;
                      final s = total % 60;
                      String timeStr;
                      if (h > 0) {
                        timeStr = '${h}h ${m}m ${s}s';
                      } else if (m > 0) {
                        timeStr = '${m}m ${s}s';
                      } else {
                        timeStr = '${s}s';
                      }
                      return Text(
                        'Time: $timeStr',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      );
                    },
                  ),
                if (_selectedMode == 2) const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: _showSettingsPanel,
                  child: const Icon(
                    CupertinoIcons.gear,
                    color: CupertinoColors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          // Fireworks for adventure complete
          if (_waitingToStart && _isGameOver && _selectedMode == 2)
            const Positioned.fill(
              child: IgnorePointer(
                child: FireworksWidget(duration: Duration(seconds: 2)),
              ),
            ),
          // "Start Game" waiting screen
          if (_waitingToStart)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isGameOver && _selectedMode == 2) ...[
                    const BubbleTextWidget(
                      text: 'Well Done',
                      fontSize: 42,
                      color: Color(0xFFFFDD00),
                    ),
                    const SizedBox(height: 24),
                  ],
                  GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.white,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Settings panel with Mode and Level sliders (on top of everything)
          if (_settingsOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _showSettingsPanel,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: const Color(0x40000000)),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xF0101020),
                      border: Border.all(
                        color: CupertinoColors.white.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_modes.length, (index) {
                            final isSelected = index == _selectedMode;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMode = index;
                                  if (_selectedMode == 1 ||
                                      _selectedMode == 2) {
                                    _selectedLevel = 0;
                                    _game.setLevel(6);
                                  } else {
                                    _game.setLevel(_selectedLevel);
                                  }
                                  _game.setMode(_selectedMode);
                                  _waitingToStart = true;
                                  _isGameOver = false;
                                  _score = 0;
                                  _game.clearState();
                                  _game.paused = false;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _game.paused = true;
                                  });
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? CupertinoColors.activeBlue
                                          : const Color(0x00000000),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? CupertinoColors.activeBlue
                                            : CupertinoColors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _modes[index],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? CupertinoColors.white
                                            : CupertinoColors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _selectedMode == 0 ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: _selectedMode != 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level',
                                  style: TextStyle(
                                    color:
                                        _selectedMode == 0
                                            ? CupertinoColors.white
                                            : CupertinoColors.systemGrey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(7, (index) {
                                    final isSelected = index == _selectedLevel;
                                    return GestureDetector(
                                      onTap: () {
                                        if (index != _selectedLevel) {
                                          setState(() {
                                            _selectedLevel = index;
                                            _waitingToStart = true;
                                            _isGameOver = false;
                                            _score = 0;
                                          });
                                          _game.setLevel(index);
                                          _game.clearState();
                                          _game.paused = false;
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                _game.paused = true;
                                              });
                                        }
                                      },
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? CupertinoColors.activeBlue
                                                  : const Color(0x00000000),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? CupertinoColors.activeBlue
                                                    : CupertinoColors.white
                                                        .withValues(alpha: 0.6),
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? CupertinoColors.white
                                                    : CupertinoColors.white
                                                        .withValues(alpha: 0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedMode == 2) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Target',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _setAdventureTarget(_adventureTarget - 10);
                                  });
                                },
                                onLongPressStart: (_) {
                                  _holdTimer = Timer.periodic(
                                    const Duration(milliseconds: 100),
                                    (_) {
                                      setState(() {
                                        _setAdventureTarget(
                                          _adventureTarget - 10,
                                        );
                                      });
                                    },
                                  );
                                },
                                onLongPressEnd: (_) {
                                  _holdTimer?.cancel();
                                  _holdTimer = null;
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    CupertinoIcons.minus_circle,
                                    color: CupertinoColors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CupertinoTextField(
                                  controller: _targetController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value);
                                    if (parsed != null) {
                                      if (parsed < 10) {
                                        _adventureTarget = 10;
                                        _targetController.text = '10';
                                        _targetController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                    _targetController
                                                        .text
                                                        .length,
                                              ),
                                            );
                                      } else {
                                        _adventureTarget = parsed.clamp(
                                          10,
                                          10000000000,
                                        );
                                      }
                                      _game.adventureTarget = _adventureTarget;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _setAdventureTarget(_adventureTarget + 10);
                                  });
                                },
                                onLongPressStart: (_) {
                                  _holdTimer = Timer.periodic(
                                    const Duration(milliseconds: 100),
                                    (_) {
                                      setState(() {
                                        _setAdventureTarget(
                                          _adventureTarget + 10,
                                        );
                                      });
                                    },
                                  );
                                },
                                onLongPressEnd: (_) {
                                  _holdTimer?.cancel();
                                  _holdTimer = null;
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    CupertinoIcons.plus_circle,
                                    color: CupertinoColors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              _game.clearState();
                              // Unpause briefly to render cleared state
                              _game.paused = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _game.paused = true;
                              });
                              setState(() {
                                _waitingToStart = true;
                                _isGameOver = false;
                                _score = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CupertinoColors.white.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Reset Game',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Volume control
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF0101020),
                      border: Border.all(
                        color: CupertinoColors.white.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final RenderBox? box =
                            _volumeBarsKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box == null) return;
                        final localPos = box.globalToLocal(
                          details.globalPosition,
                        );
                        final fraction =
                            1.0 -
                            (localPos.dy / box.size.height).clamp(0.0, 1.0);
                        final tappedLevel = (fraction * 7).ceil().clamp(1, 7);
                        setState(() {
                          if (tappedLevel == 1 && _volume == 1) {
                            _volume = 0;
                          } else {
                            _volume = tappedLevel;
                          }
                          _game.volume = _volume / 7.0;
                        });
                      },
                      onVerticalDragStart: (details) {
                        final RenderBox? box =
                            _volumeBarsKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box == null) return;
                        final localPos = box.globalToLocal(
                          details.globalPosition,
                        );
                        final fraction =
                            1.0 -
                            (localPos.dy / box.size.height).clamp(0.0, 1.0);
                        final newVolume = (fraction * 7).ceil().clamp(0, 7);
                        setState(() {
                          _volume = newVolume;
                          _game.volume = _volume / 7.0;
                        });
                      },
                      onVerticalDragUpdate: (details) {
                        final RenderBox? box =
                            _volumeBarsKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box == null) return;
                        final localPos = box.globalToLocal(
                          details.globalPosition,
                        );
                        final fraction =
                            1.0 -
                            (localPos.dy / box.size.height).clamp(0.0, 1.0);
                        final newVolume = (fraction * 7).ceil().clamp(0, 7);
                        if (newVolume != _volume) {
                          setState(() {
                            _volume = newVolume;
                            _game.volume = _volume / 7.0;
                          });
                        }
                      },
                      child: Column(
                        key: _volumeKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_volume == 0) {
                                  _volume = _volumeBeforeMute;
                                } else {
                                  _volumeBeforeMute = _volume;
                                  _volume = 0;
                                }
                                _game.volume = _volume / 7.0;
                              });
                            },
                            child: Icon(
                              _volume == 0
                                  ? CupertinoIcons.speaker_slash_fill
                                  : CupertinoIcons.speaker_2_fill,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            key: _volumeBarsKey,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (i) {
                              final level = 7 - i;
                              final isActive = level <= _volume;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 6,
                                ),
                                child: Container(
                                  width: 24,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? CupertinoColors.activeBlue
                                            : const Color(0x00000000),
                                    border: Border.all(
                                      color:
                                          isActive
                                              ? CupertinoColors.activeBlue
                                              : CupertinoColors.white
                                                  .withValues(alpha: 0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
