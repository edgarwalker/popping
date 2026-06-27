import 'dart:async';
import 'dart:ui';

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
  bool _isGameOver = false;
  int _adventureTarget = 1000;
  Timer? _holdTimer;
  Timer? _timeDisplayTimer;
  late TextEditingController _targetController;

  void _setAdventureTarget(int value) {
    _adventureTarget = value.clamp(50, 10000000000);
    _game.adventureTarget = _adventureTarget;
    _targetController.text = _adventureTarget.toString();
    if (_selectedMode == 2) {
      _score = 0;
      _waitingToStart = true;
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
        _timeDisplayTimer?.cancel();
      } else {
        if (_waitingToStart) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
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
                  BounceButton(
                    onTap: _showSettingsPanel,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        CupertinoIcons.gear,
                        color: CupertinoColors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "Start Game" waiting screen
          if (_waitingToStart && _isGameOver)
            Positioned(
              top: MediaQuery.of(context).size.height / 4,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Game Over !',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          if (_waitingToStart)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BounceButton(
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
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(16),
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
                          _game.paused = false;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _game.paused = true;
                          });
                        });
                      },
                    ),
                    if (_selectedMode == 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Level: ${_selectedLevel + 1}',
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
                        max: 6,
                        divisions: 6,
                        value: _selectedLevel.toDouble(),
                        onChanged: (value) {
                          final newLevel = value.round();
                          if (newLevel != _selectedLevel) {
                            setState(() {
                              _selectedLevel = newLevel;
                              _waitingToStart = true;
                              _score = 0;
                            });
                            _game.setLevel(newLevel);
                            _game.clearState();
                            _game.paused = false;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _game.paused = true;
                            });
                          }
                        },
                      ),
                    ],
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
                          BounceButton(
                            onTap: () {
                              setState(() {
                                _setAdventureTarget(_adventureTarget - 10);
                              });
                            },
                            onLongPressStart: () {
                              _holdTimer = Timer.periodic(
                                const Duration(milliseconds: 100),
                                (_) {
                                  setState(() {
                                    _setAdventureTarget(_adventureTarget - 10);
                                  });
                                },
                              );
                            },
                            onLongPressEnd: () {
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
                                  if (parsed < 50) {
                                    _adventureTarget = 50;
                                    _targetController.text = '50';
                                    _targetController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _targetController.text.length,
                                      ),
                                    );
                                  } else {
                                    _adventureTarget = parsed.clamp(
                                      50,
                                      10000000000,
                                    );
                                  }
                                  _game.adventureTarget = _adventureTarget;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          BounceButton(
                            onTap: () {
                              setState(() {
                                _setAdventureTarget(_adventureTarget + 10);
                              });
                            },
                            onLongPressStart: () {
                              _holdTimer = Timer.periodic(
                                const Duration(milliseconds: 100),
                                (_) {
                                  setState(() {
                                    _setAdventureTarget(_adventureTarget + 10);
                                  });
                                },
                              );
                            },
                            onLongPressEnd: () {
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
                    const SizedBox(height: 16),
                    Center(
                      child: BounceButton(
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
                            horizontal: 24,
                            vertical: 12,
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
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS-style bounce button with water drop scale animation.
class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const BounceButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPressStart: (_) {
        _controller.forward();
        widget.onLongPressStart?.call();
      },
      onLongPressEnd: (_) {
        _controller.reverse();
        widget.onLongPressEnd?.call();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
