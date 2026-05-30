import 'dart:math' as math;
import 'package:flutter/material.dart';

class AuthBackgroundPainter extends CustomPainter {
  final double progress;
  final ColorScheme cs;
  AuthBackgroundPainter(this.progress, this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final c1x = size.width * (0.2 + 0.15 * math.sin(progress * 2 * math.pi));
    final c1y = size.height * (0.15 + 0.1 * math.cos(progress * 2 * math.pi));
    paint.shader = RadialGradient(
      colors: [
        cs.primary.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c1x, c1y), radius: 300));
    canvas.drawCircle(Offset(c1x, c1y), 300, paint);

    final c2x = size.width * (0.8 + 0.1 * math.cos(progress * 2 * math.pi + 1));
    final c2y =
        size.height * (0.6 + 0.12 * math.sin(progress * 2 * math.pi + 1));
    paint.shader = RadialGradient(
      colors: [
        cs.secondary.withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c2x, c2y), radius: 250));
    canvas.drawCircle(Offset(c2x, c2y), 250, paint);

    final c3x = size.width * (0.5 + 0.2 * math.sin(progress * 2 * math.pi + 2));
    final c3y =
        size.height * (0.85 + 0.08 * math.cos(progress * 2 * math.pi + 2));
    paint.shader = RadialGradient(
      colors: [
        cs.tertiary.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(c3x, c3y), radius: 200));
    canvas.drawCircle(Offset(c3x, c3y), 200, paint);
  }

  @override
  bool shouldRepaint(covariant AuthBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.cs != cs;
}
