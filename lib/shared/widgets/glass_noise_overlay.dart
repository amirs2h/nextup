import 'package:flutter/material.dart';
import 'dart:math';

class GlassNoiseOverlay extends StatelessWidget {
  final BorderRadius? borderRadius;
  final double opacity;

  const GlassNoiseOverlay({
    super.key,
    this.borderRadius,
    this.opacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: CustomPaint(
        size: Size.infinite,
        painter: _NoisePainter(opacity: opacity),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;

  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 2) {
      for (double y = 0; y < size.height; y += 2) {
        final value = random.nextDouble();
        paint.color = Color.fromRGBO(
          255,
          255,
          255,
          value * opacity,
        );
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
