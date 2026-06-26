import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import 'level_config.dart';
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
  int _selectedLevel = 0; // default level 1 (index 0)

  void _showLevelPicker() {
    showCupertinoDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: const Color(0xF0222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(levels.length, (index) {
                    final isSelected = index == _selectedLevel;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLevel = index;
                        });
                        _game.setLevel(index);
                        Navigator.of(context).pop(index);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border:
                              index < levels.length - 1
                                  ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF444444),
                                      width: 0.5,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Text(
                          levels[index].name,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.white,
                            fontSize: 16,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          GameWidget(game: _game),
          // Level picker button positioned at top-right
          Positioned(
            top: 40,
            right: 20,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: CupertinoColors.black.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(8),
              onPressed: _showLevelPicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    levels[_selectedLevel].name,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
