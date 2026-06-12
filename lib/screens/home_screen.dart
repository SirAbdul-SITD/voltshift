// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = Preferences.instance.getCompletedCount();
    final totalStars = Preferences.instance.getTotalStars();

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        // CRT scanlines
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScanlinePainter(_ctrl.value),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),
            // Shifting row icon
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = (_ctrl.value * 2) % 1.0;
                final slide = Curves.easeInOut
                    .transform((t * 1.4).clamp(0.0, 1.0));
                return SizedBox(
                  width: 200,
                  height: 48,
                  child: ClipRect(
                    child: Stack(children: [
                      for (int i = 0; i < 5; i++)
                        Positioned(
                          left: (i - 1 + slide) * 44,
                          top: 4,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: kSurface,
                              border: Border.all(
                                  color: i == 2 ? kAccent : kBorder,
                                  width: i == 2 ? 2 : 1),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: i == 2
                                  ? [
                                      BoxShadow(
                                          color: kAccent.withOpacity(0.4),
                                          blurRadius: 12)
                                    ]
                                  : null,
                            ),
                            child: Icon(Icons.power_input,
                                color: i == 2 ? kAccent : kTraceOff, size: 18),
                          ),
                        ),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('VOLTSHIFT',
                style: techno(40,
                    color: kAccent, weight: FontWeight.w900, letterSpacing: 8)),
            const SizedBox(height: 8),
            Text('SHIFT  ·  ALIGN  ·  POWER UP',
                style: techno(12, color: kTextDim, letterSpacing: 4)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _chip(Icons.check_circle_outline, '$completed / $kTotalLevels',
                  kEasyColor),
              const SizedBox(width: 14),
              _chip(Icons.star, '$totalStars', kStarOn),
            ]),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(children: [
                _btn('PLAY', Icons.play_arrow_rounded, true, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen()));
                }),
                const SizedBox(height: 14),
                _btn('SETTINGS', Icons.tune_rounded, false, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                }),
              ]),
            ),
            const SizedBox(height: 56),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: techno(13)),
        ]),
      );

  Widget _btn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF128A37), Color(0xFF1FB94C)])
                : null,
            color: primary ? null : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.7) : kBorder,
                width: primary ? 1.5 : 1),
            boxShadow: primary
                ? [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 22)]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? Colors.white : kTextDim, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: techno(15,
                    color: primary ? Colors.white : kTextDim,
                    letterSpacing: 3)),
          ]),
        ),
      );
}

class _ScanlinePainter extends CustomPainter {
  final double t;
  _ScanlinePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final lp = Paint()..color = kAccent.withOpacity(0.025);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.4), lp);
    }
    // Slow travelling bright scanline
    final y = size.height * t;
    canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 60),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kAccent.withOpacity(0),
              kAccent.withOpacity(0.05),
              kAccent.withOpacity(0)
            ],
          ).createShader(Rect.fromLTWH(0, y, size.width, 60)));
  }

  @override
  bool shouldRepaint(_ScanlinePainter o) => o.t != t;
}
