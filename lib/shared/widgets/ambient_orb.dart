import 'package:flutter/material.dart';

class AmbientOrb extends StatefulWidget {
  final Color color;
  final double size;
  final Offset position;
  final Duration duration;

  const AmbientOrb({
    super.key,
    required this.color,
    this.size = 300,
    required this.position,
    this.duration = const Duration(seconds: 20),
  });

  @override
  State<AmbientOrb> createState() => _AmbientOrbState();
}

class _AmbientOrbState extends State<AmbientOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(30, -20)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(30, -20), end: const Offset(-20, 30)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-20, 30), end: const Offset(10, -10)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(10, -10), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx + _animation.value.dx,
          top: widget.position.dy + _animation.value.dy,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(0.3),
                  widget.color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
