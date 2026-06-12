// lib/game/tile.dart

enum TileType { empty, wire, source, bulb }

/// A tile with a FIXED connection mask — tiles never rotate in SparkSwap,
/// they get swapped into the right position instead.
/// Bits: top=1, right=2, bottom=4, left=8
class Tile {
  final TileType type;
  final int mask;
  bool isPowered;

  Tile({required this.type, required this.mask, this.isPowered = false});

  bool get isLocked => type == TileType.source || type == TileType.bulb;
  bool get hasTop => mask & 1 != 0;
  bool get hasRight => mask & 2 != 0;
  bool get hasBottom => mask & 4 != 0;
  bool get hasLeft => mask & 8 != 0;

  Tile clone() => Tile(type: type, mask: mask, isPowered: isPowered);
}
