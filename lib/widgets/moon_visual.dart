import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Рисует настоящий вид Луны: терминатор, кратеры, свечение.
class MoonVisual extends StatelessWidget {
  final double ageDays;
  final double size;
  final bool glow;

  const MoonVisual({
    super.key,
    required this.ageDays,
    this.size = 120,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonPainter(ageDays: ageDays, glow: glow),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double ageDays;
  final double glow;
  static const double _synodic = 29.530588853;

  _MoonPainter({required this.ageDays, required bool glow})
      : glow = glow ? 1.0 : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;
    final phase = (ageDays / _synodic) % 1.0;
    final waxing = phase < 0.5;
    final t = math.cos(2 * math.pi * phase);
    final illum = (1 - math.cos(2 * math.pi * phase)) / 2;

    if (glow > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF3C4).withValues(alpha: 0.06 + 0.34 * illum),
            const Color(0xFFFFF3C4).withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r * 2.2));
      canvas.drawCircle(Offset(cx, cy), r * 2.2, glowPaint);
    }

    canvas.save();
    if (!waxing) {
      canvas.translate(cx * 2, 0);
      canvas.scale(-1.0, 1.0);
    }

    final discRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3A58), Color(0xFF161E33)],
        ).createShader(discRect),
    );

    final lit = Path()
      ..moveTo(cx, cy - r)
      ..arcToPoint(Offset(cx, cy + r),
          radius: Radius.circular(r), clockwise: true)
      ..arcToPoint(Offset(cx, cy - r),
          radius: Radius.elliptical((r * t).abs(), r), clockwise: t < 0)
      ..close();

    canvas.save();
    canvas.clipPath(lit);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF0), Color(0xFFFFDF9E)],
        ).createShader(discRect),
    );

    final crater = Paint()
      ..color = const Color(0xFFD8BE86).withValues(alpha: 0.5);
    final craterSoft = Paint()
      ..color = const Color(0xFFE8D3A0).withValues(alpha: 0.45);
    canvas.drawCircle(Offset(cx + r * 0.26, cy - r * 0.32), r * 0.17, crater);
    canvas.drawCircle(Offset(cx - r * 0.22, cy + r * 0.18), r * 0.22, crater);
    canvas.drawCircle(
        Offset(cx + r * 0.42, cy + r * 0.36), r * 0.12, craterSoft);
    canvas.drawCircle(
        Offset(cx - r * 0.44, cy - r * 0.42), r * 0.10, craterSoft);
    canvas.drawCircle(Offset(cx + r * 0.02, cy + r * 0.58), r * 0.09, crater);
    canvas.restore();

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.28),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.ageDays != ageDays || old.glow != glow;
}

/// Звёздное небо для шапки. Звёзды детерминированные — не «мерцают» при перерисовке.
class StarField extends StatelessWidget {
  final int count;
  const StarField({super.key, this.count = 46});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter(count), size: Size.infinite);
  }
}

class _StarPainter extends CustomPainter {
  final int count;
  _StarPainter(this.count);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(20261111);
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final rad = 0.5 + rnd.nextDouble() * 1.3;
      final a = 0.18 + rnd.nextDouble() * 0.55;
      canvas.drawCircle(
        Offset(x, y),
        rad,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.72),
      1.8,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.22),
      1.5,
      Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.count != count;
}
