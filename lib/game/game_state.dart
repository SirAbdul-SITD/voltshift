// lib/game/game_state.dart
import 'package:flutter/material.dart';
import 'level_generator.dart';
import '../utils/preferences.dart';
import '../utils/audio_manager.dart';

class GameState extends ChangeNotifier {
  late ShiftLevel level;
  int moves = 0;
  bool isComplete = false;
  int stars = 0;
  int currentLevelIndex = 0;
  bool initialized = false;
  Set<int> poweredSet = {};

  void loadLevel(int index) {
    currentLevelIndex = index;
    level = LevelGenerator.generate(index);
    moves = 0;
    isComplete = false;
    stars = 0;
    initialized = true;
    _updatePowered();
    notifyListeners();
  }

  void shift({required bool isRow, required int index, required int dir}) {
    if (isComplete) return;
    level.tiles = LevelGenerator.applyShift(
        level.tiles, level.gridSize, isRow, index, dir);
    moves++;
    AudioManager.instance.playShift();
    _updatePowered();
    notifyListeners();
  }

  void _updatePowered() {
    final s = level.gridSize;
    final start = level.sourceRow * s;
    poweredSet = {};
    if (level.tiles[start].hasLeft) {
      poweredSet.add(start);
      final queue = [start];
      while (queue.isNotEmpty) {
        final idx = queue.removeLast();
        final r = idx ~/ s, c = idx % s;
        final t = level.tiles[idx];
        void go(int ni, bool a, bool b) {
          if (a && b && poweredSet.add(ni)) queue.add(ni);
        }

        if (r > 0) go(idx - s, t.hasTop, level.tiles[idx - s].hasBottom);
        if (c < s - 1) go(idx + 1, t.hasRight, level.tiles[idx + 1].hasLeft);
        if (r < s - 1) go(idx + s, t.hasBottom, level.tiles[idx + s].hasTop);
        if (c > 0) go(idx - 1, t.hasLeft, level.tiles[idx - 1].hasRight);
      }
    }
    for (int i = 0; i < level.tiles.length; i++) {
      level.tiles[i].isPowered = poweredSet.contains(i);
    }

    final end = level.bulbRow * s + s - 1;
    final solved = poweredSet.contains(end) && level.tiles[end].hasRight;
    if (solved && !isComplete) {
      isComplete = true;
      stars = _calcStars();
      AudioManager.instance.playComplete();
      Preferences.instance.saveLevelResult(currentLevelIndex, stars);
    }
  }

  int _calcStars() {
    if (moves <= level.parMoves) return 3;
    if (moves <= level.parMoves * 2) return 2;
    return 1;
  }

  void restartLevel() {
    level.reset();
    moves = 0;
    isComplete = false;
    stars = 0;
    _updatePowered();
    notifyListeners();
  }

  void nextLevel() {
    if (currentLevelIndex < 149) loadLevel(currentLevelIndex + 1);
  }
}
