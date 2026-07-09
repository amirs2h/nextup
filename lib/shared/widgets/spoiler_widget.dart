import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class SpoilerText extends StatefulWidget {
  final String text;
  final bool isSpoiler;

  const SpoilerText({
    super.key,
    required this.text,
    this.isSpoiler = false,
  });

  @override
  State<SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<SpoilerText> with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleReveal() {
    HapticFeedback.lightImpact();
    setState(() {
      _isRevealed = !_isRevealed;
      if (_isRevealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler) {
      return Text(
        widget.text,
        style: TextStyle(color: AppColors.text(context).withValues(alpha: 0.9), fontSize: 14, height: 1.5),
      );
    }

    return GestureDetector(
      onTap: _toggleReveal,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: _isRevealed
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cardBg(context),
                        AppColors.cardBgStrong(context),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRevealed
                    ? Colors.transparent
                    : const Color(0xFFFFD93D).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: _isRevealed
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFFFD93D).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: _isRevealed
                ? FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      widget.text,
                      style: TextStyle(color: AppColors.text(context).withValues(alpha: 0.9), fontSize: 14, height: 1.5),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.visibility_off_rounded, color: Color(0xFFFFD93D), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spoiler',
                              style: TextStyle(
                                color: const Color(0xFFFFD93D),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to reveal content',
                              style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.touch_app_rounded, color: AppColors.textMuted(context), size: 18),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class SpoilerToggle extends StatelessWidget {
  final bool isSpoiler;
  final ValueChanged<bool> onChanged;

  const SpoilerToggle({
    super.key,
    required this.isSpoiler,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isSpoiler);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSpoiler
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFD93D).withValues(alpha: 0.2),
                    const Color(0xFFFFD93D).withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSpoiler ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSpoiler ? const Color(0xFFFFD93D).withValues(alpha: 0.5) : AppColors.border(context),
          ),
          boxShadow: isSpoiler
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpoiler ? Icons.visibility_off_rounded : Icons.visibility_off_outlined,
              color: isSpoiler ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Spoiler',
              style: TextStyle(
                color: isSpoiler ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                fontSize: 12,
                fontWeight: isSpoiler ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
