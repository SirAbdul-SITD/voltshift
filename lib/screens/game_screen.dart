// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../game/tile_painter.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _victoryCtrl;
  late final Animation<double> _victoryAnim;

  Offset? _panStart;
  int? _panCellRow;
  int? _panCellCol;

  @override
  void initState() {
    super.initState();
    _victoryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _victoryAnim =
        CurvedAnimation(parent: _victoryCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().loadLevel(widget.levelIndex);
    });
  }

  @override
  void dispose() {
    _victoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Consumer<GameState>(builder: (ctx, st, _) {
        if (!st.initialized) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        if (st.isComplete && !_victoryCtrl.isCompleted) {
          _victoryCtrl.forward();
          if (Preferences.instance.isVibrationEnabled()) {
            HapticFeedback.heavyImpact();
          }
        }
        return Stack(children: [
          SafeArea(
            child: Column(children: [
              _hud(st),
              const SizedBox(height: 6),
              Text('SWIPE A ROW OR COLUMN TO SHIFT IT',
                  style: techno(10, color: kTextDim, letterSpacing: 2)),
              Expanded(child: Center(child: _board(st))),
              _bottomBar(st),
              const SizedBox(height: 12),
            ]),
          ),
          if (st.isComplete) _victory(st),
        ]);
      }),
    );
  }

  Widget _hud(GameState st) {
    final diffColor = st.level.difficulty == 'Easy'
        ? kEasyColor
        : st.level.difficulty == 'Medium'
            ? kMediumColor
            : kHardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kTextDim, size: 16),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text('LEVEL ${st.level.index + 1}',
              style: techno(14, letterSpacing: 3)),
          Text(st.level.difficulty.toUpperCase(),
              style: techno(10, color: diffColor, letterSpacing: 2)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${st.moves}',
              style: techno(18, color: kAccent, weight: FontWeight.w900)),
          Text('SHIFTS', style: techno(9, color: kTextDim, letterSpacing: 2)),
        ]),
      ]),
    );
  }

  // ── Board with socket / lamp side connectors ───────────
  Widget _board(GameState st) {
    final size = MediaQuery.of(context).size;
    const margin = 34.0; // side connector width
    final gridSize =
        (size.width - 24 - margin * 2).clamp(0.0, size.height * 0.60);
    final grid = st.level.gridSize;
    final cell = gridSize / grid;
    final s = st.level.gridSize;
    final endIdx = st.level.bulbRow * s + s - 1;
    final lampLit =
        st.poweredSet.contains(endIdx) && st.level.tiles[endIdx].hasRight;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Left socket column
      SizedBox(
        width: margin,
        height: gridSize,
        child: Stack(children: [
          Positioned(
            top: st.level.sourceRow * cell,
            left: 0,
            width: margin,
            height: cell,
            child: _SocketConnector(),
          ),
        ]),
      ),
      // The shifting grid
      Container(
        width: gridSize + 8,
        height: gridSize + 8,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder, width: 1.5),
        ),
        child: GestureDetector(
          onPanStart: (d) {
            _panStart = d.localPosition;
            final c = (d.localPosition.dx / cell).floor().clamp(0, grid - 1);
            final r = (d.localPosition.dy / cell).floor().clamp(0, grid - 1);
            _panCellRow = r;
            _panCellCol = c;
          },
          onPanEnd: (d) {
            final start = _panStart;
            if (start == null) return;
            final v = d.velocity.pixelsPerSecond;
            // dominant direction comes from total velocity at release;
            // fall back handled in onPanUpdate-free design via velocity
            const minV = 90.0;
            if (v.distance < minV) {
              _panStart = null;
              return;
            }
            final isRow = v.dx.abs() >= v.dy.abs();
            final dir = isRow ? (v.dx > 0 ? 1 : -1) : (v.dy > 0 ? 1 : -1);
            final index = isRow ? _panCellRow : _panCellCol;
            if (index != null) {
              if (Preferences.instance.isVibrationEnabled()) {
                HapticFeedback.selectionClick();
              }
              st.shift(isRow: isRow, index: index, dir: dir);
            }
            _panStart = null;
          },
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: grid),
            itemCount: grid * grid,
            itemBuilder: (_, i) =>
                CustomPaint(painter: TilePainter(tile: st.level.tiles[i])),
          ),
        ),
      ),
      // Right lamp column
      SizedBox(
        width: margin,
        height: gridSize,
        child: Stack(children: [
          Positioned(
            top: st.level.bulbRow * cell,
            right: 0,
            width: margin,
            height: cell,
            child: _LampConnector(lit: lampLit),
          ),
        ]),
      ),
    ]);
  }

  Widget _bottomBar(GameState st) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionBtn(Icons.refresh_rounded, 'RESTART', () {
            _victoryCtrl.reset();
            st.restartLevel();
          }),
          const SizedBox(width: 24),
          _actionBtn(Icons.grid_view_rounded, 'LEVELS', () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const LevelSelectScreen()));
          }),
        ],
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: kTextDim, size: 16),
            const SizedBox(width: 6),
            Text(label, style: techno(10, color: kTextDim, letterSpacing: 2)),
          ]),
        ),
      );

  Widget _victory(GameState st) => Container(
        color: Colors.black.withOpacity(0.80),
        child: Center(
          child: ScaleTransition(
            scale: _victoryAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: kAccent.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 4)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBulbOn.withOpacity(0.12),
                    border: Border.all(color: kBulbOn, width: 2),
                  ),
                  child:
                      const Icon(Icons.bolt_rounded, color: kBulbOn, size: 32),
                ),
                const SizedBox(height: 16),
                Text('CIRCUIT ONLINE',
                    style: techno(17,
                        color: kAccent,
                        weight: FontWeight.w900,
                        letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('${st.moves} SHIFTS  ·  PAR ${st.level.parMoves}',
                    style: techno(11, color: kTextDim, letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < st.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < st.stars ? kStarOn : kStarOff,
                              size: 36,
                            ),
                          )),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: _vBtn('REPLAY', Icons.refresh_rounded, false, () {
                    _victoryCtrl.reset();
                    st.restartLevel();
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _vBtn('NEXT', Icons.arrow_forward_rounded, true,
                          () {
                    _victoryCtrl.reset();
                    if (st.currentLevelIndex < 149) {
                      st.nextLevel();
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen()));
                    }
                  })),
                ]),
              ]),
            ),
          ),
        ),
      );

  Widget _vBtn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF128A37), Color(0xFF1FB94C)])
                : null,
            color: primary ? null : kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.5) : kBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: techno(12, letterSpacing: 2)),
          ]),
        ),
      );
}

// ── Side connectors ──────────────────────────────────────
class _SocketConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SocketPainter());
  }
}

class _SocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    // power stub line into the grid
    final lp = Paint()
      ..color = kSourceColor
      ..strokeWidth = size.height * 0.16
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
        Offset(size.width * 0.35, cy), Offset(size.width, cy), lp);
    // socket block
    final rect = Rect.fromCenter(
        center: Offset(size.width * 0.30, cy),
        width: size.width * 0.5,
        height: size.height * 0.55);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = kSourceColor.withOpacity(0.18));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = kSourceColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    // bolt glyph
    final tp = Paint()
      ..color = kSourceColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.30;
    canvas.drawLine(Offset(cx + 3, cy - rect.height * 0.26),
        Offset(cx - 2, cy + 1), tp);
    canvas.drawLine(
        Offset(cx - 2, cy + 1), Offset(cx + 2, cy - 1), tp);
    canvas.drawLine(Offset(cx + 2, cy - 1),
        Offset(cx - 3, cy + rect.height * 0.26), tp);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LampConnector extends StatelessWidget {
  final bool lit;
  const _LampConnector({required this.lit});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LampPainter(lit: lit));
  }
}

class _LampPainter extends CustomPainter {
  final bool lit;
  _LampPainter({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final color = lit ? kBulbOn : kBulbOff;
    // stub line from grid
    final lp = Paint()
      ..color = color
      ..strokeWidth = size.height * 0.16
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(0, cy), Offset(size.width * 0.62, cy), lp);
    // lamp circle
    final r = size.height * 0.30;
    final cx = size.width * 0.66;
    if (lit) {
      canvas.drawCircle(
          Offset(cx, cy),
          r * 2.0,
          Paint()
            ..color = kBulbOn.withOpacity(0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
    }
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = (lit ? Colors.white : kBorder).withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_LampPainter o) => o.lit != lit;
}
