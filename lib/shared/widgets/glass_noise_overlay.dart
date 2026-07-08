import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';

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
  static ui.Image? _cachedNoise;
  static const int _noiseSize = 128; // Small tile, tiled across widget

  _NoisePainter({required this.opacity});

  static Future<ui.Image> _generateNoiseImage() async {
    final random = Random(42);
    final pixels = Uint8List(_noiseSize * _noiseSize * 4);
    for (int i = 0; i < _noiseSize * _noiseSize; i++) {
      final value = random.nextDouble();
      final alpha = (value * 255).toInt();
      pixels[i * 4] = 255;     // R
      pixels[i * 4 + 1] = 255; // G
      pixels[i * 4 + 2] = 255; // B
      pixels[i * 4 + 3] = alpha; // A
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, _noiseSize, _noiseSize, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedNoise == null) {
      // First paint — generate noise synchronously using a simple approach
      _paintFallback(canvas, size);
      // Generate cached image for next paint
      _generateNoiseImage().then((img) => _cachedNoise = img);
      return;
    }

    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity)
      ..filterQuality = FilterQuality.none;

    // Tile the cached noise image across the widget
    final src = Rect.fromLTWH(0, 0, _noiseSize.toDouble(), _noiseSize.toDouble());
    for (double x = 0; x < size.width; x += _noiseSize) {
      for (double y = 0; y < size.height; y += _noiseSize) {
        final dst = Rect.fromLTWH(x, y, _noiseSize.toDouble(), _noiseSize.toDouble());
        canvas.drawImageRect(_cachedNoise!, src, dst, paint);
      }
    }
  }

  void _paintFallback(Canvas canvas, Size size) {
    // Use larger steps for fallback (4x4 pixels instead of 2x2)
    final random = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 4) {
      for (double y = 0; y < size.height; y += 4) {
        final value = random.nextDouble();
        paint.color = Color.fromRGBO(255, 255, 255, value * opacity);
        canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => oldDelegate.opacity != opacity;
}
