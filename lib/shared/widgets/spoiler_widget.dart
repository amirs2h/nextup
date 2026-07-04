import 'package:flutter/material.dart';
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

class _SpoilerTextState extends State<SpoilerText> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler) {
      return Text(
        widget.text,
        style: TextStyle(color: AppColors.text(context).withOpacity(0.9), fontSize: 14, height: 1.5),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isRevealed = !_isRevealed),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isRevealed ? Colors.transparent : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(8),
          border: _isRevealed ? null : Border.all(color: AppColors.border(context)),
        ),
        child: _isRevealed
            ? Text(
                widget.text,
                style: TextStyle(color: AppColors.text(context).withOpacity(0.9), fontSize: 14, height: 1.5),
              )
            : Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: const Color(0xFFFFD93D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Spoiler - Tap to reveal',
                      style: TextStyle(color: AppColors.textMuted(context), fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
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
      onTap: () => onChanged(!isSpoiler),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSpoiler ? const Color(0xFFFFD93D).withOpacity(0.2) : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSpoiler ? const Color(0xFFFFD93D) : AppColors.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isSpoiler ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Spoiler',
              style: TextStyle(
                color: isSpoiler ? const Color(0xFFFFD93D) : AppColors.textMuted(context),
                fontSize: 12,
                fontWeight: isSpoiler ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
