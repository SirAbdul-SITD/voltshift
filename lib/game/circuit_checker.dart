// lib/game/circuit_checker.dart
import 'dart:collection';
import 'tile.dart';

class CircuitChecker {
  static Set<int> check({
    required List<Tile> tiles,
    required int gridSize,
    required int sourceIndex,
  }) {
    final powered = <int>{sourceIndex};
    final queue = Queue<int>()..add(sourceIndex);

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final r = idx ~/ gridSize, c = idx % gridSize;
      final t = tiles[idx];

      void tryAdd(int ni, bool open, bool otherOpen) {
        if (open && otherOpen && !powered.contains(ni)) {
          powered.add(ni);
          queue.add(ni);
        }
      }

      if (r > 0) {
        final ni = idx - gridSize;
        tryAdd(ni, t.hasTop, tiles[ni].hasBottom);
      }
      if (c < gridSize - 1) {
        final ni = idx + 1;
        tryAdd(ni, t.hasRight, tiles[ni].hasLeft);
      }
      if (r < gridSize - 1) {
        final ni = idx + gridSize;
        tryAdd(ni, t.hasBottom, tiles[ni].hasTop);
      }
      if (c > 0) {
        final ni = idx - 1;
        tryAdd(ni, t.hasLeft, tiles[ni].hasRight);
      }
    }
    return powered;
  }
}
