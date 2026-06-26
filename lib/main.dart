import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

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
  int _adventureTarget = 1000;
  Timer? _holdTimer;

  void _setAdventureTarget(int value) {
    _adventureTarget = value.clamp(50, 10000000000);
    _game.adventureTarget = _adventureTarget;
    if (_selectedMode == 2) {
      _score = 0;
      _waitingToStart = true;
      _game.clearState();
    }
  }

  static const List<String> _modes = ['Level', 'Score', 'Adventure'];

  @override
  @override
  void initState() {
    super.initState();
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
      setState(() {
        _waitingToStart = true;
        _score = 0;
      });
      _game.clearState();
    };
    _game.adventureTarget = _adventureTarget;
    _game.paused = true; // Start paused, waiting for "Start Game"
  }

  void _showSettingsPanel() {
    setState(() {
      _settingsOpen = !_settingsOpen;
      if (_settingsOpen) {
        _game.paused = true;
      } else {
        if (_waitingToStart) {
          _game.paused = true;
        } else {
          _game.paused = false;
        }
      }
    });
  }

  void _startGame() {
    setState(() {
      _waitingToStart = false;
      _settingsOpen = false;
    });
    _game.startImmediately();
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_selectedMode != 0)
                    Text(
                      _selectedMode == 2
                          ? 'Score: $_score / $_adventureTarget'
                          : 'Score: $_score',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showSettingsPanel,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.gear,
                        color: CupertinoColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Settings panel with Mode and Level sliders
          if (_settingsOpen)
            Positioned(
              top: 75,
              right: 16,
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x00000000),
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
                    // Mode slider
                    Text(
                      'Mode: ${_modes[_selectedMode]}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CupertinoSlider(
                      min: 0,
                      max: 2,
                      divisions: 2,
                      value: _selectedMode.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMode = value.round();
                          if (_selectedMode == 1 || _selectedMode == 2) {
                            _selectedLevel = 0;
                            _game.setLevel(6);
                          } else {
                            _game.setLevel(_selectedLevel);
                          }
                          _game.setMode(_selectedMode);
                          _waitingToStart = true;
                          _score = 0;
                          _game.clearState();
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    // Level slider
                    Text(
                      'Level: ${_selectedLevel + 1}',
                      style: TextStyle(
                        color:
                            _selectedMode != 0
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: _selectedMode != 0 ? 0.4 : 1.0,
                      child: CupertinoSlider(
                        min: 0,
                        max: 6,
                        divisions: 6,
                        value: _selectedLevel.toDouble(),
                        onChanged:
                            _selectedMode != 0
                                ? null
                                : (value) {
                                  final newLevel = value.round();
                                  if (newLevel != _selectedLevel) {
                                    setState(() {
                                      _selectedLevel = newLevel;
                                      _waitingToStart = true;
                                      _score = 0;
                                    });
                                    _game.setLevel(newLevel);
                                    _game.clearState();
                                  }
                                },
                      ),
                    ),
                    // Target field for Adventure mode
                    if (_selectedMode == 2) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Target',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
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
                                    _setAdventureTarget(_adventureTarget - 10);
                                  });
                                },
                              );
                            },
                            onLongPressEnd: (_) {
                              _holdTimer?.cancel();
                              _holdTimer = null;
                            },
                            child: const Icon(
                              CupertinoIcons.minus_circle,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CupertinoTextField(
                              controller: TextEditingController(
                                text: _adventureTarget.toString(),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
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
                                  setState(() {
                                    _setAdventureTarget(parsed);
                                  });
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
                                    _setAdventureTarget(_adventureTarget + 10);
                                  });
                                },
                              );
                            },
                            onLongPressEnd: (_) {
                              _holdTimer?.cancel();
                              _holdTimer = null;
                            },
                            child: const Icon(
                              CupertinoIcons.plus_circle,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _waitingToStart = true;
                            _score = 0;
                          });
                          _game.clearState();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Reset Game',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
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
            ),
          // "Start Game" waiting screen
          if (_waitingToStart)
            Center(
              child: GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CupertinoColors.white,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Start Game',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
