// lib/game/level_generator.dart
import 'dart:math';
import 'tile.dart';

/// VoltShift level: power enters from a fixed SOCKET on the left edge
/// (row [sourceRow]) and must reach the LAMP on the right edge
/// (row [bulbRow]). The player shifts whole rows/columns (with wrap-around)
/// to re-align the conduit tiles.
class ShiftLevel {
  final int index;
  final int gridSize;
  final int sourceRow; // row of the left-edge socket
  final int bulbRow;   // row of the right-edge lamp
  final String difficulty;
  final int parMoves;
  final List<Tile> initialTiles;
  late List<Tile> tiles;

  ShiftLevel({
    required this.index,
    required this.gridSize,
    required this.sourceRow,
    required this.bulbRow,
    required this.difficulty,
    required this.parMoves,
    required this.initialTiles,
  }) {
    tiles = initialTiles.map((t) => t.clone()).toList();
  }

  void reset() => tiles = initialTiles.map((t) => t.clone()).toList();
}

class LevelGenerator {
  static ShiftLevel generate(int levelIndex) {
    int size;
    String difficulty;
    int scrambleShifts;
    if (levelIndex < 50) {
      size = 4;
      difficulty = 'Easy';
      scrambleShifts = 3 + levelIndex ~/ 12;
    } else if (levelIndex < 100) {
      size = 5;
      difficulty = 'Medium';
      scrambleShifts = 5 + (levelIndex - 50) ~/ 12;
    } else {
      size = 6;
      difficulty = 'Hard';
      scrambleShifts = 7 + (levelIndex - 100) ~/ 10;
    }

    final rng = Random(levelIndex * 7457 + levelIndex * 11 + 3);

    final sourceRow = rng.nextInt(size);
    final bulbRow = rng.nextInt(size);

    // Build a path from (sourceRow, 0) to (bulbRow, size-1)
    final start = sourceRow * size;
    final end = bulbRow * size + size - 1;
    final path = _dfsPath(start, end, size, rng) ?? _straightPath(start, end, size);

    final masks = List<int>.filled(size * size, 0);
    for (int i = 0; i < path.length - 1; i++) {
      final d = _dir(path[i], path[i + 1], size);
      masks[path[i]] |= 1 << d;
      masks[path[i + 1]] |= 1 << ((d + 2) % 4);
    }
    masks[start] |= 8; // open LEFT toward the socket
    masks[end] |= 2;   // open RIGHT toward the lamp

    // Sprinkle decoy conduit pieces on empty cells (~35%)
    final decoys = [3, 5, 6, 9, 10, 12, 7, 13];
    for (int i = 0; i < size * size; i++) {
      if (masks[i] == 0 && rng.nextDouble() < 0.35) {
        masks[i] = decoys[rng.nextInt(decoys.length)];
      }
    }

    var tiles = List<Tile>.generate(
        size * size,
        (i) => Tile(
            type: masks[i] == 0 ? TileType.empty : TileType.wire,
            mask: masks[i]));

    // Scramble with random row/col shifts; record count
    int done = 0;
    final history = <List<int>>[];
    while (done < scrambleShifts) {
      final isRow = rng.nextBool();
      final idx = rng.nextInt(size);
      final dir = rng.nextBool() ? 1 : -1;
      // avoid trivially undoing the previous shift
      if (history.isNotEmpty) {
        final h = history.last;
        if (h[0] == (isRow ? 1 : 0) && h[1] == idx && h[2] == -dir) continue;
      }
      tiles = applyShift(tiles, size, isRow, idx, dir);
      history.add([isRow ? 1 : 0, idx, dir]);
      done++;
    }

    // Make sure it isn't already solved
    if (isSolvedState(tiles, size, sourceRow, bulbRow)) {
      tiles = applyShift(tiles, size, true, sourceRow, 1);
      done++;
    }

    return ShiftLevel(
      index: levelIndex,
      gridSize: size,
      sourceRow: sourceRow,
      bulbRow: bulbRow,
      difficulty: difficulty,
      parMoves: done,
      initialTiles: tiles,
    );
  }

  /// Shift a row (isRow=true) or column by dir (+1 / -1) with wrap-around.
  static List<Tile> applyShift(
      List<Tile> tiles, int size, bool isRow, int index, int dir) {
    final out = tiles.map((t) => t.clone()).toList();
    if (isRow) {
      for (int c = 0; c < size; c++) {
        final from = index * size + ((c - dir) % size + size) % size;
        out[index * size + c] = tiles[from].clone();
      }
    } else {
      for (int r = 0; r < size; r++) {
        final from = (((r - dir) % size + size) % size) * size + index;
        out[r * size + index] = tiles[from].clone();
      }
    }
    return out;
  }

  static bool isSolvedState(
      List<Tile> tiles, int size, int sourceRow, int bulbRow) {
    final start = sourceRow * size;
    if (!tiles[start].hasLeft) return false;
    final powered = <int>{start};
    final queue = [start];
    while (queue.isNotEmpty) {
      final idx = queue.removeLast();
      final r = idx ~/ size, c = idx % size;
      final t = tiles[idx];
      void go(int ni, bool a, bool b) {
        if (a && b && powered.add(ni)) queue.add(ni);
      }

      if (r > 0) go(idx - size, t.hasTop, tiles[idx - size].hasBottom);
      if (c < size - 1) go(idx + 1, t.hasRight, tiles[idx + 1].hasLeft);
      if (r < size - 1) go(idx + size, t.hasBottom, tiles[idx + size].hasTop);
      if (c > 0) go(idx - 1, t.hasLeft, tiles[idx - 1].hasRight);
    }
    final end = bulbRow * size + size - 1;
    return powered.contains(end) && tiles[end].hasRight;
  }

  // ── path helpers ───────────────────────────────────────
  static List<int> _nbrs(int i, int s) {
    final r = i ~/ s, c = i % s;
    return [
      if (r > 0) i - s,
      if (c < s - 1) i + 1,
      if (r < s - 1) i + s,
      if (c > 0) i - 1,
    ];
  }

  static int _dir(int from, int to, int s) {
    if (to == from - s) return 0;
    if (to == from + 1) return 1;
    if (to == from + s) return 2;
    return 3;
  }

  static List<int>? _dfsPath(int start, int end, int s, Random rng) {
    final path = <int>[start];
    final visited = <int>{start};
    bool dfs() {
      if (path.last == end) return true;
      final nbrs =
          _nbrs(path.last, s).where((n) => !visited.contains(n)).toList()
            ..shuffle(rng);
      for (final n in nbrs) {
        visited.add(n);
        path.add(n);
        if (dfs()) return true;
        path.removeLast();
        visited.remove(n);
      }
      return false;
    }

    for (int attempt = 0; attempt < 16; attempt++) {
      path
        ..clear()
        ..add(start);
      visited
        ..clear()
        ..add(start);
      if (dfs() && path.length >= 3) return List<int>.from(path);
    }
    return null;
  }

  static List<int> _straightPath(int start, int end, int s) {
    // L-shaped: across the source row, then down/up the last column
    final out = <int>[];
    final sr = start ~/ s, br = end ~/ s;
    for (int c = 0; c < s; c++) out.add(sr * s + c);
    if (br > sr) {
      for (int r = sr + 1; r <= br; r++) out.add(r * s + s - 1);
    } else if (br < sr) {
      for (int r = sr - 1; r >= br; r--) out.add(r * s + s - 1);
    }
    return out;
  }
}
