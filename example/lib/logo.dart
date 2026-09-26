import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A made-up logo for the example: a rounded tile with a bold "Y".
///
/// Drawn in code, so it stays sharp at every size the brand pop uses.
class YakoLogo extends StatelessWidget {
  /// Creates the logo.
  const YakoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(s * 0.06, s * 0.06, s * 0.88, s * 0.88);
    final tile = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF8E6CFF),
            Color(0xFFFF4FA3),
            Color(0xFFFFB347)
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      tile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // The "Y": two arms meeting in the middle, then a stem.
    final y = Path()
      ..moveTo(s * 0.3, s * 0.26)
      ..lineTo(s * 0.5, s * 0.5)
      ..lineTo(s * 0.7, s * 0.26)
      ..moveTo(s * 0.5, s * 0.5)
      ..lineTo(s * 0.5, s * 0.76);
    canvas.drawPath(
      y,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    // A little shine in the corner.
    canvas.drawCircle(
      Offset(s * 0.24, s * 0.22),
      s * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.5), radius: s * 0.36),
      math.pi * 1.1,
      math.pi * 0.25,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
