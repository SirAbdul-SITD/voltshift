// lib/game/tile_painter.dart
import 'package:flutter/material.dart';
import 'tile.dart';
import '../utils/constants.dart';

/// Terminal-phosphor styled conduit tile, painted from its mask.
class TilePainter extends CustomPainter {
  final Tile tile;
  const TilePainter({required this.tile});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final pad = w * 0.05;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, pad, w - pad * 2, h - pad * 2),
        const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = kSurface);
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = tile.isPowered ? kTraceOn.withOpacity(0.7) : kBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    if (tile.type == TileType.empty) {
      // faint scanline dot
      canvas.drawCircle(Offset(cx, cy), w * 0.03,
          Paint()..color = kBorder.withOpacity(0.6));
      return;
    }

    final color = tile.isPowered ? kTraceOn : kTraceOff;
    final tw = w * 0.16;

    if (tile.isPowered) {
      final gp = Paint()
        ..color = kTraceOn.withOpacity(0.45)
        ..strokeWidth = tw * 2.6
        ..strokeCap = StrokeCap.square
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      _strokes(canvas, size, cx, cy, gp);
    }

    final tp = Paint()
      ..color = color
      ..strokeWidth = tw
      ..strokeCap = StrokeCap.square;
    _strokes(canvas, size, cx, cy, tp);

    // Square junction block (terminal aesthetic = square, not round)
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(cx, cy), width: tw * 1.3, height: tw * 1.3),
        Paint()..color = color);
  }

  void _strokes(Canvas canvas, Size s, double cx, double cy, Paint p) {
    final w = s.width, h = s.height;
    final e = w * 0.03;
    if (tile.hasTop) canvas.drawLine(Offset(cx, e), Offset(cx, cy), p);
    if (tile.hasRight) canvas.drawLine(Offset(cx, cy), Offset(w - e, cy), p);
    if (tile.hasBottom) canvas.drawLine(Offset(cx, cy), Offset(cx, h - e), p);
    if (tile.hasLeft) canvas.drawLine(Offset(e, cy), Offset(cx, cy), p);
  }

  @override
  bool shouldRepaint(TilePainter old) =>
      old.tile != tile || old.tile.isPowered != tile.isPowered;
}
